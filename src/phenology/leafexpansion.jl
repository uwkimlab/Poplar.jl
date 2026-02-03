@system LeafExpansion begin

    leaf_max_factor => 2 ~ preserve(parameter)
    leaf_max(bud_max, leaf_max_factor) => leaf_max_factor * bud_max ~ track(u"kg/ha")

    # Budburst only when forcing requirement met. No budburst when coppiced i.e. WS == 0.
    leafexpansion(bud_max, leaf_max, WF, senescent) => begin
        (WF > bud_max) && (WF <= leaf_max) && !senescent
    end ~ flag
end
