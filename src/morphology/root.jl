@system Root begin

    #=========
    Parameters
    =========#

    "Initial root drymass"
    iWR ~ preserve(parameter, u"kg/ha")
    
    "Average monthly root turnover rate"
    gammaR => 0.005 ~ preserve(parameter)

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
    
    dWR(growthRoot, rootTurnover, deathRoot, thinning_WR, dShoot) => growthRoot - rootTurnover - deathRoot - thinning_WR - dShoot ~ track(u"kg/ha/hr")
    WR(dWR) ~ accumulate(u"kg/ha", init=iWR, min=0) # root drymass
end