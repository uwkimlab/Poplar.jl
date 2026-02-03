@system Budburst begin

    #=========
    Parameters
    =========#

    "Minimum temperature for budburst"
    T_bud_min => 5 ~ preserve(parameter, u"°C")

    "Optimal temperature for budburst"
    T_bud_opt => 20 ~ preserve(parameter, u"°C")

    "Maximum temperature for budburst"
    T_bud_max => 40 ~ preserve(parameter, u"°C")

    # Yearly target bud growth. Should possibly be a function of stem biomass?
    # bud_max => 1e3 ~ preserve(parameter, u"kg/ha")
    bud_max_factor => 0.1 ~ preserve(parameter)
    bud_max(bud_max_factor, WD) => bud_max_factor * WD ~ track(u"kg/ha")

    # bud growth per degree hours
    bud_rate => 1 ~ preserve(parameter, u"kg/ha/hr/K")  


    #=========
    =========#

    # Budburst only when forcing requirement met. No budburst when coppiced i.e. WS == 0.
    budburst(F, Rf, bud_max, WF) => begin
        (F >= Rf) && (bud_max >= WF)
    end ~ flag

    # Degree units for budburst. Actual
    BD(T=T_air, Tb=T_bud_min, To=T_bud_opt, Tx=T_bud_max): budburst_degrees => begin
        T = !isnothing(To) ? min(T, To) : T
        T = !isnothing(Tx) && T >= Tx ? Tb : T
        T - Tb
        # min(T_air, T_bud_opt) - T_bud 
    end ~ track(when=budburst, min=0, u"K")

    BDD(BD): budburst_degree_days ~ accumulate(u"K*hr")

    dBud_max(WS, step) => WS / step ~ track(u"kg/ha/hr")

    # bud growth per hour (WIP).
    dBud(bud_rate, BD) => bud_rate * BD ~ track(max=dBud_max, u"kg/ha/hr")

    # Accumulated bud growth for the year. Resets to 0 every year. Budburst halts when target is met.
    # bud(dBud) ~ accumulate(reset=senescent, u"kg/ha")
end
