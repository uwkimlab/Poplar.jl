@system LeafExpansion begin

    dWD(W, x=context.clock.step) => W/x^2 ~ capture(u"kg/ha/hr", when=dormant)
    WD(dWD): dormant_biomass ~ accumulate(u"kg/ha", max=W)

    leaf_max_percent => 0.25 ~ preserve(parameter)
    leaf_max(WD, leaf_max_percent) => leaf_max_percent * WD ~ track(u"kg/ha")

    # Budburst only when forcing requirement met. No budburst when coppiced i.e. WS == 0.
    leafexpansion(bud_max, leaf_max, WF, senescent) => begin
        (WF > bud_max) && (WF <= leaf_max) && !senescent
    end ~ flag
end
