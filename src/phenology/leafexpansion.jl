@system LeafExpansion begin
    # set leaf_max_factor to 1 to remove leaf expansion stage (i.e. leaf_max = bud_target)
    # Recommended: on with constant BBCH, off with allometric partition types
    leaf_max_factor => 2 ~ preserve(parameter)

    # maximum leaf foliage for leaf expansion stage
    leaf_max(bud_target, leaf_max_factor) => leaf_max_factor * bud_target ~ track(u"kg/ha")

    # Leaf expansion occurs when bud_target is met and leaf_max is not met
    leafexpansion(bud_target, leaf_max, WF, senescent) => begin
        (WF > bud_target) && (WF <= leaf_max) && !senescent
    end ~ flag
end
