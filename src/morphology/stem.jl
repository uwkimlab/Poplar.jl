@system Stem begin
    #=========
    Parameters
    =========#

    "Initial stem drymass"
    iWS => 2000 ~ preserve(parameter, u"kg/ha")

    growthStem(NPP, pS) => NPP * pS ~ track(u"kg/ha/hr") 

    deathStem(WS, mS, mortality, stemNo) => begin
        mS * mortality * (WS / stemNo)
    end ~ track(u"kg/ha/hr", when=flagMortal)

    dWS(growthStem, deathStem, thinning_WS, dBud, coppicing) => growthStem - deathStem - thinning_WS - dBud - coppicing ~ track(u"kg/ha/hr")
    
    "Average stem mass"
    avStemMass(WS, stemNo) => WS / stemNo ~ track(u"kg")

    # Reset when coppice == true (not sure if it resets in the beginning or the end of the loop)
    WS(dWS) ~ accumulate(u"kg/ha", init=iWS, min=0) # stem drymass
end