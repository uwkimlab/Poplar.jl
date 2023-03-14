@system Root begin

    "Initial root drymass"
    iWR ~ preserve(parameter, u"kg/ha")

    growthRoot(NPP, pR) => NPP * pR ~ track(u"kg/ha/hr") # root

    deathRoot(WR, mR, mortality, stemNo) => begin
        mR * mortality * (WR / stemNo)
    end ~ track(u"kg/ha/hr", when=flagMortal)

    "Average monthly root turnover rate"
    gammaR  ~ preserve(parameter)

    gammaRhour(calendar, gammaR) => begin
        (1 - (1 - gammaR)^(1 / daysinmonth(calendar.date') / 24)) / u"hr"
    end ~ track(u"hr^-1")

    rootTurnover(gammaRhour, WR) => gammaRhour * WR ~ track(u"kg/ha/hr")
    
    dWR(growthRoot, rootTurnover, deathRoot) => growthRoot - rootTurnover - deathRoot ~ track(u"kg/ha/hr")
    WR(dWR) ~ accumulate(u"kg/ha", init=iWR) # root drymass
end