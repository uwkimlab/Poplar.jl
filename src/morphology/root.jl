@system Root begin

    #=========
    Parameters
    =========#

    carbohydrate_root ~ preserve(parameter)
    lignin_root ~ preserve(parameter)
    lipid_root ~ preserve(parameter)
    mineral_root ~ preserve(parameter)
    organic_root ~ preserve(parameter)

    "Initial root drymass"
    iWR => 3000 ~ preserve(parameter, u"kg/ha")
    
    "Average monthly root turnover rate"
    gammaR => 0.005 ~ preserve(parameter) # Amichev

    #=====
    Growth
    =====#

    # NPP multiplied by root partition in BiomassPartition
    "Canopy root growth rate"
    growth_root(NPP, pR) => NPP * pR ~ track(u"kg/ha/hr") # root

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
    
    dWR(growth_root, rootTurnover, deathRoot, thinning_WR, dShoot) => growth_root - rootTurnover - deathRoot - thinning_WR - dShoot ~ track(u"kg/ha/hr")
    WR(dWR) ~ accumulate(u"kg/ha", init=iWR, min=0) # root drymass
    WR_ton(nounit(WR)) => WR / 1000 ~ track
end