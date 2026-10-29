include("gasexchange/gasexchange.jl")

"""
Photosynthesis
"""
@system Photosynthesis begin

    #=================
    Gas-exchange Model
    =================#

#     "Gas exchange model for sunlit leaves"

#     sunlit_gasexchange(context, PPFD=Q_sun, LAI=LAI_sunlit, w=leaf_width, water_stress =water_stress) ~ ::GasExchange

#     "Gas exchange model for shaded leaves"
#     shaded_gasexchange(context, PPFD=Q_sh, LAI=LAI_shaded, w=leaf_width, water_stress =water_stress) ~ ::GasExchange

    "Gas exchange model for sunlit leaves"
    sunlit_gasexchange(context, PPFD=Q_sun, LAI=LAI_sunlit, w=leaf_width, s=s, water_stress=water_stress) ~ ::GasExchange

    "Gas exchange model for shaded leaves"
    shaded_gasexchange(context, PPFD=Q_sh, LAI=LAI_shaded, w=leaf_width, s=s, water_stress=water_stress) ~ ::GasExchange


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

    canopy_efficiency(A_gross,R_sw) => begin
	A_gross/R_sw
    end ~ track(u"μmol/s/W") 


    "Transpiration rate (sunlit + shaded)"
    ET(a=sunlit_gasexchange.E_total, b=shaded_gasexchange.E_total): transpiration_H2O_mol_per_m2_s => begin
        a + b
    end ~ track(u"mmol/m^2/s" #= H2O =#)

    "Net solar radiation absorbed (sunlit + shaded)"
    R_sw(a=sunlit_gasexchange.R_sw_total, b=shaded_gasexchange.R_sw_total): radiation_absorbed_J_per_s => begin
        a + b
    end ~ track(u"W/m^2")

    CO2_weight => 44.0098 ~ preserve(u"g/mol")
    C_weight => 12.0107 ~ preserve(u"g/mol")
    CH2O_weight => 30.031 ~ preserve(u"g/mol")
    H2O_weight => 18.01528 ~ preserve(u"g/mol")
    H2O_density => 997 ~ preserve(u"kg/m^3")
    
    # Calculated by using gross photosynthesis and CH2O weight.
    # Empirical transpiration scale factor from original 3PG model
    # to account for water deficit.
    "Gross primary production"
    GPP(A_gross, w=CH2O_weight#=, transpScaleFactor=#) => begin
        A_gross * w #* transpScaleFactor
    end ~ track(u"kg/ha/hr")

    "C available..."
    C_available(GPP) ~ track(u"kg/ha/hr")

    # From 3PG model, possibly different for poplars.
    # Appears to be the standard value for most species.
    "NPP/GPP ratio"
    γ => 0.47 ~ preserve(parameter) # Amichev

    # growth respiration and carbon contents from Grossman & Dejong (1994) - PEACH
    "Growth respiration coefficient"
    Gr => 0.211 ~ preserve(parameter #=gCHO/gDW=#) # peach fruit
    "Carbon content foliage"
    Cf => 0.453 ~ preserve(parameter #=gC/gDW=#) # peach leaf
    "Carbon content stem"
    Cs => 0.475 ~ preserve(parameter #=gC/gDW=#) # peach trunk
    "Carbon content root"
    Cr => 0.458 ~ preserve(parameter #=gC/gDW=#) # peach root

    "Growth yield"
    Yg(Cf, Cs, Cr, pF, pS, pR, C_weight, CH2O_weight, Gr) => begin
        1 / ((Cf*pF + Cs*pS + Cr*pR) * (CH2O_weight / C_weight) + Gr) 
    end ~ track(when=growthFlag) #=gDW/gCHO=#
    # Yg => 0.75 ~ preserve(parameter)

    # 1--constant NPP:GPP ratio (recommended with constant allocation); 
    # 2--dynamic respiration (recommended with allometric allocation types)
    "Switch parameter to control NPP types"
    NPP_type => 1 ~ preserve(parameter)

    "total maintenance respiration"
	Rp(Root_Rp, Stem_Rp, Leaf_Rp) =>  Root_Rp + Stem_Rp + Leaf_Rp ~ track(u"kg/ha/hr")

	growthFlag(GPP, Rp) => GPP > Rp ~ flag
	
	"Net primary production"
    NPP(GPP, γ, NPP_type, Rp, Yg, growthFlag) => begin
        if NPP_type == 1 # using NPP/GPP ratio
            γ * GPP
        elseif NPP_type == 2 # using growth-maintenance respiration regime
			if growthFlag						# growth (NPP>0)
            	(GPP - Rp) * Yg 
			else								# no growth (NPP<0)
				GPP - Rp
			end
        else
            @error "Invalid NPP_type: $NPP_type. Use 1 or 2 for ratio or respiration, respectively"
        end
    end ~ track(u"kg/ha/hr")

    NPP_ac(NPP) ~ accumulate(u"kg/ha")

    GPP_ac(GPP) ~ accumulate(u"kg/ha")

    # output NPP/GPP ratio for comparison when NPP_type = 2
    γ_out(NPP, GPP) => NPP / GPP ~ track
    γ_out_ac(NPP_ac, GPP_ac) => NPP_ac / GPP_ac ~ track

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
