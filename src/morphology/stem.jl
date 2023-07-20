@system Stem begin

    #==========
    Composition
    ==========#
    
    "Maximum protein composition in stems during growth with
    luxurious supply of N (g[protein]/g[stem])"
    PROSTI => 0.194 ~ preserve(parameter)

    "Normal growth protein composition in stems during growth
    (g[protein]/g[stem)"
    PROSTG => 0.145 ~ preserve(parameter)

    "Minimum stem protein composition after N mining
    (g[protein]/g[stem])"
    PROSTF => 0.035 ~ preserve(parameter)

    "Maximum N required for stem growth"
    FNINS(PROSTI) => PROSTI * 0.16 ~ preserve
    
    "Minimum N required for stem growth"
    FNINSG(PROSTG) => PROSTG * 0.16 ~ preserve

    #=========
    Parameters
    =========#

    "Initial stem drymass"
    iWS => 4000 ~ preserve(parameter, u"kg/ha")

    # growth_stem(NPP, partition_stem) => NPP * partition_stem ~ track(u"kg/ha/hr") 

    deathStem(WS, mS, mortality, trees) => begin
        mS * mortality * (WS / trees)
    end ~ track(u"kg/ha/hr", when=flagMortal, max=WS_lim)

    dWS(growth_stem, deathStem, thinning_WS, bud_delta, coppicing, dShoot) => growth_stem - deathStem - thinning_WS - bud_delta - coppicing + dShoot ~ track(u"kg/ha/hr")
    
    "Average stem mass"
    avStemMass(WS, trees) => WS / trees ~ track(u"kg")

    # Reset when coppice == true (not sure if it resets in the beginning or the end of the loop)
    WS_lim(WS, step) => WS / step ~ track(u"kg/ha/hr") 
    WS(dWS) ~ accumulate(u"kg/ha", init=iWS, min=0) # stem drymass
    WS_ton(nounit(WS)) => WS / 1000 ~ track
end