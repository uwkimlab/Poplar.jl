module StomataTests
using Cropbox, Poplar, Test, Dates, TimeZones
using Cropbox.Unitful: ustrip
using Poplar.DataFrames: DataFrame

@system StomatalBoundaryHarness(Poplar.Stomata, Controller) begin
    water_stress => 1 ~ preserve(parameter)
    s => 0 ~ preserve(parameter)
    A_net => 10 ~ preserve(u"μmol/m^2/s", parameter)
    gb => 0.5 ~ preserve(u"mol/m^2/s/bar", parameter)
    RH => 0.5 ~ preserve(parameter)
    CO2 => 400 ~ preserve(u"μmol/mol", parameter)
    P_air => 100 ~ preserve(u"kPa", parameter)
end

# An independent high-precision root of the original humidity/conductance
# balance, without normalizing or using the production quadratic expression.
function reference_humidity(s)
    g0=BigFloat(ustrip(u"mol/m^2/s/bar",s.g0'))
    gb=BigFloat(ustrip(u"mol/m^2/s/bar",s.gb'))
    A=BigFloat(ustrip(u"mol/m^2/s",s.A_net'))
    Cs=BigFloat(ustrip(u"bar",s.Cs'))
    g1=BigFloat(s.g1'); m=BigFloat(s.m'); rh=BigFloat(s.RH')
    balance(h)=(h-rh)*gb-(1-h)*(g0+g1*m*A*h/Cs)
    lo=big"0"; hi=big"1"
    for _ in 1:200
        mid=(lo+hi)/2
        if balance(mid)>0
            hi=mid
        else
            lo=mid
        end
    end
    Float64((lo+hi)/2)
end

# Define the inherited fixture in Poplar's scope so its enum/function references
# retain the same bindings as the production Model. This only affects this test process.
@eval Poplar @system SenescenceGasExchangeModel(Model) begin
    SDD => 100 ~ preserve(parameter, u"K*d")
end

@testset "original stomata with the senescence margin" begin
    @testset "ordinary conditions and the production senescence cap" begin
        for cfg in (
            (s=0.,), (s=.5,), (s=.99,), (s=1-1e-6,),
            (s=1-1e-6,A_net=-2.), (s=0.,A_net=-2.),
            (s=0.,RH=0.), (s=0.,RH=1.))
            s=instance(StomatalBoundaryHarness;config=:StomatalBoundaryHarness=>cfg)
            expected=reference_humidity(s)
            @test isfinite(s.hs')
            # The original quadratic formula loses precision near zero slope.
            @test s.hs' ≈ expected atol=1e-8 rtol=1e-8
            @test 0 <= s.hs' <= 1
            @test isfinite(s.gs')
            @test s.gs' >= s.g0'
        end
    end

    @testset "known original-solver limitations (not fixed by this workaround)" begin
        for cfg in ((s=1.,), (s=1-1e-6,A_net=0.),
                    (s=1-1e-6,water_stress=0.), (s=1-1e-6,g1=0.))
            s=instance(StomatalBoundaryHarness;config=:StomatalBoundaryHarness=>cfg)
            @test_broken isfinite(s.hs')
        end
    end

    @testset "full senescence with production margin, day/night and leaves/no leaves" begin
        for radiation in (0.,800.), foliage in (0.,1000.)
            start=ZonedDateTime(2014,4,5,12,tz"UTC-8")
            weather=DataFrame(index=[start+Hour(i) for i in 0:2],
                SolRad=fill(radiation,3),Tair=fill(25.,3),RH=fill(40.,3),
                Wind=fill(2.,3),Rain=zeros(3))
            s=instance(Poplar.SenescenceGasExchangeModel;config=@config(
                :Calendar=>(init=start,),:Atmosphere=>(data=weather,),
                :SenescenceGasExchangeModel=>(SDD=100,),
                :Model=>(iWF=foliage,iWS=5000,iWR=2000,iSW=1004,DRp=0,
                    irrigation_rate=0,irrigation_start_level=0,irrigation_end_level=0,
                    bud_rate=0,shoot_rate=0,NPP_type=2)))
            for step in 0:1
                @test s.s' == 1-1e-6
                @test s.senescence_progress' == 1
                @test s.dSen' == s.WF'/s.step'
                for leaf in (s.sunlit_gasexchange,s.shaded_gasexchange)
                    @test leaf.s' == 1-1e-6
                    @test leaf.m' > 0
                    @test isfinite(leaf.hs')
                    @test leaf.gs' >= leaf.g0'
                    @test isfinite(leaf.A_net')
                    @test isfinite(leaf.E')
                end
                @test isfinite(s.GPP')
                @test isfinite(s.transpiration')
                @test isfinite(s.WS')
                step==0 && update!(s)
            end
        end
    end
end
end
