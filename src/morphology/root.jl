@system Root begin

    #=========
    Parameters
    =========#

    "Initial root drymass"
    iWR => 3000 ~ preserve(parameter, u"kg/ha")
    
    "Average monthly root turnover rate"
    gammaR => 0.005 ~ preserve(parameter) # Amichev

    "Root nitrogen ratio"
    N_ratio_root => 0.01 ~ preserve(parameter)

    #=====
    Growth
    =====#

    # NPP multiplied by root partition in BiomassPartition
    "Canopy root growth rate"
    growthRoot(NPP, pR) => NPP * pR ~ track(u"kg/ha/hr") # root

    #========
    Mortality
    ========#

    "Canopy root mortality rate"
    deathRoot(WR, mR, mortality, stemNo) => begin
        mR * mortality * (WR / stemNo)
    end ~ track(u"kg/ha/hr", when=flagMortal)

    #=======
    Turnover
    =======#

    # Turnover rate in 3PG was monthly. Converted to hourly.
    "Root turnover rate"
    gammaRhour(date, gammaR) => begin
        (1 - (1 - gammaR)^(1 / daysinmonth(date) / 24)) / u"hr"
    end ~ track(u"hr^-1")

    "Root turnover"
    rootTurnover(gammaRhour, WR) => gammaRhour * WR ~ track(u"kg/ha/hr")

    #========
    Coppicing
    ========#
    # root mass repartitioned when coppiced == true
    # root_partition()

    #=====
    Weight
    =====#
    
    dWR(growthRoot, N_stress, rootTurnover, deathRoot, thinning_WR, dShoot) => growthRoot * N_stress - rootTurnover - deathRoot - thinning_WR - dShoot ~ track(u"kg/ha/hr")
    WR(dWR) ~ accumulate(u"kg/ha", init=iWR, min=0) # root drymass
    WR_ton(nounit(WR)) => WR / 1000 ~ track

    #==
    ==#
    "Specific root length"
    SRL => 20 ~ preserve(parameter, u"cm/g")

    # From CROPGRO
    "Root length density"
    RLD(WR, soil_depth, SRL) => WR / soil_depth * SRL ~ track(u"cm/cm^3")

    # root respiration
    Q10_root_below30C: root_temperature_sensitivity_conefficient_below30C => 2.0 ~ preserve(parameter) #dimensionless
    Q10_root_above30C: root_temperature_sensitivity_conefficient_above30C => 1.61 ~ preserve(parameter) #dimensionless
    k_root_20: root_maintenance_rate_at_20C => 24 * 1000 ~ preserve(parameter, u"ng/kg/s"#=gCHO 20to30oC=#)
    k_root_30(q=Q10_root_below30C, k_root_20): root_maintenance_rate_at_30C => begin
        k_root_20 * q^((30-20)/10)
    end~track(u"ng/kg/s"#=gCHO 30to40oC=#)

    Root_Rp(k_root_20, k_root_30, WR, a = Q10_root_below30C, b=Q10_root_above30C, nounit(T_air)): root_maintenance_respiration => begin
        if T_air < 30
            k_root_20 * WR * a^((T_air-20) / 10)
        else
            k_root_30 * WR * b^((T_air-30) / 10)
        end
    end ~ track(u"g/ha/hr"#=g CHO=#)

end
