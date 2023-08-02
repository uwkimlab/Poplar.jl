@system Root begin

    #==========
    Composition
    ==========#

    # PROTEIN #

    "Maximum protein composition in roots during growth with luxurious supply of N (g[protein]/g[root])"
    protein_root_max => 0.092 ~ preserve(parameter)

    "Normal growth protein composition in roots during growth (g[protein]/g[root])"
    protein_root_normal => 0.064 ~ preserve(parameter)

    "Minimum root protein composition after N mining (g[protein]/g[root])"
    protein_root_min => 0.056 ~ preserve(parameter)


    # NITROGEN #

    "Maximum N required for root growth"
    N_root_max(protein_root_max) => protein_root_max * 0.16 ~ preserve

    "Minimum N required for root growth"
    N_root_min(protein_root_normal) => protein_root_normal * 0.16 ~ preserve

    N_root_init(iWR, protein_root_normal) => iWR * protein_root_normal * 0.16 ~ preserve(u"g/m^2")

    N_root_delta(growth_root_N, RTNMINE, NROFF, NADRT) => begin
        growth_root_N - RTNMINE - NROFF + NADRT
    end ~ track(u"g/m^2/hr")

    N_root(N_root_delta) ~ accumulate(u"g/m^2", init=N_root_init)

    "N available for mobilization from root above lower limit of mining"
    WNRRT(N_root, protein_root_min, WR, C_net_root) => begin
        N_root - protein_root_min * 0.16 * (WR - C_net_root)


    # CARBON #

    "Mobile CH2O concentration of root"
    PCHORTF => 0.020 ~ preserve(parameter)

    "Fraction of new root growth that is mobile C"
    C_mobile_root => 0.08 ~ preserve(parameter)

    end ~ track(min=0, u"g/m^2")
    
    C_net_root_Δ(growth_root, C_mobile_root, CMINERT, CROFF, CADRT) => begin
        growth_root * C_mobile_root - CMINERT - CROFF + CADRT
    end ~ track(u"g/m^2/hr")

    C_net_root_init(C_mobile_root, WR) => C_mobile_root * WR ~ preserve(u"g/m^2")

    "Mass of CH2O reserves in leaves"
    C_net_root(C_net_root_Δ) ~ accumulate(u"g/m^2", init=C_net_root_init)

    NADRT => 0 ~ track(u"g/m^2/hr")

    CADRT => 0 ~ track(u"g/m^2/hr")

    "Percent N in root"
    PCNRT(N_root, WR) => N_root / WR ~ track(u"percent")

    "Percent CH2O in root"
    RHOR(C_net_root, WR) => C_net_root / WR ~ track(u"percent")


    #==
    3PG
    ==#


    "Initial root drymass"
    iWR => 3000 ~ preserve(parameter, u"kg/ha")
    
    "Average monthly root turnover rate (fraction of root biomass)"
    gammaR => 0.005 ~ preserve(parameter) # Amichev

    #=====
    Growth
    =====#

    # NPP multiplied by root partition in BiomassPartition
    # "Canopy root growth rate"
    # growth_root(NPP, partition_root) => NPP * partition_root ~ track(u"kg/ha/hr") # root

    #========
    Mortality
    ========#

    # "Canopy root mortality rate"
    # deathRoot(#=WR, mR, mortality, trees=#) => begin
    #     #mR * mortality * (WR / trees)
    # end ~ track(u"kg/ha/hr", when=flagMortal)

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
    
    RFAC => 7500 ~ preserve(parameter, u"cm/g")

    dWR(growth_root, rootTurnover#=, deathRoot=#, thinning_WR, dShoot, senescence_root) => begin
        growth_root - rootTurnover#= - deathRoot=# - thinning_WR - dShoot - senescence_root
    end ~ track(u"kg/ha/hr")

    WR(dWR) ~ accumulate(u"kg/ha", init=iWR, min=0) # root drymass
    WR_ton(nounit(WR)) => WR / 1000 ~ track

    RLV(RFAC, WR, soil_depth) => WR / soil_depth * RFAC ~ track(u"cm/cm^3")
end