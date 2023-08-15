@system Coppicing begin
    # Coppicing dates in the form of a vector of ZonedDateTime values.
    # Example in configuration in config.jl
    coppicing_date => [] ~ preserve::Vector(parameter, optional)

    # Coppicing only possible when dormant (for now), 
    coppice(coppicing_date, time, dormant) => begin
        (time in coppicing_date) && (dormant)
    end ~ flag

    # Don't have to worry about foliage during dormancy
    coppicing(step, WS, growth_stem, deathStem, thinning_WS, bud_delta) => begin
        (WS / step) - (growth_stem - deathStem - thinning_WS - bud_delta)
    end ~ track(when=coppice, u"kg/ha/hr")

    # Coppiced when stem biomass is zero.
    coppiced(WS, W) => begin
        WS == 0u"kg/ha" && W != 0u"kg/ha"
    end ~ flag
end