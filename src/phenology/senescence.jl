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

    # Retain full progress for leaf drop without changing accumulated temperature.
    senescence_progress(SDD, Rs) => begin
        SDD/Rs
    end ~ track(min=0, max=1)

    # Applied to physiology through gs (Palm, 2022). The numerical margin
    # avoids the original stomatal solver's zero slope at full senescence.
    # It does not handle zero slopes caused by other inputs (e.g. A_net=0).
    s(senescence_progress): senescence_reduction_factor => senescence_progress ~ track(min=0, max=1-1e-6)
    
    dSen(WF, senescence_progress, step, Rld) => begin
        if senescence_progress >= 1
            WF / step   # completes leaf drop at full progress
        elseif senescence_progress >= Rld
            (senescence_progress - Rld) * WF / 1u"d"
        else 
            0
        end
    end ~ track(u"kg/ha/hr")

    # Accumulated leaf drop for the year, resets to 0 every year - modeling meeting 10/2/26
    WFSen_annual(dSen) ~ accumulate(reset=budburst, u"kg/ha")
    WFSen_total(dSen) ~ accumulate(u"kg/ha")
end
