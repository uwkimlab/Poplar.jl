@system Budburst begin
    # Minimum temperature for budburst
    T_bud => 8 ~ preserve(parameter, u"°C")

    # Optimal temperature for budburst
    T_bud_opt => 32 ~ preserve(parameter, u"°C")

    # Yearly target bud growth. Should possibly be a function of stem biomass?
    bud_max => 2.5e3 ~ preserve(parameter, u"kg/ha")

    # Budburst only when forcing requirement met. No budburst when coppiced i.e. WS == 0.
    budburst(F, Rf, bud_max, bud, coppiced) => begin
        (F >= Rf) && (bud_max >= bud) && !coppiced
    end ~ flag

    # Degree units for budburst. Actual
    BD(T_air, T_bud, T_bud_opt): budburst_degrees => begin
        min(T_air, T_bud_opt) - T_bud 
    end ~ track(when=budburst, min=0, u"K")

    BDD(BD): budburst_degree_days ~ accumulate(u"K*hr")

    # bud growth per degree hours
    bud_rate => 1 ~ preserve(parameter, u"kg/ha/hr/K")

    # bud growth per hour. WIP.
    dBud(bud_rate, BD) => bud_rate * BD ~ track(u"kg/ha/hr")

    # Accumulated bud growth for the year. Resets to 0 every year. Budburst halts when target is met.
    bud(dBud) ~ accumulate(reset=senescent, u"kg/ha")
end