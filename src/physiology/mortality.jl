"""
Mortality
"""
@system Mortality begin

    #=================
    Natural Senescence
    =================#

    "Maximum rate of natural leaf senescence per physiological day"
    LFSEN => 1 - (1 - 0.01)^(1/24) ~ preserve(u"hr^-1", parameter)

    "Fraction of existing root length that can be senesced per HOUR"
    RTSEN => 1 - (1 - 0.008)^(1/24) ~ preserve(u"hr^-1", parameter)

    "Proportion of cumulative storage weight lost per day"
    SRSEN => 1 - (1 - 0.009)^(1/24) ~ preserve(u"hr^-1", parameter)

    "Thermal factor (?)"
    DTX(nounit(T_air)) => curve("lin", 3, 25, 33, 45, T_air) ~ track

    "Hourly leaf senescence"
    senescence_leaf(WF, LFSEN, DTX) => WF * LFSEN * DTX ~ track(u"g/m^2/hr")

    "Maximum hourly stem senescence"
    SSMDOT_max(WS) => 0.1 * WS / u"hr" ~ track(u"g/m^2/hr")

    "ratio of petiole to leaf weight"
    PORPT => 0.27 ~ preserve(parameter)

    "Hourly stem senescence"
    senescence_stem(senescence_leaf, PORPT) => senescence_leaf * PORPT ~ track(u"g/m^2/hr", max=SSMDOT_max)

    "Root length denstiy senesced (cm/cm^3)"
    RLSEN(RLV, RTSEN, DTX) => RLV * RTSEN * DTX ~ track(u"cm/cm^3/hr")

    "Hourly root senescence"
    senescence_root(RLSEN, RFAC, soil_depth) => RLSEN * soil_depth / RFAC ~ track(u"g/m^2/hr")

    "Hourly storage senescence"
    senescence_storage(WSR, SRSEN, DTX) => WSR * SRSEN * DTX ~ track(u"g/m^2/hr")

    #=========
    Parameters
    ==========#

    "Seedling mortality rate (t=0)"
    gammaN0 => 0 ~ preserve(u"percent", parameter)

    "Mortality rate for large t"
    gammaN1 => 0 ~ preserve(u"percent", parameter)
    
    "Age at which mortality rate has median value"
    tgammaN => 0 ~ preserve(parameter)
    
    "Shape of mortality response"
    ngammaN => 1 ~ preserve(parameter) # Amichev
    
    "Max. stem mass per tree at 1000 trees/hectare"
    wSx1000 => 200 ~ preserve(parameter, u"kg") # Amichev
    
    "Power in self-thinning rule"
    thinning_power => 1.5 ~ preserve(parameter) # Amichev
    
    "Fraction mean single-tree foliage biomass lost per dead tree"
    mF => 0 ~ preserve(parameter) # Amichev
    
    "Fraction mean single-tree root biomass lost per dead tree"
    mR => 0.2 ~ preserve(parameter) # Amichev
    
    "Fraction mean single-tree stem biomass lost per dead tree"
    mS => 0.2 ~ preserve(parameter) # Amichev


    #=====================
    Age & Stress Mortality
    =====================#

    # "Mortality rate (yearly)"
    # gammaNyear(stand_age, gammaN0, gammaN1, tgammaN, ngammaN) => begin
    #     gammaN1 + (gammaN0 - gammaN1) * exp(-log(2) * (stand_age / tgammaN) ^ ngammaN)
    # end ~ track
    
    # "Mortality rate (daily)"
    # gammaNhour(date, gammaNyear) => begin
    #     (1 - (1 - gammaNyear)^(1 / daysinyear(date) / 24)) / u"hr"
    # end ~ track(u"hr^-1")
    
    # "Mortality flag"
    # flagMortal(gammaNhour) => gammaNhour > 0u"hr^-1" ~ flag

    # "Age & stress-related mortality rate (hourly)"
    # asMortality(gammaNhour, trees) => gammaNhour * trees ~ track(u"ha^-1/hr", when=flagMortal)


    #============
    Self-thinning
    ============#

    wSmax(trees, thinning_power, wSx1000) => wSx1000 * (1000u"ha^-1" / trees) ^ thinning_power ~ track(u"kg")

    flag_self_thin(wSmax, avStemMass) => wSmax < avStemMass ~ flag

    # Accuracy of Newton-Raphson method used in self-thinning calculation.
    accuracy => 1/1000 ~ preserve

    # Canopy "self-thins" to account for competition between stands.
    # Follows the "self-thinning" rule.
    "Self-thinning rate"
    self_thinning(accuracy, mS, trees, WS, wSx1000, thinning_power) => begin
        n = trees / 1000u"ha^-1"
        x1 = mS * WS / trees
        i = 0
        while true
            x2 = wSx1000 * n ^ (1 - thinning_power)
            fN = (x2) - (x1 * n) - ((1 - mS) * WS / 1000u"ha^-1")
            dfN = ((1 - thinning_power) * x2 / n) - (x1)
            dN = -fN / dfN
            n = n + dN
            i = i + 1
            if abs(dN) <= accuracy || i >= 5
                break
            end
        end
        (trees - 1000u"ha^-1" * n) / u"hr"
    end ~ track(u"ha^-1/hr", when=flag_self_thin)

    #========
    Mortality
    ========#
    
    # "Tree mortality rate"
    # mortality(#=asMortality, =#self_thinning) => #=asMortality + =#self_thinning ~ track(u"ha^-1/hr", when=flagMortal)
end