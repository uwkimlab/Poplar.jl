# N_demand_total is required.
@system NitrogenUptake begin

    # PARAMETERS

    # Nitrate uptake per unit root length
    NO3_per_root_length ~ preserve(parameter)

    # Ammonium uptake per unit root length
    NO4_per_root_length ~ preserve(parameter)

    "CH2O required for protein synthesis when source of N is nitrate uptake"
    RNO3C => 2.556 ~ preserve

    "CH2O required for protein synthesis when sourjce of N is ammonim uptake"
    RNH4C => 2.556 ~ preserve

    bulk_density

    soil_layer_thickness

    # Conversion factor to switch from kg [N] / ha to ug [N] / g [soil] for soil layer L 
    N_conversion_factor => 10 / (bulk_density * soil_layer_thickness) ~ preserve

    "Extractable nitrate in soil"
    NO3_extractable(NO3_soil, FAC) => NO3_soil / FAC ~ track

    "Extractable ammonium in soil"
    NH4_extractable(NH4_soil, FAC) => NH4_soil / FAC ~ track

    # The N_senescence should go into N_demand calculation in the first place?
    "N_demand_crop"
    N_demand_crop(N_demand_total, N_senescence) => begin
        N_demand_total - N_senescence * 10 # Why * 10?
    end(max=N_uptake_total)

    # Potential NH4 availability factor from CROPGRO.
    # Not sure why 0.04 and below is 0.
    "Potential NH4 availability factor"
    NH4_factor(NH4) => begin
        f = 1 - exp(-0.08 * NH4)
        f < 0.04 ? 0 : f
    end ~ track(max=1)

    # Poptential NO3 availability factor from CROPGRO.
    # Not sure why 0.04 and below is 0.
    "Potential NO3 availability factor"
    NO3_factor(NO3) => begin
        f = 1 - exp(-0.08 * NH4)
        f < 0.04 ? 0 : f
    end ~ track(max=1)

    # Relative drought factor from CROPGRO. Used for N_uptake_conversion_factor.
    # Not sure why minimum is 0.1.
    "Relative drought factor"
    drought_factor(ASW, min_ASW, field_capacity) => begin
        if ASW > field_capacity
            2.0 - (ASW - field_capacity) / (max_ASW - field_capacity)
        else
            2*((ASW - min_ASW) / (field_capacity - min_ASW))
        end
    end ~ track(min=0, max=1) 

    # Nitrogen uptake conversion factor.
    # How much kg/ha of nitrogen for mg/cm of nitrogen (root)?
    N_uptake_conversion_factor(RLV, drought_factor, soil_depth) => begin
        RLV * sqrt(drought_factor) * soil_depth
    end ~ track

    "Amount of NO3 that stays in soil"
    NO3_min(N_conversion_factor) => 0.25 / N_conversion_factor ~ preserve

    "Maximum NO3 uptake from soil"
    NO3_uptake_max(NO3_extractable, NO3_min) => NO3_extractable - NO3_min ~ preserve(min=0)

    "Amount of NH4 that stays in soil"
    NH4_min(N_conversion_factor) => 0.5 / N_conversion_factor ~ preserve

    "Maximum NH4 uptake from soil"
    NH4_uptake_max(NH4_extractable, NH4_min) => NH4_extractable - NH4_min ~ preserve(parameter)

    "Potential nitrate (NO3) uptake from soil"
    NO3_uptake_potential(N_uptake_conversion_factor, NO3_factor, RTNO3) => begin
        N_uptake_conversion_factor * NO3_factor * NO3_per_root_length
    end(min=0, max=NO3_uptake_max)

    "Potential ammonium (NH4) uptake from soil"
    NH4_uptake_potential(N_uptake_conversion_factor, NH4_factor, RTNH4) => begin
        N_uptake_conversion_factor * NH4_factor * NH4_per_root_length
    end(min=0, max=NH4_uptake_max)

    "Potential respiration cost of nitrate (NO3) uptake"
    NO3_respiration_cost_potential(NO3_uptake_potential) => begin
        (NO3_uptake_potential / 10) / 0.16 * RNO3C
        # Why divide by 10?
    end

    "Potential respiration cost of ammonium (NH4) uptake"
    NH4_respiration_cost_potential(NH4_uptake_potential) => begin
        (NH4_uptake_potential / 10) / 0.16 * RNH4C
        # Why divide by 10?
    end

    # Demand vs. uptake fraction.
    # Max set to 1 as nitrogen uptake cannot be greater than what is available.
    "Fraction of available CH2O to potential CH2O cost"
    N_respiration_fraction(GPP, NO3_respiration_cost_potential, NH4_respiration_cost_potential) => begin
        GPP / (NO3_respiration_cost_potential + NH4_respiration_cost_potential)
    end ~ track

    # Calculate coefficient for reducing N uptake
    "Fraction of demand to maximum uptake given CH2O avaiability"
    N_demand_fraction(N_respiration_fraction) => begin
        N_demand / (NO3_uptake_potential + NH4_uptake_potential)
    end ~ track

    N_uptake_fraction(N_respiration_fraction, N_demand_fraction) => begin
        min(N_respiration_fraction, N_demand_fraction)
    end ~ track(max=1)

    # Actual NO3 uptake based on N uptake fraction.
    "Final nitrate (NO3) uptake given demand and available CH2O"
    NO3_uptake(NO3_uptake_potential, N_uptake_fraction) => begin
        NO3_uptake_potential * N_uptake_fraction
    end ~ track(max=NO3_up_max)

    # Actual NO3 uptake based on N uptake fraction.
    "Final ammonium (NH4) uptake given demand and available CH2O"
    NH4_uptake(NH4_uptake_potential, N_respiration_fraction, N_demand_fraction) => begin
        NH4_uptake_potential * N_respiration_fraction * N_demand_fraction
    end ~ track(max=NH4_up_max)

    "Total nitrogen uptake"
    N_uptake(NO3_uptake, NH4_uptake) => begin
        NO3_uptake + NH4_uptake
    end
end