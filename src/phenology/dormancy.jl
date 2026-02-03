@enum DormancyType begin
    sequential = 0
    parallel = 1
    photoperiod = 2
end

@system Dormancy begin

    dormancy_type => parallel ~ preserve::DormancyType(parameter)

    T_dorm: temperature_threshold => 5.94915 ~ preserve(parameter, u"°C")

    Rc: chilling_requirement => begin
        -100
        #-149.549
    end ~ preserve(parameter, u"K*d")

    Rf: forcing_requirement => 100 ~ preserve(parameter, u"K*d")

    dormant(WF) => begin
        WF == 0u"kg/ha"
    end ~ flag

    DD(T_air, T_dorm): dormant_degrees => (T_air - T_dorm) ~ track(when=dormant, u"K")

    # arbitrary parameter value
    δ: photosensitvity => 0.1 ~ preserve(parameter, u"K/hr")

    # arbitrary parameter value
    Kmin: minimum_competence => 0.1 ~ preserve(parameter)
    
    # Kramer (1994) Eq. 6 
    K(Kmin,Rc,C): competence_function => begin
        Kmin + (1-Kmin)/Rc*C
    end ~ track(max=1)

    dC(DD, δ, day_length, dormancy_type) => begin
        if dormancy_type == photoperiod 
            DD - δ * day_length # Kramer (1994) Eq. 15
        else
            DD
        end
    end ~ track(max = 0, u"K")
    C(dC):  chilling_accumulated ~ accumulate(when=!chilled, reset=senescent, u"K*hr")

    chilled(C, Rc) => (C <= Rc) ~ flag

    dF(DD) ~ track(min = 0, u"K")

    F(K,dF,dormancy_type,chilled): forcing_accumulated => begin
        if dormancy_type == parallel    
            K * dF
        elseif (dormancy_type == sequential || dormancy_type == photoperiod) && chilled 
            dF
        else
            0
        end
    end ~ accumulate(reset=senescent, u"K*hr")

    # track biomass during dormancy to inform bud_max and leaf_max
    dWD(W, x=context.clock.step) => W/x^2 ~ capture(u"kg/ha/hr", when=dormant)
    WD(dWD): dormant_biomass ~ accumulate(u"kg/ha", max=W)

end
