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

    "Root turnover rate"
    gammaRhour(date, gammaR) => begin
        (1 - (1 - gammaR)^(1 / daysinmonth(date) / 24)) / u"hr"
    end ~ track(u"hr^-1")

    "Root turnover"
    rootTurnover(gammaRhour, WR) => gammaRhour * WR ~ track(u"kg/ha/hr")

    #=====
    Weight
    =====#
    
    dWR(growthRoot, rootTurnover, deathRoot) => growthRoot - rootTurnover - deathRoot ~ track(u"kg/ha/hr")
    WR(dWR) ~ accumulate(u"kg/ha", init=iWR) # root drymass
end