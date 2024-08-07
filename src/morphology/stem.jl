@system Stem begin
    #=========
    Parameters
    =========#

    "Initial stem drymass"
    iWS => 4000 ~ preserve(parameter, u"kg/ha")

    "Stem nitrogen ratio"
    N_ratio_stem => 0.01 ~ preserve(parameter)

    #=====
    Growth
    =====#

    growthStem(NPP, pS) => NPP * pS ~ track(u"kg/ha/hr") 

    #========
    Mortality
    ========#

    deathStem(WS, mS, mortality, stemNo) => begin
        mS * mortality * (WS / stemNo)
    end ~ track(u"kg/ha/hr", when=flagMortal, max=WS_lim)

    #=====
    Weight
    =====#

    dWS(growthStem, N_stress, deathStem, thinning_WS, dBud, coppicing, dShoot) => growthStem * N_stress - deathStem - thinning_WS - dBud - coppicing + dShoot ~ track(u"kg/ha/hr")
    
    "Average stem mass"
    avStemMass(WS, stemNo) => WS / stemNo ~ track(u"kg")

    # Reset when coppice == true (not sure if it resets in the beginning or the end of the loop)
    WS_lim(WS, step) => WS / step ~ track(u"kg/ha/hr") 
    WS(dWS) ~ accumulate(u"kg/ha", init=iWS, min=0) # stem drymass
    WS_ton(nounit(WS)) => WS / 1000 ~ track
end