include("gasexchange/gasexchange.jl")

"""
Photosynthesis
"""
@system Photosynthesis begin

    #=================
    Gas-exchange Model
    =================#

#     "Gas exchange model for sunlit leaves"

#     sunlit_gasexchange(context, PPFD=Q_sun, LAI=LAI_sunlit, w=leaf_width, drought_factor =drought_factor) ~ ::GasExchange

#     "Gas exchange model for shaded leaves"
#     shaded_gasexchange(context, PPFD=Q_sh, LAI=LAI_shaded, w=leaf_width, drought_factor =drought_factor) ~ ::GasExchange

    "Gas exchange model for sunlit leaves"
    sunlit_gasexchange(context, PPFD=Q_sun, LAI=LAI_sunlit, w=leaf_width, s=s, drought_factor=drought_factor) ~ ::GasExchange

    "Gas exchange model for shaded leaves"
    shaded_gasexchange(context, PPFD=Q_sh, LAI=LAI_shaded, w=leaf_width, s=s, drought_factor=drought_factor) ~ ::GasExchange


    #=================
    =================#

    "Gross photosynthetic rate (sunlit + shaded)"
    A_gross(a=sunlit_gasexchange.A_gross_total, b=shaded_gasexchange.A_gross_total): gross_CO2_umol_per_m2_s => begin
        a + b
    end ~ track(u"μmol/m^2/s" #= CO2 =#)

    "Net photosynthetic rate (sunlit + shaded)"
    A_net(a=sunlit_gasexchange.A_net_total, b=shaded_gasexchange.A_net_total, w=leaf_width): net_CO2_umol_per_m2_s => begin
        a + b
    end ~ track(u"μmol/m^2/s" #= CO2 =#)

    "Transpiration rate (sunlit + shaded)"
    ET(a=sunlit_gasexchange.E_total, b=shaded_gasexchange.E_total): transpiration_H2O_mol_per_m2_s => begin
        a + b
    end ~ track(u"mmol/m^2/s" #= H2O =#)

    CO2_weight => 44.0098 ~ preserve(u"g/mol")
    C_weight => 12.0107 ~ preserve(u"g/mol")
    CH2O_weight => 30.031 ~ preserve(u"g/mol")
    H2O_weight => 18.01528 ~ preserve(u"g/mol")
    H2O_density => 997 ~ preserve(u"kg/m^3")
    
    # Calculated by using gross photosynthesis and CH2O weight.
    # Empirical transpiration scale factor from original 3PG model
    # to account for water deficit.
    "Gross primary production"
    GPP(A_gross, w=CH2O_weight, transpScaleFactor) => begin
        A_gross * w * transpScaleFactor
    end ~ track(u"kg/ha/hr")

    "C available..."
    C_available(GPP) ~ track(u"kg/ha/hr")

    # From 3PG model, possibly different for poplars.
    # Appears to be the standard value for most species.
    "NPP/GPP ratio"
    γ => 0.47 ~ preserve(parameter) # Amichev

    "Switch parameter to control NPP types"
    NPP_type => 1 ~ preserve(parameter)

    "Net primary production"
    NPP(GPP, γ, NPP_type, Root_Rp, Stem_Rp, Leaf_Rp) => begin
        if NPP_type == 1 # using NPP/GPP ratio
            γ * GPP
        elseif NPP_type == 2 # using maintenance respiration rate
            GPP - Root_Rp - Stem_Rp - Leaf_Rp
        else
            error("Invalid calculation method: $calculation_method. Use 1 or 2 for ratio or respiration, respectively")
        end
    end ~ track(u"kg/ha/hr")
    #NPP(GPP, Root_Rp, Stem_Rp, Leaf_Rp) => begin
    #    GPP - Root_Rp - Stem_Rp - Leaf_Rp
    #end ~ track(u"kg/ha/hr")  
    #NPP(γ, GPP) => begin
    #    γ*GPP
    #end ~ track(u"kg/ha/hr")

    "Water-use efficiency"
    WUE(NPP, transpiration) => begin
        NPP / transpiration
    end ~ track(u"g/L")

    # Conversion to mm/hr to match water balance.
    "Canopy transpiration in mm/hr"
    transpiration(ET, w=H2O_weight, d=H2O_density) => begin
        ET * w / d
    end ~ track(u"mm/hr")

    # Overall canopy conductance, not used in any calculations.
    "Canopy conductance"
    conductance(gs_sun=sunlit_gasexchange.gs, LAI_sunlit, gs_sh=shaded_gasexchange.gs, LAI_shaded, LAI) => begin
        #HACK ensure 0 when one of either LAI is 0, i.e., night
        # average stomatal conductance Yang
        c = ((gs_sun * LAI_sunlit) + (gs_sh * LAI_shaded)) / LAI
        #c = max(zero(c), c)
        # iszero(LAI) ? zero(c) : c
    end ~ track(u"mol/m^2/s/bar")
end
