"""
`Shooting` keeps track of new shoot growth post-coppicing.
(Model assumes tree already has a shoot at initialization).
"""
@system Shooting begin
    T_shoot => 8 ~ preserve(parameter, u"°C")
    T_shoot_opt => 32 ~ preserve(parameter, u"°C")

    shoot_max => 2e4 ~ preserve(parameter, u"kg/ha")

    shooting(F, Rf, shoot_max, shoot, WS) => begin
        (F >= Rf) && (shoot_max >= shoot) && (WS <= shoot_max) 
    end ~ flag

    ShD(T_air, T_shoot, T_shoot_opt): shooting_degrees => begin
        min(T_air, T_shoot_opt) - T_shoot 
    end ~ track(when=shooting, min=0, u"K")

    shoot_rate => 2 ~ preserve(parameter, u"kg/ha/hr/K")

    # Maximum shoot growth available for coppicing based on available root drymass.
    dShoot_max(WR, step) => WR / step ~ track(u"kg/ha/hr")

    # Hourly shoot growth rate.
    dShoot(shoot_rate, ShD) => shoot_rate * ShD ~ track(max=dShoot_max, u"kg/ha/hr")

    # Accumulated shoot growth for the season, resets every year.
    shoot(dShoot) ~ accumulate(reset=senescent, u"kg/ha")
end