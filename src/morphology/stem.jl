@system Stem begin

    #==========
    Composition
    ==========#
    
    "Maximum protein composition in stems during growth with luxurious supply of N (g[protein]/g[stem])"
    protein_stem_max => 0.194 ~ preserve(parameter)

    "Normal growth protein composition in stems during growth (g[protein]/g[stem)"
    protein_stem_normal => 0.145 ~ preserve(parameter)

    "Minimum stem protein composition after N mining  (g[protein]/g[stem])"
    protein_stem_min => 0.035 ~ preserve(parameter)

    "Maximum N required for stem growth"
    N_stem_max(protein_stem_max) => protein_stem_max * 0.16 ~ preserve
    
    "Minimum N required for stem growth"
    N_stem_min(protein_stem_normal) => protein_stem_normal * 0.16 ~ preserve

    "Mobile CH2O contentration of stem"
    PCHOSTF => 0.008 ~ preserve(parameter)

    "Fraction of new stem growth that is mobile C"
    C_mobile_stem => 0.08 ~ preserve(parameter)

    N_stem_init(iWS, protein_stem_normal) => iWS * protein_stem_normal * 0.16 ~ preserve(u"g/m^2")

    N_stem_delta(growth_stem_N, STNMINE, NSOFF, NADST) => begin
        growth_stem_N - STNMINE - NSOFF + NADST
    end ~ track(u"g/m^2/hr")

    N_stem(N_stem_delta) ~ accumulate(init=0, u"g/m^2")

    "N available for mobilization from stem above lower limit of mining"
    WNRST(N_stem, protein_stem_min, WS, C_net_stem) => begin
        N_stem - protein_stem_min * 0.16 * (WS - C_net_stem)
    end ~ track(min=0, u"g/m^2")

    C_net_stem_Δ(growth_stem, C_mobile_stem, CMINEST, CSOFF, CADST) => begin
        growth_stem * C_mobile_stem - CMINEST - CSOFF + CADST
    end ~ track(u"g/m^2/hr")

    C_net_stem_init(C_mobile_stem, WS) => C_mobile_stem * WS ~ preserve(u"g/m^2")

    C_net_stem(C_net_stem_Δ) ~ accumulate(u"g/m^2", init=C_net_stem_init)

    NADST => 0 ~ track(u"g/m^2/hr")

    CADST => 0 ~ track(u"g/m^2/hr")

    "Percent N in stem"
    PCNST(N_stem, WS) => N_stem / WS ~ track(u"percent")

    "Percent CH2O in stem"
    RHOS(C_net_stem, WS) => C_net_stem / WS ~ track(u"percent")

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