module IrrigationIntegrationTests
using Cropbox, Poplar, Test, Dates, TimeZones
using Poplar.DataFrames: DataFrame

@testset "absent irrigation schedules retain automatic irrigation" begin
    for schedule_config in ((;), (irrigation_data=nothing,),
                            (irrigation_dates=nothing,), (irrigation_dates=ZonedDateTime[],))
        for rate in (0.0, 2.0)
            @testset "schedule=$schedule_config rate=$rate" begin
                s = instance(Poplar.Model; config=@config(Poplar.config_Model,
                    :Model => (iWF=1000, iWS=5000, iWR=2000, iAge=2, iSW=368,
                               bud_rate=0, shoot_rate=0, NPP_type=2, irrigation_rate=rate),
                    :Model => schedule_config))
                if haskey(schedule_config, :irrigation_dates) && isnothing(schedule_config.irrigation_dates)
                    @test isnothing(s.irrigation_dates')
                else
                    @test isempty(s.irrigation_dates')
                end
                @test !s.dormant'
                @test s.flag_irrigation'
                @test s.irrigation' == rate*u"mm/hr"
                before = s.IR_ac'
                step = s.step'
                update!(s)
                @test s.IR_ac' - before ≈ rate*u"mm/hr" * step
                @test s.irrigation' == rate*u"mm/hr"
            end
        end
    end
end

@testset "scheduled amounts take precedence over automatic irrigation" begin
    schedule = DataFrame(year=fill(2014, 2), jday=fill(95, 2),
                         time=[Time(0), Time(1)], irrigation=[0.0, 5.0])
    s = instance(Poplar.Model; config=@config(Poplar.config_Model,
        :Model => (irrigation_data=schedule, timezone=tz"America/Los_Angeles",
                   iWF=1000, iWS=5000, iWR=2000, iAge=2, iSW=368,
                   bud_rate=0, shoot_rate=0, NPP_type=2, irrigation_rate=2)))
    for amount in (0.0, 5.0, 2.0)
        @test s.flag_irrigation' && !s.dormant'
        @test s.irrigation' == amount*u"mm/hr"
        update!(s)
    end
    @test s.IR_ac' ≈ 7u"mm"
end

@testset "initial biomass from planting material" begin
    s = instance(Poplar.Model; config=@config(Poplar.config_Model,
        :Model => (init_weight=16.54, iStemNo=3586,
                   init_pf=0.1, init_ps=0.2, init_pr=0.7)))
    total = 16.54u"g" * 3586u"ha^-1"
    @test s.iWF' ≈ 0.1total
    @test s.iWS' ≈ 0.2total
    @test s.iWR' ≈ 0.7total
    @test s.iW' ≈ total
    @test s.WF' ≈ s.iWF'
    @test s.WS' ≈ s.iWS'
    @test s.WR' ≈ s.iWR'
end

@testset "scheduled irrigation enters the corrected water budget" begin
    # CUH example begins at midnight on 5 April 2014. An absent hour supplies zero.
    schedule = DataFrame(year=fill(2014, 3), jday=fill(95, 3),
                         time=[Time(0), Time(2), Time(4)], irrigation=[2.0, 5.0, 0.0])
    for fraction in (0.0, 0.5, 1.0)
        s = instance(Poplar.Model; config=@config(Poplar.config_Model,
            :Model => (irrigation_data=schedule, timezone=tz"America/Los_Angeles",
                       irrigation_rate=0, pool_fraction=fraction, iSW=1004)))
        initial_irrigation = s.IR_ac'
        total_runoff = 0.0u"mm"
        for expected_irrigation in (2.0, 0.0, 5.0, 0.0, 0.0)
            @test s.irrigation' ≈ expected_irrigation*u"mm/hr"
            old_soil, old_pool = s.SW', s.pool'
            expected_soil_change = s.dSW' * s.step'
            expected_pool_change = s.dPool' * s.step'
            net_change = (s.rain' + s.irrigation' - s.evapotranspiration' -
                          s.drainage' - s.dRunoff') * s.step'
            total_runoff += s.dRunoff' * s.step'
            update!(s)
            @test isapprox(s.SW' + s.pool' - old_soil - old_pool, net_change; atol=1e-8u"mm")
            @test isapprox(s.SW' - old_soil, expected_soil_change; atol=1e-8u"mm")
            @test isapprox(s.pool' - old_pool, expected_pool_change; atol=1e-8u"mm")
            @test s.minSW' <= s.SW' <= s.maxSW'
            @test s.pool' >= 0u"mm"
        end
        @test s.IR_ac' - initial_irrigation ≈ 7u"mm"
        if fraction == 1
            @test total_runoff == 0u"mm"
            @test s.pool' > 0u"mm"
        else
            @test total_runoff > 0u"mm"
        end
    end
end
end
