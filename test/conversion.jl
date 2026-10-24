module ConversionTests
using Cropbox, Poplar, Test, Dates, TimeZones
using Poplar.DataFrames: DataFrame

function make_model(; initial_age=0u"yr", cutting_eff=.6, coppice_eff=.75,
                    shoot_rate=0)
    start = ZonedDateTime(2014, 4, 5, 12, tz"UTC-8")
    weather = DataFrame(index=[start + Hour(i) for i in 0:3],
        SolRad=fill(1.,4), Tair=fill(25.,4), RH=fill(40.,4),
        Wind=fill(2.,4), Rain=zeros(4))
    instance(Poplar.Model; config=@config(
        :Calendar => (init=start,), :Atmosphere => (data=weather,),
        :Age => (iAge=initial_age,),
        :Stem => (root_conversion_efficiency_cutting=cutting_eff,
                  root_conversion_efficiency_coppice=coppice_eff),
        :Model => (iWF=1000, iWS=5000, iWR=2000, iSW=1004, DRp=0,
            irrigation_rate=0, irrigation_start_level=0, irrigation_end_level=0,
            bud_rate=0, shoot_rate=shoot_rate, gammaR=0, NPP_type=2)))
end

@testset "root-to-shoot conversion" begin
    @testset "initialization and first-year transition" begin
        young = make_model()
        @test young.cutting'
        @test young.root_conversion_efficiency' == .6

        older = make_model(initial_age=1u"yr")
        @test !older.cutting'
        @test older.root_conversion_efficiency' == .75

        transition = make_model(initial_age=1u"yr"-1u"hr")
        @test transition.cutting'
        @test transition.root_conversion_efficiency' == .6
        update!(transition)
        @test transition.standAgeYear' ≈ 1u"yr"
        @test !transition.cutting'
        @test transition.root_conversion_efficiency' == .75
    end

    @testset "phase parameters and constant-efficiency runs" begin
        custom = make_model(initial_age=1u"yr"-1u"hr", cutting_eff=.55, coppice_eff=.8)
        @test custom.root_conversion_efficiency' == .55
        update!(custom)
        @test custom.root_conversion_efficiency' == .8

        fixed = make_model(initial_age=1u"yr"-1u"hr", cutting_eff=.65, coppice_eff=.65)
        @test fixed.root_conversion_efficiency' == .65
        update!(fixed)
        @test !fixed.cutting'
        @test fixed.root_conversion_efficiency' == .65
    end

    @testset "selected efficiency reaches the stem update" begin
        # Compare otherwise identical full-model updates, with and without
        # root-to-shoot transfer. This checks the recipient and donor stocks.
        disabled = make_model(shoot_rate=0)
        enabled = make_model(shoot_rate=.5)
        transferred = enabled.dShoot' * enabled.step'
        @test transferred > 0u"kg/ha"
        update!(disabled)
        update!(enabled)
        @test enabled.WS' - disabled.WS' ≈ .6 * transferred
        @test disabled.WR' - enabled.WR' ≈ transferred
        @test enabled.WF' ≈ disabled.WF'
    end
end
end
