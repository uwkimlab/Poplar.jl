# Senescence keeps track of senescent days and quantifies senescence based on degree days.
@system Senescence begin
    P_sen => 13 ~ preserve(parameter, u"hr")
    T_sen => 20.93 ~ preserve(parameter, u"°C")
    Tk_sen(T_sen) ~ preserve(u"K")

    Rs: senescence_requirement => 100 ~ preserve(parameter, u"K*d")
    Rld: requirement_for_leaf_drop => 0.5 ~ preserve(parameter) # percent of Rs

    senescent(day_length, P_sen, d, WF) => begin
        (day_length < P_sen) && (200u"d" < d) && (WF != 0u"kg/ha")
    end ~ flag
    
    SD(day_length, P_sen, Tk_air, Tk_sen): senescent_degrees => begin
        (Tk_sen - Tk_air) * (1 - day_length / P_sen)
    end ~ track(when=senescent, u"K")
    
    SDD(SD) ~ accumulate(reset=budburst, u"K*d")

    # applied to physiology through gs (Palm, 2022)
    s(SDD,Rs): senescence_reduction_factor => begin
        SDD/Rs
    end ~ track
    
    dSen(WF, s, step, Rld) => begin
        if s >= 1
            WF / step   # completes leaf drop when s > 1
        elseif s >= Rld
            (s - Rld) * WF / 1u"d"   # starts leaf drop when s > Rld
        else 
            0
        end
    end ~ track(u"kg/ha/hr")

    # Accumulated leaf drop for the year, resets to 0 every year - modeling meeting 10/2/26
    WFSen_annual(dSen) ~ accumulate(reset=budburst, u"kg/ha")
    WFSen_total(dSen) ~ accumulate(u"kg/ha")
end
