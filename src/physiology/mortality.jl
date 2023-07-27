"""
Mortality
"""
@system Mortality begin

    #=================
    Natural Senescence
    =================#

    "Fraction of existing leaf senesced per HOUR"
    LFSEN => 1 - (1 - 0.01)^(1/24) ~ preserve(u"hr^-1", parameter)

    "Fraction of existing root length senesced per HOUR"
    RTSEN => 1 - (1 - 0.008)^(1/24) ~ preserve(u"hr^-1", parameter)

    "Fraction of existing storage senesced per HOUR"
    SRSEN => 1 - (1 - 0.009)^(1/24) ~ preserve(u"hr^-1", parameter)

    "Ratio of petiole to leaf weight"
    petiole_to_leaf => 0.27 ~ preserve(parameter)

    "Thermal factor (between 0 and 1)"
    DTX(nounit(T_air)) => curve("lin", 3, 25, 33, 45, T_air) ~ track

    "Root length denstiy senesced (cm/cm^3)"
    RLSEN(RLV, RTSEN, DTX) => RLV * RTSEN * DTX ~ track(u"cm/cm^3/hr")

    "Hourly leaf senescence"
    senescence_leaf(WF, LFSEN, DTX) => WF * LFSEN * DTX ~ track(u"g/m^2/hr")

    "Maximum hourly stem senescence"
    senescence_stem_max(WS) => 0.1 * WS / u"hr" ~ track(u"g/m^2/hr")

    "Hourly stem senescence. Appears to be related to leaf senescence rate.
    Not sure if this behavior is applicable to a woody species like poplar"
    senescence_stem(senescence_leaf, petiole_to_leaf) => senescence_leaf * petiole_to_leaf ~ track(u"g/m^2/hr", max=senescence_stem_max)

    "Hourly root senescence"
    senescence_root(RLSEN, RFAC, soil_depth) => RLSEN * soil_depth / RFAC ~ track(u"g/m^2/hr")

    "Hourly storage senescence"
    senescence_storage(WSR, SRSEN, DTX) => WSR * SRSEN * DTX ~ track(u"g/m^2/hr")

    "Leaf N loss per HOUR"
    NLOFF(senescence_leaf, SENNLV, PCNL, PROLFF, LFSENWT) => begin
        senescence_leaf *
        (SENNLV * (PCNL - PROLFF * 0.16) + PROLFF * 0.16) +
        (LFSENWT) * PROLFF * 0.16
        # (SLNDOT + WLIDOT + WLFDOT) * PCNL
        # water stress + pest + freezing
    end ~ track(u"g/m^2/hr")

    "Proportion used to calculate..."
    SENCLV => 1 ~ preserve(parameter)

    "CH2O loss from leaves per HOUR"
    CLOFF(senescence_leaf, LFSENWT, SENCLV, RHOL, PCHOLFF) => begin
        (senescence_leaf + LFSENWT) *
        (SENCLV * (RHOL - PCHOLFF) + PCHOLFF)
        #(SLNDOT + WLIDOT + WLFDOT) * RHOL
    end ~ track(u"g/m^2/hr")

    NSOFF(senescence_stem, SENNSV, PCNST, PROSTF, STSENWT) => begin
        senescence_stem *
        (SENNSV * (PCNST - PROSTF * 0.16) + PROSTF * 0.16) +
        (STSENWT) * PROSTF * 0.16
    end ~ track(u"g/m^2/hr")

    SENCSV => 1 ~ preserve(parameter)

    CSOFF(senescence_stem, STSENWT, SENCSV, RHOS, PCHOSTF) => begin
        (senescence_stem + STSENWT) *
        (SENCSV * (RHOS - PCHOSTF) + PCHOSTF)
     end ~ track(u"g/m^2/hr")

    NROFF(senescence_root, SENNRV, PCNRT, PRORTF) => begin
        senescence_root *
        (SENNRV * (PCNRT - PRORTF * 0.16) + PRORTF * 0.16)
    end ~ track(u"g/m^2/hr")

    SENCRV => 1 ~ preserve(parameter)

    CROFF(senescence_root, SENCRV, RHOR, PCHORTF) => begin
        senescence_root *
        (SENCRV * (RHOR - PCHORTF) + PCHORTF)
    end ~ track(u"g/m^2/hr")

    NSROFF(senescence_storage, SENNSRV, PCNSR, PROSRF) => begin
        senescence_storage *
        (SENNSRV * (PCNSR - PROSRF * 0.16) + PROSRF * 0.16)
    end ~ track(u"g/m^2/hr")

    SENCSRV => 1 ~ preserve(parameter)

    CSROFF(senescence_storage, SENCSRV, RHOSR, PCHOSRF) => begin
        senescence_storage *
        (SENCSRV * (RHOSR - PCHOSRF) + PCHOSRF)
    end ~ track(u"g/m^2/hr")

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