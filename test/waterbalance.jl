module WaterBalanceTests
using Cropbox, Poplar, Test, TimeZones
using Poplar: CL

# Use the production component with controlled weather and ET demand.
@system WaterHarness(Poplar.Soil, Poplar.WaterBalance, Controller) begin
    step(context.clock.step) ~ preserve(u"hr")
    LAI => 0 ~ preserve(parameter)
    rain => 0 ~ preserve(parameter, u"mm/hr")
    transpiration => 0 ~ preserve(parameter, u"mm/hr")
    potential_surface_evaporation => 0 ~ preserve(parameter, u"mm/hr")
    time => ZonedDateTime(2020, 1, 1, tz"UTC") ~ preserve::ZonedDateTime
    dormant => true ~ flag
    initial_pool => 0 ~ preserve(parameter, u"mm")
    pool(dPool) ~ accumulate(init=initial_pool, min=0, u"mm")
end

amount(s, name, unit=u"mm") = Cropbox.Unitful.ustrip(unit, getproperty(s, name)')
function fixture(; sw=80., maximum=100., minimum=20., fc=80., pool=0.,
                 fraction=0., rain=0., et=0., drainage=0., dt=1.)
    instance(WaterHarness; config=@config(
        :Clock => (step=dt*u"hr",),
        :WaterHarness => (
            soil_depth=1, reference_depth=1, soil_saturation=maximum,
            field_capacity=fc, wilting_point=minimum, minimum_soil_water=minimum,
            iSW=sw, initial_pool=pool, pool_fraction=fraction,
            rain=rain, transpiration=et, DRp=drainage, maxInterception=0,
        ),
    ))
end

function advance_and_check!(s)
    sw, pool = amount(s,:SW), amount(s,:pool)
    dt = amount(s,:step,u"hr")
    rate(n) = amount(s,n,u"mm/hr")
    net = rate(:rain)+rate(:irrigation)-rate(:evapotranspiration)-rate(:drainage)-rate(:dRunoff)
    ds, dp = rate(:dSW), rate(:dPool)
    et, runoff = rate(:evapotranspiration), rate(:dRunoff)
    update!(s)
    sw1, pool1 = amount(s,:SW), amount(s,:pool)
    @test abs(sw1-sw+pool1-pool-net*dt) < 1e-8
    # Bounds must not silently remove or create water.
    @test abs(sw1-sw-ds*dt) < 1e-8
    @test abs(pool1-pool-dp*dt) < 1e-8
    @test amount(s,:minSW)-1e-8 <= sw1 <= amount(s,:maxSW)+1e-8
    @test pool1 >= -1e-8
    (; sw=sw1, pool=pool1, et, runoff)
end

@testset "water accounting regressions" begin
    a=advance_and_check!(fixture(sw=100.,maximum=124.,fc=100.,rain=2.))
    @test a.sw ≈ 102.
    @test a.runoff ≈ 0.
    a=advance_and_check!(fixture(sw=100.,fc=80.,rain=2.))
    @test a.sw ≈ 100.
    @test a.runoff ≈ 2.
    a=advance_and_check!(fixture(sw=100.,pool=24.,fraction=1.))
    @test a.sw ≈ 100.
    @test a.pool ≈ 24.
    a=advance_and_check!(fixture(sw=76.,pool=24.,fraction=1.))
    @test a.sw ≈ 77.
    @test a.pool ≈ 23.
    a=advance_and_check!(fixture(sw=20.,et=.5))
    @test a.et ≈ 0.
    a=advance_and_check!(fixture(sw=20.,pool=24.,et=2.))
    @test a.et ≈ 1.
    a=advance_and_check!(fixture(sw=100.,rain=2.,fraction=.5))
    @test a.runoff ≈ 1.
    @test a.pool ≈ 1.
    a=advance_and_check!(fixture(sw=20.,pool=24.,et=2.,dt=48.))
    @test a.pool ≈ 0. atol=1e-8
    @test a.et ≈ .5
end

@testset "storage limits across timesteps" begin
    for fraction in (0.,.5,1.), dt in (.25,1.,6.,24.,48.),
        sw in (20.,80.,100.), rain in (0.,2.,30.), et in (0.,.5,20.), drainage in (0.,1.)
        advance_and_check!(fixture(; fraction,dt,sw,rain,et,drainage,pool=24.))
    end
end

@testset "ten days of successive updates" begin
    for fraction in (0.,.5,1.), rain in (0.,2.), dt in (.25,1.,6.)
        s=fixture(;fraction,rain,dt,pool=24.,et=.5,drainage=.1)
        for _ in 1:round(Int,240/dt)
            advance_and_check!(s)
        end
    end
end
end
