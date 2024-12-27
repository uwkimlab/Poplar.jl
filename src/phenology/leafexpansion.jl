@system LeafExpansion begin

    leaf_max => 2e3 ~ preserve(parameter, u"kg/ha")

    # Budburst only when forcing requirement met. No budburst when coppiced i.e. WS == 0.
    leafexpansion(bud_max, leaf_max, WF, senescent) => begin
        (WF > bud_max) && (WF <= leaf_max) && !senescent
    end ~ flag
end
