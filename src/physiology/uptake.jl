# N_demand_total is required.
@system Uptake begin

    "Nitrate uptake per unit root length (mg[N]/cm[root])"
    NO3_per_root_length => 0.075 ~ preserve(parameter, u"mg/cm")

    "Ammonium uptake per unit root length (mg[N]/cm[root])"
    NH4_per_root_length => 0.075 ~ preserve(parameter, u"mg/cm")

    "CH2O required for protein synthesis when source of N is nitrate uptake"
    RNO3C => 2.556 ~ preserve(u"g/g") # Value from CROPGRO DSSAT

    "CH2O required for protein synthesis when source of N is ammonim uptake"
    RNH4C => 2.556 ~ preserve(u"g/g") # Value from CROPGRO DSSAT

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

############################# THIS SHOULD NOT BE HERE
    # The N_senescence should go into N_demand calculation in the first place?
    # "N_demand_crop"
    # N_demand(N_demand_total#=, N_senescence=#) => begin
    #     N_demand_total#= - N_senescence=# * 10 # Why * 10?
    # end(u"")

    #=
    Potential nitrogen uptake based solely on soil nitrogen availability
    =#

    "Potential NH4 availability factor"
    NH4_factor(nounit(NH4)) => begin
        f = 1 - exp(-0.08 * NH4) # Potential NH4 availability factor from CROPGRO.
        f < 0.04 ? 0 : f         # Not sure why 0.04 and below is 0.
    end ~ track(max=1)

    "Potential NO3 availability factor"
    NO3_factor(nounit(NO3)) => begin
        f = 1 - exp(-0.08 * NO3) # Poptential NO3 availability factor from CROPGRO.
        f < 0.04 ? 0 : f         # Not sure why 0.04 and below is 0.
    end ~ track(max=1)

    # Relative drought factor from CROPGRO. Used for N_uptake_conversion_factor.
    "Relative drought factor"
    drought_factor(ASW, ASW_min, field_capacity, ASW_max) => begin
        if ASW > field_capacity
            2.0 - (ASW - field_capacity) / (ASW_max - field_capacity)
        else
            2*((ASW - ASW_min) / (field_capacity - ASW_min))
        end
    end ~ track(min=0, max=1) 

    # Nitrogen uptake conversion factor.
    # How much kg/ha of nitrogen for mg/cm of nitrogen (root)?
    N_uptake_conversion_factor(RLV, drought_factor, soil_depth) => begin
        RLV * sqrt(drought_factor) * soil_depth 
    end ~ track(u"kg*cm/mg/ha")

    "Amount of NO3 that stays in soil"
    NO3_min(N_conversion_factor) => 0.25u"μg/g" / N_conversion_factor ~ preserve(u"kg/ha")

    "Maximum NO3 uptake from soil"
    NO3_uptake_max(NO3_extractable, NO3_min) => NO3_extractable - NO3_min ~ preserve(min=0, u"kg/ha")

    "Amount of NH4 that stays in soil"
    NH4_min(N_conversion_factor) => 0.5u"μg/g" / N_conversion_factor ~ preserve(u"kg/ha")

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

    #=
    Respiration cost for potential uptake
    =#

    "Potential respiration cost of nitrate (NO3) uptake"
    NO3_respiration_cost_potential(NO3_uptake_potential, RNO3C) => begin
        (NO3_uptake_potential) / 0.16 * RNO3C
    end ~ track(u"g/m^2")

    "Potential respiration cost of ammonium (NH4) uptake"
    NH4_respiration_cost_potential(NH4_uptake_potential, RNH4C) => begin
        (NH4_uptake_potential) / 0.16 * RNH4C
    end ~ track(u"g/m^2")

    #=
    Actual nitrogen uptake based on limiting factors
    =#

    "Fraction of available CH2O to potential CH2O cost"
    N_respiration_fraction(C_available, NO3_respiration_cost_potential, NH4_respiration_cost_potential) => begin
        if (NO3_respiration_cost_potential + NH4_respiration_cost_potential) <= 0u"g/m^2"
            0
        else
            C_available * u"hr" / (NO3_respiration_cost_potential + NH4_respiration_cost_potential)
        end
    end ~ track # nounit

    "Fraction of demand to maximum uptake given CH2O avaiability"
    N_demand_fraction(N_demand, NO3_uptake_potential, NH4_uptake_potential) => begin
        if (NO3_uptake_potential + NH4_uptake_potential) <= 0u"g/m^2"
            0
        else
            N_demand * u"hr" / (NO3_uptake_potential + NH4_uptake_potential)
        end
    end ~ track

    ""
    N_uptake_fraction(N_respiration_fraction, N_demand_fraction) => begin
        min(N_respiration_fraction, N_demand_fraction)
    end ~ track(max=1)

    "Total nitrate (NO3) uptake"
    NO3_uptake(NO3_uptake_potential, N_uptake_fraction) => begin
        NO3_uptake_potential * N_uptake_fraction
    end ~ track(max=NO3_uptake_max, u"g/m^2") # nounit

    "Total ammonium (NH4) uptake"
    NH4_uptake(NH4_uptake_potential, N_uptake_fraction) => begin
        NH4_uptake_potential * N_uptake_fraction
    end ~ track(max=NH4_uptake_max, u"g/m^2")

    "Total nitrogen uptake"
    N_uptake(NO3_uptake, NH4_uptake) => begin
        (NO3_uptake + NH4_uptake) / u"hr"
    end ~ track(u"g/m^2/hr")

    N_uptake_tot(N_uptake) ~ accumulate(u"g/m^2")
end