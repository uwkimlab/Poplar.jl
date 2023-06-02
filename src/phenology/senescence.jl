# Senescence keeps track of senescent days and quantifies senescence based on degree days.
@system Senescence begin
    P_sen => 13 ~ preserve(parameter, u"hr")
    T_sen => 20.93 ~ preserve(parameter, u"°C")
    Tk_sen(T_sen) ~ preserve(u"K")

    senescent(T_air, T_sen, day_length, P_sen, d, WF) => begin
        (T_air < T_sen) && (day_length < P_sen) && (200u"d" < d) && (WF != 0u"kg/ha")
    end ~ flag
    
    SD(day_length, P_sen, Tk_air, Tk_sen): senescent_degrees => begin
        (Tk_sen - Tk_air) * (day_length / P_sen)
    end ~ track(when=senescent, u"K")

    rSen => 1 ~ preserve(parameter, u"kg/ha/hr/K")

    dSen(rSen, SD) => rSen * SD ~ track(u"kg/ha/hr")

    # SDD(SD) ~ accumulate(u"K*hr")
end