include("radiation.jl")

"""
Foliage 
"""
@system Foliage(Radiation) begin
    #=========
    Parameters
    ==========#
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

    "Foliage nitrogen ratio"
    N_ratio_foliage => 0.03 ~ preserve(parameter)

    #=====
    Growth
    =====#

    growthFoliage(NPP, pF) => NPP * pF ~ track(u"kg/ha/hr") # foliage

    #========
    Mortality
    ========#

    deathFoliage(WF, mF, mortality, stemNo) => begin
        mF * mortality * (WF / stemNo)
    end ~ track(u"kg/ha/hr", when=flagMortal)

    # Monthly litterfall rate
    gammaFmonth(gammaF1, gammaF0, standAge, tgammaF) => begin
        if tgammaF * gammaF1 == 0
            gammaF1
        else
            kgammaF = 12 * log(1 + gammaF1 / gammaF0) / tgammaF
            gammaF1 * gammaF0 / (gammaF0 + (gammaF1 - gammaF0) * exp(-kgammaF * standAge))
        end
    end ~ track
    
    # Hourly litterfall rate
    gammaFhour(date, gammaFmonth) => begin
        (1 - (1 - gammaFmonth)^(1 / daysinmonth(date) / 24)) / u"hr"
    end ~ track(u"hr^-1")

    litterfall(gammaFhour, WF) => gammaFhour * WF ~ track(u"kg/ha/hr")

    #=====
    Weight
    =====#

    dWF(growthFoliage, N_stress, litterfall, deathFoliage, defoliation, thinning_WF, dSen, dBud) => begin
        growthFoliage * N_stress - litterfall - deathFoliage - defoliation - thinning_WF - dSen + dBud
    end ~ track(u"kg/ha/hr")

    WF(dWF) ~ accumulate(u"kg/ha", init=iWF, min=0) # foliage drymass

    WF_ton(nounit(WF)) => WF / 1000 ~ track # conversion to metric

    # Specific leaf area based on stand age (years)
    SLA(standAge, SLA0, SLA1, tSLA) => begin
        SLA1 + (SLA0 - SLA1) * exp(-log(2) * (standAge / tSLA) ^ 2)
    end ~ track(u"m^2/kg")

    # Leaf Area Index
    LAI(WF, SLA) => WF * SLA ~ track

    # Leaf respiration
    Q10_leaf_below30C: leaf_temperature_sensitivity_conefficient_below30C => 2.0 ~ preserve(parameter) #dimensionless
    Q10_leaf_above30C: leaf_temperature_sensitivity_conefficient_above30C => 2.03 ~ preserve(parameter) #dimensionless
    k_leaf_20: leaf_maintenance_rate_at_20C => 300.3 * 1000 ~ preserve(parameter, u"ng/kg/s"#=gCHO 20to30oC=#)
    k_leaf_30(q=Q10_leaf_below30C, k_leaf_20): leaf_maintenance_rate_at_30C => begin
        k_leaf_20 * q^((30-20)/10)
    end~track(u"ng/kg/s"#=gCHO 30to40oC=#)

    Leaf_Rp(k_leaf_20, k_leaf_30, WF, a = Q10_leaf_below30C, b=Q10_leaf_above30C, nounit(T_air)): leaf_maintenance_respiration => begin
        if T_air < 30
            k_leaf_20 * WF * a^((T_air-20) / 10)
        else
            k_leaf_30 * WF * b^((T_air-30) / 10)
        end
    end ~ track(u"g/ha/hr"#=g CHO=#)

end