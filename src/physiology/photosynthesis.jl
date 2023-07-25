include("gasexchange/gasexchange.jl")

"""
Photosynthesis
"""
@system Photosynthesis begin

    #=================
    Gas-exchange Model
    =================#

    "Gas exchange model for sunlit leaves"
    sunlit_gasexchange(context, PPFD=Q_sun, LAI=LAI_sunlit, w=leaf_width) ~ ::GasExchange

    "Gas exchange model for shaded leaves"
    shaded_gasexchange(context, PPFD=Q_sh, LAI=LAI_shaded, w=leaf_width) ~ ::GasExchange

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
    GPP(A_gross, w=CH2O_weight, transpiration_scale_factor): gross_primary_production => begin
        A_gross * w * transpiration_scale_factor
    end ~ track(u"kg/ha/hr")

    # From 3PG model, possibly different for poplars.
    # Appears to be the standard value for most species.
    "NPP/GPP fraction"
    γ: NPP_GPP_fraction => 0.47 ~ preserve(parameter) # Amichev

    "Total available CH2O for growth & respiration"
    C_available(GPP#=, CMINEP=#) => 4 #= + CMINEP=# ~ track(u"g/m^2/hr")

    # "Net primary production"
    NPP(γ, GPP): net_primary_production => begin
        γ*GPP
    end ~ track(u"kg/ha/hr")

    "Water use efficiency (productivity)"
    WUE(NPP, transpiration): water_use_efficiency => begin
        NPP / transpiration
    end ~ track(u"g/L")

    "Canopy transpiration in mm/hr"
    transpiration(ET, w=H2O_weight, d=H2O_density) => begin
        ET * w / d
    end ~ track(u"mm/hr") # Conversion to mm/hr to match water balance.

    "Canopy conductance"
    conductance(gs_sun=sunlit_gasexchange.gs, LAI_sunlit, gs_sh=shaded_gasexchange.gs, LAI_shaded, LAI) => begin
        #HACK ensure 0 when one of either LAI is 0, i.e., night
        # average stomatal conductance Yang
        c = ((gs_sun * LAI_sunlit) + (gs_sh * LAI_shaded)) / LAI
        #c = max(zero(c), c)
        # iszero(LAI) ? zero(c) : c
    end ~ track(u"mol/m^2/s/bar") # Overall canopy conductance, not used in any calculations.
end