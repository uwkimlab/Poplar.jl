@system Shooting begin
    T_shoot => 8 ~ preserve(parameter, u"°C")
    T_shoot_opt => 32 ~ preserve(parameter, u"°C")

    shoot_max => 2.5e3 ~ preserve(parameter, u"kg/ha")

    shooting(F, Rf, shoot_max, shoot) => begin
        (F >= Rf) && (bud_max >= bud) && !coppiced
    end ~ flag

    SD(T_air, T_shoot, T_shoot_opt): shooting_degrees => begin
        min(T_air, T_shoot_opt) - T_bud 
    end ~ track(when=shooting, min=0, u"K")

    shoot_rate => 1 ~ preserve(parameter, u"kg/ha/hr/K")

    dBud(bud_rate, BD) => bud_rate * BD ~ track(u"kg/ha/hr")

    bud(dBud) ~ accumulate(reset=senescent, u"kg/ha")
end