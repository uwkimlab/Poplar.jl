@system Root begin

    #==========
    Composition
    ==========#

    "Maximum protein composition in roots during growth with
    luxurious supply of N (g[protein]/g[root])"
    PRORTI => 0.092 ~ preserve(parameter)

    "Normal growth protein composition in roots during growth
    (g[protein]/g[root])"
    PRORTG => 0.064 ~ preserve(parameter)

    "Minimum root protein composition after N mining
    (g[protein]/g[root])"
    PRORTF => 0.056 ~ preserve(parameter)

    "Maximum N required for root growth"
    FNINR(PRORTI) => PRORTI * 0.16 ~ preserve

    "Minimum N required for root growth"
    FNINRG(PRORTG) => PRORTG * 0.16 ~ preserve

    PCNRT(WTNRT, WRTI) => WTNRT / WRTI ~ track(u"percent")

    "Mobile CH2O concentration of root"
    PCHORTF => 0.020 ~ preserve(parameter)

    "Fraction of new root growth that is mobile C"
    ALPHR => 0.08 ~ preserve(parameter)
    
    #=========
    Parameters
    =========#


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

    "Canopy root mortality rate"
    deathRoot(WR, mR, mortality, trees) => begin
        mR * mortality * (WR / trees)
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
    
    RFAC1 => 7500 ~ preserve(parameter, u"cm/g")

    dWR(growth_root, rootTurnover, deathRoot, thinning_WR, dShoot) => growth_root - rootTurnover - deathRoot - thinning_WR - dShoot ~ track(u"kg/ha/hr")
    WR(dWR) ~ accumulate(u"kg/ha", init=iWR, min=0) # root drymass
    WR_ton(nounit(WR)) => WR / 1000 ~ track

    RLV(RFAC1, WR, soil_depth) => WR / soil_depth * RFAC1 ~ track(u"cm/cm^3")
end