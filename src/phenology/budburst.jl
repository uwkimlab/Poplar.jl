@system Budburst begin
    
    #=========
    Parameters
    =========#

    # 1--constant; 2--allometric DBH (original 3PG); 3--allometric VI (Hart, 2015)
    "Switch parameter to control bud allocation type"
    bud_allocation_type => 1 ~ preserve(parameter) 

    "Minimum temperature for budburst"
    T_bud_min => 5 ~ preserve(parameter, u"°C")

    "Optimal temperature for budburst"
    T_bud_opt => 20 ~ preserve(parameter, u"°C")

    "Maximum temperature for budburst"
    T_bud_max => 40 ~ preserve(parameter, u"°C")

    "Yearly target bud growth as constant"
    bud_target_const => 1e3 ~ preserve(parameter, u"kg/ha") 
  
    "Yearly target bud growth as fraction of target foliage mass"
    bud_max_factor => 0.3 ~ preserve(parameter) 
    
    # bud growth per degree hours
    bud_rate => 1 ~ preserve(parameter, u"kg/ha/hr/K")  

    #=========
    =========#

    "Target foliage mass per stem"
    avTargetWF(avTargetWF_vi, avTargetWF_dbh, bud_allocation_type, partition_type) => begin
        if bud_allocation_type != partition_type
            @warn "bud_allocation_type = $bud_allocation_type does not match partition_type = $partition_type"
        end
        if bud_allocation_type == 1
            0
        elseif bud_allocation_type == 2
            avTargetWF_dbh
        elseif bud_allocation_type == 3
            avTargetWF_vi
        else
            @error "Invalid bud_allocation_type: $bud_allocation_type use 1, 2 or 3 for constnat, DBH or VI, respectively"
        end
    end ~ track(u"g")

    # Budburst only when forcing requirement met. No budburst when coppiced i.e. WS == 0. Budburst halts when target bud_target is met.
    budburst(F, Rf, bud_target, WF) => begin
        (F >= Rf) && (bud_target >= WF)
    end ~ flag

    # Degree units for budburst. Actual
    BD(T=T_air, Tb=T_bud_min, To=T_bud_opt, Tx=T_bud_max): budburst_degrees => begin
        T = !isnothing(To) ? min(T, To) : T
        T = !isnothing(Tx) && T >= Tx ? Tb : T
        T - Tb
        # min(T_air, T_bud_opt) - T_bud 
    end ~ track(when=budburst, min=0, u"K")

    BDD(BD): budburst_degree_days ~ accumulate(u"K*hr")

    # bud_max limits bud_target to fraction of maximum foliage mass (i.e. WS * pFSmax) 
    bud_max(bud_allocation_type, bud_max_factor, WS, pFSmax, bud_target_const) => begin
        bud_allocation_type == 1 ? bud_target_const : bud_max_factor * WS * pFSmax
    end ~ track(u"kg/ha")

    # yearly amount of stem mass allocated to bud growth as fraction of target folilage mass
    bud_target(bud_allocation_type, bud_max_factor, avTargetWF, stemNo, bud_target_const) => begin
        bud_allocation_type == 1 ? bud_target_const : bud_max_factor * avTargetWF * stemNo
    end ~ track(u"kg/ha", max=bud_max)
   
    # mass of buds remaining
    bud_mass(bud_target, bud) => bud_target - bud ~ track(u"kg/ha")

    # maximum bud growth per hour
    dBud_max(bud_mass, step) => bud_mass / step ~ track(u"kg/ha/hr")

    # bud growth per hour
    dBud(bud_rate, BD) => bud_rate * BD ~ track(max=dBud_max, u"kg/ha/hr")

    # Accumulated bud growth for the year. Resets to 0 every year. 
    bud(dBud) ~ accumulate(reset=senescent, u"kg/ha")
end
