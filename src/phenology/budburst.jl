@system Budburst begin
    T_bud => 8 ~ preserve(parameter, u"°C")
    T_bud_opt => 32 ~ preserve(parameter, u"°C")

    Bud_max => 2.5e3 ~ preserve(parameter, u"kg/ha")

    budburst(F, Rf, Bud_max, Bud, coppiced) => begin
        (F >= Rf) && (Bud_max >= Bud) && !coppiced
    end ~ flag

    BD(T_air, T_bud, T_bud_opt): budburst_degrees => begin
        min(T_air, T_bud_opt) - T_bud 
    end ~ track(when=budburst, min=0, u"K")

    BDD(BD): budburst_degree_days ~ accumulate(u"K*hr")

    rBud => 1 ~ preserve(parameter, u"kg/ha/hr/K")

    dBud(rBud, BD) => rBud * BD ~ track(u"kg/ha/hr")

    Bud(dBud) ~ accumulate(reset=senescent, u"kg/ha")
end