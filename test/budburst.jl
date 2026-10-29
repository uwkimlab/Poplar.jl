module BudburstTests
using Cropbox, Poplar, Test
using Poplar: Budburst

# Exercise production bud equations with controlled allometric targets and
# paired recipient/donor stocks. Other plant growth and losses are excluded.
@system BudTransferHarness(Budburst, Controller) begin
    step(context.clock.step) ~ preserve(u"hr")
    F => 100 ~ preserve
    Rf => 0 ~ preserve
    T_air => 10 ~ preserve(u"°C")
    senescent => false ~ flag
    partition_type => 3 ~ preserve(parameter)
    stemNo => 1000 ~ preserve(u"ha^-1")
    pFSmax => 2 ~ preserve
    avTargetWF_dbh => 100 ~ preserve(u"g")
    avTargetWF_vi(t=context.clock.time) => begin
        2u"hr" <= t < 4u"hr" ? 10 : 100
    end ~ track(u"g")
    WF(dBud) => dBud ~ accumulate(init=0, u"kg/ha")
    WS(dBud) => -dBud ~ accumulate(init=1000, u"kg/ha")
end

@testset "falling bud target stops transfer without reversing it" begin
    s = instance(BudTransferHarness; config=@config(
        :BudTransferHarness => (bud_allocation_type=3,)))
    initial_total = s.WF' + s.WS'
    @test s.bud_target' ≈ 30u"kg/ha"
    @test s.dBud' ≈ 5u"kg/ha/hr"
    update!(s)
    update!(s)
    # Ten kg/ha was transferred before the target falls to three. Stop;
    # do not take seven back from the leaves, even with budburst inactive.
    @test s.bud_target' ≈ 3u"kg/ha"
    @test s.bud' ≈ 10u"kg/ha"
    @test !s.budburst'
    @test s.dBud' == 0u"kg/ha/hr"
    update!(s)
    @test s.WF' ≈ 10u"kg/ha"
    @test s.WS' ≈ 990u"kg/ha"
    @test s.bud' ≈ 10u"kg/ha"
    @test s.dBud' == 0u"kg/ha/hr"
    @test s.WF' + s.WS' ≈ initial_total
    # The moving target may rise again. Resume forward transfer, then stop
    # at the target without overshooting or changing the combined stock.
    update!(s)
    @test s.bud_target' ≈ 30u"kg/ha"
    @test s.dBud' ≈ 5u"kg/ha/hr"
    for _ in 1:4
        update!(s)
    end
    @test s.bud' ≈ 30u"kg/ha"
    @test s.WF' ≈ 30u"kg/ha"
    @test s.WS' ≈ 970u"kg/ha"
    @test s.dBud' == 0u"kg/ha/hr"
    @test s.WF' + s.WS' ≈ initial_total
end
end
