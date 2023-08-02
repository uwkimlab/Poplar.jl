include("radiation.jl")

"""
Foliage system.
"""
@system Foliage(Radiation) begin

    #==========
    Composition
    ==========#

    # PROTEIN #
    "Maximum protein composition in leaves during growth with luxurious supply of N (g[protein]/g[leaf])"
    protein_leaf_max => 0.372 ~ preserve(parameter)

    "Normal growth protein composition in leaves during growth (g[protein]/g[leaf)"
    protein_leaf_normal => 0.291 ~ preserve(parameter)

    "Minimum leaf protein composition after N mining (g[protein]/g[leaf])"
    protein_leaf_min => 0.112 ~ preserve(parameter)

    "Maximum N required for leaf growth"
    N_leaf_max(protein_leaf_max) => protein_leaf_max * 0.16 ~ preserve

    # NITROGEN #
    "Minimum N required for leaf growth.
    As you can see, the 'normal' amount of protein is necessary for growth."
    N_leaf_min(protein_leaf_normal) => protein_leaf_normal * 0.16 ~ preserve

    "Initial N foliage"
    N_foliage_init(iWF, protein_leaf_normal) => iWF * protein_leaf_normal * 0.16 ~ preserve(u"g/m^2")

    "Hourly change in foliage nitrogen"
    N_foliage_delta(growth_foliage_N, LFNMINE, NLOFF, NADLF) => begin
        growth_foliage_N - LFNMINE - NLOFF + NADLF
    end ~ track(u"g/m^2/hr")

    "Mass of N in leaves"
    N_foliage(N_foliage_delta) ~ accumulate(init=N_foliage_init, u"g/m^2")

    "N available for mobilization from foliage above lower limit of mining"
    WNRLF(N_foliage, protein_leaf_min, WF, C_net_leaf) => begin
        N_foliage - protein_leaf_min * 0.16 * (WF - C_net_leaf)
    end ~ track(min=0, u"g/m^2")

    "Percent N in foliage"
    PCNL(N_foliage, WF) => N_foliage / WF ~ track(u"percent")

    PWLF => 4 ~ preserve(parameter)

    "N reserve leaf"
    NADLF => 0 ~ track(u"g/m^2/hr")

    # CARBON #
    "Fraction of new leaf growth that is mobile C"
    C_mobile_leaf => 0.04 ~ preserve(parameter)

    "Hourly change in foliage CH2O"
    C_net_leaf_Δ(growth_foliage, C_mobile_leaf, CMINELF, CLOFF, CADLF) => begin
        growth_foliage*C_mobile_leaf - CMINELF - CLOFF + CADLF
    end ~ track(u"g/m^2/hr")

    "Initial foliage CH2O"
    C_net_leaf_init(C_mobile_leaf, WF) => C_mobile_leaf * WF ~ preserve(u"g/m^2")

    "Mass of CH2O reserves in leaves"
    C_net_leaf(C_net_leaf_Δ) ~ accumulate(u"g/m^2", init=C_net_leaf_init)

    "Percent CH2O in foliage"
    RHOL(C_net_leaf, WF) => C_net_leaf/ WF ~ track(u"percent")

    "Proportion of mobile CH2O remaining in senesced leaf tissue"
    PCHOLFF => 0.004 ~ preserve(parameter)

    "C reserve leaf"
    CADLF => 0 ~ track(u"g/m^2/hr")

    #==
    3PG
    ==#

    "Initial foliage drymass"
    iWF => 1000 ~ preserve(parameter, u"kg/ha")

    # Specific leaf area
    "Specific leaf area at age 0"
    SLA0 => 10.8 ~ preserve(parameter, u"m^2/kg") # Amichev
    
    "Specfic leaf area for mature leaves"
    SLA1 => 10.8 ~ preserve(parameter, u"m^2/kg") # Amichev
    
    "Age at which specific leaf area = (SLA0 + SLA1)/2"
    tSLA => 1 ~ preserve(parameter) # Amichev
    
    "Maximum litterfall rate"
    gammaF1 => 0 ~ preserve(parameter) # Amichev

    "Literfall rate at t = 0"
    gammaF0 => 0 ~ preserve(parameter) # Amichev

    "Age at which litterfall rate has median value"
    tgammaF => 0 ~ preserve(parameter) # Amichev

    "Leaf width"
    leaf_width => begin
        10 # for poplar?
    end ~ preserve(u"cm", parameter)

    "LAI for maximum rainfall interception"
    LAI_interception_max => 0 ~ preserve(parameter) # Sands

    # growth_foliage(NPP, partition_foliage) => NPP * partition_foliage ~ track(u"kg/ha/hr") # foliage

    # deathFoliage(WF, mF, mortality, trees) => begin
    #     mF * mortality * (WF / trees)
    # end ~ track(u"kg/ha/hr", when=flagMortal)

    "Monthly litterfall rate"
    gammaFmonth(gammaF1, gammaF0, stand_age, tgammaF) => begin
        if tgammaF * gammaF1 == 0
            gammaF1
        else
            kgammaF = 12 * log(1 + gammaF1 / gammaF0) / tgammaF
            gammaF1 * gammaF0 / (gammaF0 + (gammaF1 - gammaF0) * exp(-kgammaF * stand_age))
        end
    end ~ track
    
    "Hourly litterfall rate"
    gammaFhour(date, gammaFmonth) => begin
        (1 - (1 - gammaFmonth)^(1 / daysinmonth(date) / 24)) / u"hr"
    end ~ track(u"hr^-1")

    "Hourly litterfall"
    litterfall(gammaFhour, WF) => gammaFhour * WF ~ track(u"kg/ha/hr")

    "Hourly change in foliage drymass"
    dWF(growth_foliage, litterfall, #=deathFoliage,=# defoliation, thinning_WF, senescence_delta, bud_delta, senescence_leaf) => begin
        growth_foliage - litterfall #=- deathFoliage=# - defoliation - thinning_WF - senescence_delta + bud_delta - senescence_leaf
    end ~ track(u"kg/ha/hr")

    "Foliage drymass"
    WF(dWF) ~ accumulate(u"kg/ha", init=iWF, min=0) # foliage drymass

    "Foliage drymass in metric ton"
    WF_ton(nounit(WF)) => WF / 1000 ~ track # conversion to metric

    "Specific leaf area based on stand age (years)"
    SLA(stand_age, SLA0, SLA1, tSLA) => begin
        SLA1 + (SLA0 - SLA1) * exp(-log(2) * (stand_age / tSLA) ^ 2)
    end ~ track(u"m^2/kg")

    "Leaf Area Index"
    LAI(WF, SLA) => WF * SLA ~ track
    # LAI => 1 ~ preserve(parameter)
end