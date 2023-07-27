@system Stem begin

    #==========
    Composition
    ==========#
    
    "Maximum protein composition in stems during growth with luxurious supply of N (g[protein]/g[stem])"
    PROSTI => 0.194 ~ preserve(parameter)

    "Normal growth protein composition in stems during growth (g[protein]/g[stem)"
    PROSTG => 0.145 ~ preserve(parameter)

    "Minimum stem protein composition after N mining  (g[protein]/g[stem])"
    PROSTF => 0.035 ~ preserve(parameter)

    "Maximum N required for stem growth"
    FNINS(PROSTI) => PROSTI * 0.16 ~ preserve
    
    "Minimum N required for stem growth"
    FNINSG(PROSTG) => PROSTG * 0.16 ~ preserve

    "Percent N in stem"
    PCNST(N_stem, WS) => N_stem / WS ~ track(u"percent")

    "Mobile CH2O contentration of stem"
    PCHOSTF => 0.008 ~ preserve(parameter)

    "Fraction of new stem growth that is mobile C"
    ALPHS => 0.08 ~ preserve(parameter)

    N_stem_init(iWS, PROSTG) => iWS * PROSTG * 0.16 ~ preserve(u"g/m^2")

    N_stem_delta(growth_stem_N, STNMINE, NSOFF, NADST) => begin
        growth_stem_N - STNMINE - STOFF + NADST
    end ~ track(u"g/m^2/hr")

    N_stem(N_stem_delta) ~ accumulate(init=0, u"g/m^2")

    "N available for mobilization from stem above lower limit of mining"
    WNRST(N_stem, PROSTF, WS, WCRST) => begin
        N_stem - PROSTF * 0.16 * (WS - WCRST)
    end ~ track(min=0, u"g/m^2")

    WCRSDT(growth_stem, ALPHS, CMINEST, CSOFF) => begin
        growth_stem * ALPHS - CMINEST - CSOFF + CADLF
    end ~ track(u"g/m^2/hr")

    WCRSTi(ALPHS, WS) => ALPHS * WS ~ preserve(u"g/m^2")

    WCRST(WCRSDT) ~ accumulate(u"g/m^2", init=WCRSTi)

    NADST => 0 ~ track(u"g/m^2/hr")

    CADST => 0 ~ track(u"g/m^2/hr")

    "Percent N in stem"
    PCNS(N_stem, WS) => N_stem / WS ~ track(u"percent")

    "Percent CH2O in stem"
    RHOS(WCRST, WS) => WCRST / WS ~ track(u"percent")

    #=========
    Parameters
    =========#

    "Initial stem drymass"
    iWS => 4000 ~ preserve(parameter, u"kg/ha")

    # growth_stem(NPP, partition_stem) => NPP * partition_stem ~ track(u"kg/ha/hr") 

    # deathStem(WS, mS, mortality, trees) => begin
    #     mS * mortality * (WS / trees)
    # end ~ track(u"kg/ha/hr", when=flagMortal, max=WS_lim)

    dWS(growth_stem,#= deathStem,=# thinning_WS, bud_delta, coppicing, dShoot, senescence_stem) => begin
        growth_stem #=- deathStem=# - thinning_WS - bud_delta - coppicing + dShoot - senescence_stem
    end ~ track(u"kg/ha/hr")
    
    "Average stem mass"
    avStemMass(WS, trees) => WS / trees ~ track(u"kg")

    # Reset when coppice == true (not sure if it resets in the beginning or the end of the loop)
    WS_lim(WS, step) => WS / step ~ track(u"kg/ha/hr") 
    WS(dWS) ~ accumulate(u"kg/ha", init=iWS, min=0) # stem drymass
    WS_ton(nounit(WS)) => WS / 1000 ~ track
end