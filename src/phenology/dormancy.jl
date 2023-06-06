@system Dormancy begin

    
    T_dorm: temperature_threshold => 5.94915 ~ preserve(parameter, u"°C")
    Rc: chilling_requirement => -149.549 ~ preserve(parameter, u"K*d")
    Rf: forcing_requirement => 128.738 ~ preserve(parameter, u"K*d")

    dormant(WF) => begin
        WF == 0u"kg/ha"
    end ~ flag

    DD(T_air, T_dorm): dormant_degrees => (T_air - T_dorm) ~ track(when=dormant, u"K")

    dC(DD) ~ track(max = 0, u"K")
    C(dC):  chilling_accumulated ~ accumulate(when=!chilled, reset=senescent, u"K*hr")

    chilled(C, Rc) => (C <= Rc) ~ flag

    dF(DD) ~ track(min = 0, u"K")
    F(dF):  forcing_accumulated  ~ accumulate(when=chilled, reset=senescent, u"K*hr")
end