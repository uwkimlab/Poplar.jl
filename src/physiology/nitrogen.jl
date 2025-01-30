@system Nitrogen begin

    #=======
    "Stress"
    =======#

    N_stress(N_demand, N_uptake) => begin
        if N_demand == 0u"g/m^2/hr"
            0
        else
            N_uptake / N_demand
        end
    end ~ track(max=1)

    #=====
    Demand
    ======#

    N_demand_foliage(growthFoliage, N_ratio_foliage) => begin
        growthFoliage * N_ratio_foliage 
    end ~ track(u"g/m^2/hr")

    N_demand_stem(growthStem, N_ratio_stem) => begin
        growthStem * N_ratio_stem
    end ~ track(u"g/m^2/hr")

    N_demand_root(growthRoot, N_ratio_root) => begin
        growthRoot * N_ratio_root
    end ~ track(u"g/m^2/hr")

    N_demand(N_demand_foliage, N_demand_stem, N_demand_root) => begin
        N_demand_foliage + N_demand_stem + N_demand_root
    end ~ track(u"g/m^2/hr")

    #=====
    Uptake
    =====#

    "Nitrate uptake per unit root length (mg[N]/cm[root])"
    NO3_per_root_length => 0.075 ~ preserve(parameter, u"mg/cm")

    "Ammonium uptake per unit root length (mg[N]/cm[root])"
    NH4_per_root_length => 0.075 ~ preserve(parameter, u"mg/cm")

    "Bulk density"
    bulk_density => 1.4 ~ preserve(u"g/cm^3")

    "Soil depth"
    soil_depth => 50 ~ preserve(parameter, u"cm")

    "Conversion factor from kg[N]/ha to g[N]/µg[soil] for soil layer"
    N_conversion_factor(bulk_density, soil_depth) => begin
        1 / (bulk_density * soil_depth)
    end ~ preserve(u"cm^2/g")

    "Total extractable nitrate N in soil layer"
    NO3_extractable(NO3, N_conversion_factor) => NO3 / N_conversion_factor ~ track(u"kg/ha")

    "Total extractable ammonium N in soil layer"
    NH4_extractable(NH4, N_conversion_factor) => NH4 / N_conversion_factor ~ track(u"kg/ha")

    "Potential NH4 availability factor"
    NH4_factor(nounit(NH4)) => begin
        f = 1 - exp(-0.08 * NH4) # Potential NH4 availability factor from CROPGRO.
        # f < 0.04 ? 0 : f       # Not sure why 0.04 and below is 0.
        f
    end ~ track(max=1)

    "Potential NO3 availability factor"
    NO3_factor(nounit(NO3)) => begin
        f = 1 - exp(-0.08 * NO3) # Potential NO3 availability factor from CROPGRO.
        # f < 0.04 ? 0 : f         # Not sure why 0.04 and below is 0. Also not sure what -0.08 represents
        f
    end ~ track(max=1)

    # Relative drought factor from CROPGRO. Used for N_uptake_conversion_factor.
    "Relative drought factor"
    drought_factor(SW, minSW, field_capacity, soil_saturation, WP) => begin
        if SW > field_capacity
            1.0 - (SW - field_capacity) / (soil_saturation - field_capacity)
        else
            1 * ((SW - WP) / (field_capacity - WP))
        end
    end ~ track(min=0.1, max=1) 

    # Nitrogen uptake conversion factor.
    # How much kg/ha of nitrogen for mg/cm of nitrogen (root)?
    N_uptake_conversion_factor(RLD, drought_factor, soil_depth) => begin
        RLD * sqrt(drought_factor) * soil_depth 
    end ~ track(u"kg*cm/mg/ha")

    "Amount of NO3 that stays in soil"
    NO3_min(N_conversion_factor) => 0u"μg/g" / N_conversion_factor ~ preserve(u"kg/ha")

    "Maximum NO3 uptake from soil"
    NO3_uptake_max(NO3_extractable, NO3_min) => NO3_extractable - NO3_min ~ preserve(min=0, u"kg/ha")

    "Amount of NH4 that stays in soil"
    NH4_min(N_conversion_factor) => 0u"μg/g" / N_conversion_factor ~ preserve(u"kg/ha")

    "Maximum NH4 uptake from soil"
    NH4_uptake_max(NH4_extractable, NH4_min) => NH4_extractable - NH4_min ~ preserve(min=0, u"kg/ha")

    "Potential nitrate (NO3) uptake from soil"
    NO3_uptake_potential(N_uptake_conversion_factor, NO3_factor, NO3_per_root_length) => begin
        N_uptake_conversion_factor * NO3_factor * NO3_per_root_length
    end ~ track(min=0, max=NO3_uptake_max, u"kg/ha")

    "Potential ammonium (NH4) uptake from soil"
    NH4_uptake_potential(N_uptake_conversion_factor, NH4_factor, NH4_per_root_length) => begin
        N_uptake_conversion_factor * NH4_factor * NH4_per_root_length
    end ~ track(min=0, max=NH4_uptake_max, u"kg/ha")

    "Fraction of demand to maximum uptake given CH2O avaiability"
    N_demand_fraction(N_demand, NO3_uptake_potential, NH4_uptake_potential) => begin
        if (NO3_uptake_potential + NH4_uptake_potential) <= 0u"g/m^2"
            0
        else
            N_demand * u"hr" / (NO3_uptake_potential + NH4_uptake_potential)
        end
    end ~ track

    "..."
    N_uptake_fraction(#=N_respiration_fraction, =#N_demand_fraction) => begin
        min(#=N_respiration_fraction, =#N_demand_fraction)
    end ~ track(max=1)

    "Total nitrate (NO3) uptake"
    NO3_uptake(NO3_uptake_potential, N_uptake_fraction) => begin
        NO3_uptake_potential * N_uptake_fraction
    end ~ track(max=NO3_uptake_max, u"g/m^2")

    "Total ammonium (NH4) uptake"
    NH4_uptake(NH4_uptake_potential, N_uptake_fraction) => begin
        NH4_uptake_potential * N_uptake_fraction
    end ~ track(max=NH4_uptake_max, u"g/m^2")

    "Total nitrogen uptake"
    N_uptake(NO3_uptake, NH4_uptake) => begin
        (NO3_uptake + NH4_uptake) / u"hr"
    end ~ track(u"g/m^2/hr")

    N_uptake_tot(N_uptake) ~ accumulate(u"g/m^2")

    #===========
    Mobilization
    ===========#

    # #========================
    # N from natural senescence
    # ========================#

    # "Proportion of actual N mobilized from leaves lost to natural, low-light, and
    # N-mobilization senescence. Value of 1 equates to all of the N mobilized."
    # SENNLV => 1 ~ preserve

    # SENNSV => 1 ~ preserve

    # SENNRV => 1 ~ preserve

    # SENNSRV => 1 ~ preserve

    # # LTSEN(DTX, XLAI, LCMP, TCMP) => begin
    # #     DTX * (XLAI - LCMP) / TCMP
    # # end

    # "Nitrogen mobilized from natural leaf senescence"
    # LFSNMOB(senescence_leaf, PCNL, SENNLV, protein_leaf_min#=, LTSEN=#) => begin
    #     senescence_leaf * (PCNL/100 - (SENNLV * (PCNL / 100 - protein_leaf_min * 0.16) + protein_leaf_min * 0.16))
    #     # LTSEN * (PCNL / 100 - protein_leaf_min * 0.16)
    #     # LTSEN refers to further senescence specific to leaves exposed to low-light
    #     # I was considering using the LAI_shaded variable to calculate this value.
    #     # Currently not implemented.
    # end ~ track(u"g/m^2/hr", min=0)

    # "Nitrogen mobilized from natural stem senescence"
    # STSNMOB(senescence_stem, PCNST, SENNSV, PCNST, protein_stem_min#=, STLFSEN=#) => begin
    #     senescence_stem * (PCNST / 100 - (SENNSV * (PCNST / 100 - protein_stem_min * 0.16) + protein_stem_min * 0.16))
    #     # STLTSEN * (PCNST / 100 - protein_stem_min * 0.16)
    # end ~ track(u"g/m^2/hr", min=0)
    
    # "Nitrogen mobilized from natural root senescence"
    # RTSNMOB(senescence_root, PCNRT, SENNRV, protein_root_min) => begin
    #     senescence_root * (PCNRT / 100 - (SENNRV * (PCNRT / 100 - protein_root_min*0.16) + protein_root_min*0.16))
    # end ~ track(u"g/m^2/hr", min=0)

    # "Nitrogen mobillized from natural storage senescence"
    # SRSNMOB(senescence_storage, PCNSR, SENNSRV, PCNSR, PROSRF) => begin
    #     senescence_storage * (PCNSR / 100 - (SENNSRV * (PCNSR / 100 - PROSRF * 0.16) + PROSRF * 0.16))
    # end ~ track(u"g/m^2/hr", min=0)

    # #======================
    # N mined from old tissue
    # ======================#

    # "Minimum relative rate of reproductive development under long days and optimal temperature"
    # THVAR => 1 ~ preserve(parameter) 

    # "Sensitivity to photoperiod; Slope of the relative rate of development for day lengths above CSDVAR (1/hr)"
    # PPSEN => 0.2 ~ preserve(parameter)

    # "Critical daylength above which development rate decreases (prior to flowering)"
    # CSDVAR => 0 ~ preserve(parameter)

    # "Critical daylength above which development rate remains at min value (prior to flowering) (hours)"
    # CLDVAR(PPSEN, CSDVAR, THVAR) => begin
    #     if PPSEN >= 0
    #         CSDVAR + (1 - THVAR) / max(PPSEN, 0.000001)
    #     elseif PPSEN < 0
    #         CSDVAR + (1 - THVAR) / min(PPSEN, -0.000001)
    #     end
    # end ~ track

    # "Photoperiod factor? (The value seems to be 1 anyways, given the parameters provided in DSSAT)"
    # DRPP(CSDVAR, CLDVAR, THVAR, nounit(day_length)) => curve("inl", 1, CSDVAR, CLDVAR, THVAR, day_length) ~ track

    # "Thermal factor (between 0 and 1)"
    # TNTFAC(nounit(T_air)) => curve("lin", 3, 25, 33, 45, T_air) ~ track

    # "Photo-thermal factor"
    # TDUMX(TNTFAC, DRPP) => TNTFAC * DRPP ~ track

    # "Relative rate of N mining during vegetative stage to that in reproductive stage"
    # NVSMOB => 1 ~ preserve(parameter)

    # "Maximum fraction of N which can be mobilized in an HOUR"
    # NMOBMX => 1 - (1 - 0.08) ^ (1/24) ~ preserve(u"hr^-1", parameter)

    # "Maximum fraction of C which can be mobilzed in an HOUR"
    # CMOBMX => 1 - (1 - 0.055) ^ (1/24) ~ preserve(u"hr^-1", parameter)

    # "Nitrogen mining rate"
    # NMOBR(NVSMOB, NMOBMX, TDUMX) => begin
    #     NVSMOB * NMOBMX * TDUMX
    # end ~ track(u"hr^-1")

    # "Potential mobile N available from leaf (g[N]/m^2)"
    # NMINELF(NMOBR, WNRLF) => NMOBR * WNRLF ~ track(u"g/m^2/hr")

    # "Potential mobile N available from stem (g[N]/m^2)"
    # NMINEST(NMOBR, WNRST) =>  NMOBR * WNRST ~ track(u"g/m^2/hr")

    # "Reduction in mobilization from storage organ due to photoperiod induced dormancy (?)"
    # PPMFAC => 1 ~ preserve(parameter)

    # "Potential mobile N available from root (g[N]/m^2)"
    # NMINERT(NMOBR, PPMFAC, WNRRT) => NMOBR * PPMFAC * WNRRT ~ track(u"g/m^2/hr")

    # "Potential mobile N available from storage (g[N]/m^2)"
    # NMINESR(NMOBR, WNRSR) => NMOBR * WNRSR ~ track(u"g/m^2/hr")

    # #================
    # Total N mobilized
    # ================#

    # "Maximum potential N mobilization from leaf (g[N]/m^2)"
    # LFNMINE(LFSNMOB, NMINELF) => LFSNMOB + NMINELF ~ track(u"g/m^2/hr")

    # "Maximum potential N mobilization from stem (g[N]/m^2)"
    # STNMINE(STSNMOB, NMINEST) => STSNMOB + NMINEST ~ track(u"g/m^2/hr")

    # "Maximum potential N mobilization from root"
    # RTNMINE(RTSNMOB, NMINERT) => RTSNMOB + NMINERT ~ track(u"g/m^2/hr")

    # "Maximum potential N mobilization from storage"
    # SRNMINE(SRSNMOB, NMINESR) => SRSNMOB + NMINESR ~ track(u"g/m^2/hr")

    # # "Potential whole-plant N mobilization from storage (g[N]/m^2/d)"
    # # NMINEP(LFNMINE, STNMINE, RTNMINE, SRNMINE) => begin
    # #     LFNMINE + STNMINE + RTNMINE + SRNMINE
    # # end ~ track(u"g/m^2/hr")

    # # "DSSAT4 potential N mobilization from storage (g[N)/m^2/d)"
    # # NMINEO(NMINELF, NMINEST, NMINERT, NMINESR) => begin
    # #     NMINELF + NMINEST + NMINERT + NMINESR
    # # end ~ track(u"g/m^2/hr")

    # "Total plant N mobilized from tissues lost to natural and low-light senescence"
    # N_mobilized(LFNMINE, STNMINE, SRNMINE, RTNMINE) => begin
    #     LFNMINE + STNMINE + SRNMINE + RTNMINE
    # end ~ track(u"g/m^2/hr")

    # #==========================
    # Potential CH2O mobilization
    # ==========================#

    # "Potential mobile CH2O available from leaf"
    # CMINELF(CMOBMX, DTX, C_net_leaf, WF, PCHOLFF) => begin
    #     CMOBMX * DTX * (C_net_leaf - WF * PCHOLFF)
    # end ~ track(u"g/m^2/hr")

    # "Potential mobile CH2O available from stem"
    # CMINEST(CMOBMX, DTX, C_net_stem, WS, PCHOSTF) => begin
    #     CMOBMX * DTX * (C_net_stem - WS * PCHOSTF)
    # end ~ track(u"g/m^2/hr")

    # "Potential mobile CH2O available from root"
    # CMINERT(CMOBMX, DTX, C_net_root, WR, PCHORTF, PPMFAC) => begin
    #     CMOBMX * DTX * PPMFAC * (C_net_root - WR * PCHORTF)
    # end ~ track(u"g/m^2/hr")

    # # FIX NEED TO USE CMOBSR FOR CALCULATION INSTEAD OF CMOBMX
    # "Potential mobile CH2O available from storage"
    # CMINESR(CMOBMX, DTX, WCRSR, WSR, PCHOSRF) => begin
    #     CMOBMX * DTX * (WCRSR - WSR * PCHOSRF)
    # end ~ track(u"g/m^2/hr")

    # C_mobilized(CMINELF, CMINEST, CMINERT, CMINESR) => begin
    #     CMINELF + CMINEST + CMINERT + CMINESR
    # end ~ track(u"g/m^2/hr")


    # # "Leaf senescence due to mobilization (?).
    # # It appears that leaf senescence occurs as a result of N mobilization as well.
    # # I assume that there is no N mobilization occuring due to this senescence."

    # "Factor by which protein mined from leaves each day is multiplied to determine LEAF senescence. (g(leaf) / g(protein loss))"
    # SENRTE => 0.8 ~ preserve(parameter)

    # LFSENWT(SENRTE, NMINELF) => SENRTE * NMINELF / 0.16 ~ track(u"g/m^2/hr")
    
    # STSENWT(LFSENWT, petiole_to_leaf) => LFSENWT * petiole_to_leaf ~ track(u"g/m^2/hr")
end