@system Coppicing begin
    # Coppicing dates in the form of a vector of ZonedDateTime values.
    # Example in configuration in config.jl
    coppicing_date => [] ~ preserve::Vector(parameter, optional)

    # Coppicing only possible when dormant (for now), 
    coppice(coppicing_date, time, dormant) => begin
        (time in coppicing_date) && (dormant)
    end ~ flag

    # Don't have to worry about foliage during dormancy
    coppicing(step, WS, growthStem, deathStem, thinning_WS, dBud) => begin
        (WS / step) - (growthStem - deathStem - thinning_WS - dBud)
    end ~ track(when=coppice, u"kg/ha/hr")

    # Coppiced when stem biomass is zero.
    coppiced(WS, W) => begin
        WS == 0u"kg/ha" && W != 0u"kg/ha"
    end ~ flag
end