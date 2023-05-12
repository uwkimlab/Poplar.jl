@system Shooting begin
    T_shoot => 8 ~ preserve(parameter, u"°C")
    T_shoot_opt => 32 ~ preserve(parameter, u"°C")

    shoot_max => 2e4 ~ preserve(parameter, u"kg/ha")

    shooting(F, Rf, shoot_max, shoot) => begin
        (F >= Rf) && (shoot_max >= shoot)
    end ~ flag

    ShD(T_air, T_shoot, T_shoot_opt): shooting_degrees => begin
        min(T_air, T_shoot_opt) - T_shoot 
    end ~ track(when=shooting, min=0, u"K")

    shoot_rate => 2 ~ preserve(parameter, u"kg/ha/hr/K")

    dShoot(shoot_rate, ShD) => shoot_rate * ShD ~ track(u"kg/ha/hr")

    shoot(dShoot) ~ accumulate(reset=senescent, u"kg/ha")
end