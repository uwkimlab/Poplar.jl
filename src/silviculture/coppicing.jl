@system Coppicing begin
    coppicing_time => [] ~ preserve::Vector(parameter, optional)

    # Coppicing only possible when dormant (for now)
    coppice(coppicing_time, time, dormant) => begin
        (time in coppicing_time) && (dormant)
    end ~ flag

    # Don't have to worry about foliage during dormancy
    coppicing(step, WS, dWS) => begin
        (WS / step) - dWS
    end ~ track(when=coppice, u"kg/ha/hr")

    coppiced(WS) => begin
        WS == 0u"kg/ha"
    end ~ flag
end