@system Coppicing begin
    coppicing_date => [] ~ preserve::Vector(parameter, optional)

    # Coppicing only possible when dormant (for now), 
    coppice(coppicing_date, time, dormant) => begin
        (time in coppicing_date) && (dormant)
    end ~ flag

    # Don't have to worry about foliage during dormancy
    coppicing(step, WS, growthStem, deathStem, thinning_WS, dBud) => begin
        (WS / step) - (growthStem - deathStem - thinning_WS - dBud)
    end ~ track(when=coppice, u"kg/ha/hr")

    # Coppicing 
    coppiced(WS) => begin
        WS == 0u"kg/ha"
    end ~ flag

    # Root partition predetermined when coppiced?
    # Possibly set 
end