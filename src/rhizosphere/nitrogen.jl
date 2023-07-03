@system Nitrogen begin
    
    NH4_factor(NH4) => begin
        f = 1 - exp(-0.08 * NH4)
        if f < 0.04
            0
        else
            f
        end
    end ~ track(max=1) # Not sure why 0.04 and below is 0.


    NO3_factor(NO3) => begin
        f = 1 - exp(-0.08 * NH4)
        if f < 0.04
            0
        else
            f
        end
    end ~ track(max=1) # Not sure why 0.04 and below is 0.


    drought_factor(ASW, min_ASW, field_capacity) => begin
        if ASW > field_capacity
            1.0 - (ASW - field_capacity) / (max_ASW - field_capacity)
        else
            (ASW - min_ASW) / (field_capacity - min_ASW)
        end
    end ~ track(min=0.1) 

    N_uptake_factor(RLV, drought_factor, soil_depth) => begin
        RLV * sqrt(drought_factor) * soil_depth
    end ~ track

    NO3_per_length ~ preserve(parameter)

    NO4_per_length ~ preserve(parameter)

    NO3_uptake(N_uptake_factor, NO3_factor, RTNO3) => begin
        N_uptake_factor * NO3_factor * RTNO3
    end(min=0)

    NH4_uptake(N_uptake_factor, NH4_factor, RTNH4) => begin
        N_uptake_factor * NH4_factor * RTNH4
    end(min=0)

    N_uptake(NO3_up, NH4_up) => begin
        NO3_up + NH4_up
    end

    N_demand(N_demand_veg, N_demand_old#=, N_demand_seed, N_demand_rep=#)

    N_uptake_fraction(N_demand, N_uptake) => begin
        N_demand / N_uptake
    end ~ track(max=1)

    NO3_up(NO3_uptake, N_uptake_fraction) => begin
        NO3_uptake * N_uptake_fraction
    end ~ track

    NH4_up(NH4_uptake, N_uptake_fraction) => begin
        NO3_uptake * N_uptake_fraction
    end ~ track

    NO3_denitrified(KG2PPM) => 0.25 / KG2PPM

    NO3_uptake_max(NO3, NO3_denitrified) => NO3 - NO3_denitrified

    NH4_immobilized(KG2PPM) => 0.5 / KG2PPM

    NH4_uptake_max(NH4, NH4_immobilized) => NH4 - NH4_denitrified


    # VEGGR

    N_supply(N_fixation, N_uptake, N_mined) => begin
        N_fixation + N_uptake + N_mined
    end ~ track

    N_stress(N_supply, N_demand_new, N_stress_factor) => begin
        N_supply / (N_demand_new * N_stress_factor)
    end ~ track

    N_fraction_leaf_max

    N_fraction_stem_max

    N_fraction_root_max

    N_fraction_leaf_min

    N_fraction_stem_min

    N_fraction_root_min


    N_demand_leaf_max(growth_leaf, N_fraction_leaf_max)  ~ track

    N_demand_stem_max(growth_stem, N_fraction_stem_max) ~ track

    N_demand_root_max(growth_root, N_fraction_root_max) ~ track

    N_demand_leaf_min(growth_leaf, N_fraction_leaf_min)

    N_demand_stem_min(growth_stem, N_fraction_stem_min)

    N_demand_root_min(growth_root, N_fraction_root_min)


    N_ratio(N_available, N_growth) => N_available / N_growth

    growth_foliage2(growth_foliage, N_ratio) => growth_follage * N_ratio

    ch2o_per_growth ~ preserve(parameter)

    growth_demand(GPP, CH2O_per_vegetative) => begin
        GPP / CH2O_per_growth
    end ~ track # CH2O to Vegetative mass conversion

    # growth_foliage(growth_demand * GPP * partition)

    AGRVG(

    PGAVL: total available ch2o available for growth & respiration

    protein_leaf(N_growth_leaf, )

end