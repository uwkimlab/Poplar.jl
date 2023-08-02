"Calculates "
@system Senescence begin
    "Photoperiod threshold for senescence"
    P_sen => 13 ~ preserve(parameter, u"hr")

    "Temperature threshold for senescence in Celsius"
    T_sen => 20.93 ~ preserve(parameter, u"°C")

    "Temperature threshold for senescence in Kelvin"
    Tk_sen(T_sen) ~ preserve(u"K")

    "Flag for whether tree is going through autumnal senescence"
    senescent(T_air, T_sen, day_length, P_sen, d, WF) => begin
        (T_air < T_sen) && (day_length < P_sen) && (200u"d" < d) && (WF != 0u"kg/ha")
    end ~ flag
    
    ""
    SD(day_length, P_sen, Tk_air, Tk_sen): senescent_degrees => begin
        (Tk_sen - Tk_air) * (day_length / P_sen)
    end ~ track(when=senescent, u"K")

    "Arbitrary senescence rate per senescent degree"
    senescence_rate => 1 ~ preserve(parameter, u"kg/ha/hr/K")

    "Rate of leaf senescence"
    senescence_delta(senescence_rate, SD) => senescence_rate * SD ~ track(u"kg/ha/hr")

    # SDD(SD) ~ accumulate(u"K*hr")

end