module SenescenceTests
using Cropbox, Poplar, Test
using Poplar: Senescence

# Prescribe accumulated temperature to exercise the production factor and
# leaf-drop equation at both boundaries and in the unchanged interior.
@system SenescenceBoundaryHarness(Senescence, Controller) begin
    step(context.clock.step) ~ preserve(u"hr")
    day_length => 12 ~ preserve(u"hr")
    d => 250 ~ preserve(u"d")
    WF => 10 ~ preserve(u"kg/ha")
    Tk_air => 278.15 ~ preserve(u"K")
    budburst => false ~ flag
    SDD => 0 ~ preserve(parameter, u"K*d")
end

# Keep the real accumulator to check that output bounds do not erase the
# negative temperature history or change warm-to-cold accumulation.
@system SenescenceWeatherHarness(Senescence, Controller) begin
    step(context.clock.step) ~ preserve(u"hr")
    day_length => 12 ~ preserve(u"hr")
    d => 250 ~ preserve(u"d")
    WF => 10 ~ preserve(u"kg/ha")
    Tk_air(t=context.clock.time) => begin
        t < 2u"hr" ? 303.15 : 278.15
    end ~ track(u"K")
    budburst => false ~ flag
end

# Instantiate production stomata so Track's minimum is applied. The debugging
# form Cropbox.value(System, :m; ...) evaluates only the body, without bounds.
@system SenescenceMultiplierHarness(Poplar.Stomata, Controller) begin
    water_stress => .4 ~ preserve(parameter)
    s => 0 ~ preserve(parameter)
    A_net => 10 ~ preserve(u"μmol/m^2/s", parameter)
    gb => .5 ~ preserve(u"mol/m^2/s/bar", parameter)
    RH => .5 ~ preserve(parameter)
    CO2 => 400 ~ preserve(u"μmol/mol", parameter)
    P_air => 100 ~ preserve(u"kPa", parameter)
end
multiplier(s) = instance(SenescenceMultiplierHarness;
    config=:SenescenceMultiplierHarness=>(s=s.s',)).m'

@testset "bounded senescence and stomatal multiplier floor" begin
    @testset "physiology and leaf drop at boundaries" begin
        for (raw, expected_s, expected_m, leaf_drop) in (
            (-8., 0., .4, 0.),
            (0., 0., .4, 0.),
            (20., .2, .32, 0.),
            (75., .75, .1, 2.5/24),
            (99.99995, .9999995, 1e-5, (.9999995-.5)*10/24),
            (100., 1., 1e-5, 10.),
            (120., 1., 1e-5, 10.))
            s = instance(SenescenceBoundaryHarness; config=@config(
                :SenescenceBoundaryHarness => (SDD=raw,)))
            @test s.s' ≈ expected_s
            @test 0 <= s.s' <= 1
            @test s.senescence_progress' ≈ clamp(raw/100,0,1)
            @test multiplier(s) ≈ expected_m
            @test 1e-5 <= multiplier(s) <= .4
            @test s.dSen' ≈ leaf_drop * u"kg/ha/hr"
        end
    end

    @testset "raw warm-weather history remains available" begin
        s = instance(SenescenceWeatherHarness)
        @test s.SD' < 0u"K"
        @test s.SDD' == 0u"K*d"
        update!(s)
        @test s.SDD' < 0u"K*d"
        @test s.s' == 0
        update!(s)
        @test s.SD' > 0u"K"
        @test s.SDD' < 0u"K*d"
        for _ in 1:3
            update!(s)
        end
        @test s.SDD' > 0u"K*d"
        @test 0 < s.s' < 1
    end
end
end
