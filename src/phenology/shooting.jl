"""
`Shooting` keeps track of new shoot growth post-coppicing.
(Model assumes tree already has a shoot at initialization).
"""
@system Shooting begin
    T_shoot => 8 ~ preserve(parameter, u"°C")
    T_shoot_opt => 32 ~ preserve(parameter, u"°C")

    shoot_max => 1e4 ~ preserve(parameter, u"kg/ha")

    shooting(F, Rf, shoot_max, shoot, WS, coppice_days,shooting_interval) => begin
        (F >= Rf) && (shoot_max >= shoot) && (WS <= shoot_max) && (coppice_days>0u"d" && coppice_days<shooting_interval)
    end ~ flag

    # Days after coppicing where reshooting can occur
    shooting_interval => begin
	365
    end ~ preserve(parameter,u"d")

    root_shoot_ratio(WR,WS,WF) => begin
        (WR)/(WS+WF)
    end ~ track()

    min_RSR:min_root_shoot_ratio => begin
         .1
    end ~ preserve(parameter)

    fraction_NSC => begin
	.1
    end ~ preserve(parameter)

    pre_shooting_weight(fraction_NSC,WR) => begin 
	fraction_NSC*WR
    end ~ track(u"kg/ha")

    non_structural_carbon(shooting,pre_shooting_weight,dShoot,shooting, non_structural_carbon,dWR) => begin
	if(shooting)
		-dShoot
        else(non_structural_carbon<pre_shooting_weight)
                dWR
        end
    end ~ accumulate(u"kg/ha",min=0u"kg/ha",init=pre_shooting_weight,max=pre_shooting_weight)

    ShD(T_air, T_shoot, T_shoot_opt): shooting_degrees => begin
        min(T_air, T_shoot_opt) - T_shoot 
    end ~ track(when=shooting, min=0, u"K")

    shoot_rate => 2 ~ preserve(parameter, u"kg/ha/hr/K")

    # Maximum shoot growth available for coppicing based on available root drymass.
    dShoot_max(WR, step,non_structural_carbon) => non_structural_carbon / step ~ track(u"kg/ha/hr")

    # Hourly shoot growth rate.
    dShoot(shoot_rate, ShD, root_shoot_ratio,non_structural_carbon,shoot,min_RSR) => begin 
        if(root_shoot_ratio<min_RSR || non_structural_carbon<=0u"kg/ha") 
	   0
        else
           shoot_rate * ShD 
        end
    end ~ track(max=dShoot_max, u"kg/ha/hr")

    # Accumulated shoot growth for the season, resets every year.
    shoot(dShoot) ~ accumulate(reset=senescent, u"kg/ha")
end
