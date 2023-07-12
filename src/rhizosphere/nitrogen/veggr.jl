@system NitrogenVeggr begin
    N_supply(N_fixation, N_uptake, N_mined) => begin
        N_fixation + N_up + N_mined
    end ~ track

    N_stress(N_supply, N_demand_new, N_stress_factor) => begin
        N_supply / (N_demand_new * N_stress_factor)
    end ~ track
    

    N_fraction_leaf_max => 0 ~ preserve(parameter)

    N_fraction_stem_max => 0 ~ preserve(parameter)

    N_fraction_root_max => 0 ~ preserve(parameter)

    N_fraction_leaf_min => 0 ~ preserve(parameter)

    N_fraction_stem_min => 0 ~ preserve(parameter)

    N_fraction_root_min => 0 ~ preserve(parameter)


    N_demand_leaf_max(growth_leaf, N_fraction_leaf_max)  ~ track

    N_demand_stem_max(growth_stem, N_fraction_stem_max) ~ track

    N_demand_root_max(growth_root, N_fraction_root_max) ~ track

    # N_demand_leaf_min(growth_leaf, N_fraction_leaf_min)

    # N_demand_stem_min(growth_stem, N_fraction_stem_min)

    # N_demand_root_min(growth_root, N_fraction_root_min)

    # N_stressed(N_ratio) => N_ratio < 1 ~ flag

    # N_ratio(N_available, N_growth) => N_available / N_growth

    # growth_foliage2(growth_foliage, N_ratio) => growth_follage * N_ratio

    # protein_leaf_growth
    # protein_leaf_max

    # protein_stem_growth
    # protein_stem_max

    # protein_root_growth
    # protein_root_max

    ch2o_per_growth => begin
        if N_stressed
             CH2O_req_leaf * partition_foliage * (1 - (protein_leaf_growth - protein_leaf_max)/(1 - protein_leaf_max)) +
            AGRSTM * partition_stem * (1 - (protein_stem_growth - protein_stem_max)/(1 - protein_stem_max)) +
             CH2O_req_root * partition_root * (1 - (protein_stem_growth - protein_stem_max)/(1 - protein_stem_max))
        else
            CH2O_req_leaf * partition_foliage + AGRSTM * partition_stem + CH2O_req_root * partition_root
        end
    end ~ preserve(parameter)


    growth_demand(GPP, CH2O_per_vegetative) => begin
        GPP / CH2O_per_growth
    end ~ track # CH2O to Vegetative mass conversion

    growth_demand_leaf(growth_demand, partition_foliage) ~ growth_demand * partition_foliage ~ track

    growth_demand_stem(growth_demand, partition_stem) ~ growth_demand * partition_stem ~ track

    growth_demand_root(growth_demand, partition_root) ~ growth_demand * partition_root ~ track

    N_demand_min(N_demand_leaf_min, N_demand_stem_min, N_demand_root_min) => begin
        N_demand_leaf_min + N_demand_stem_min + N_demand_root_min
    end

    N_ratio(N_available, N_up) => N_available / N_up ~ track(min=0, max=1) ~ track

    growth_leaf(growth_demand_leaf, N_ratio) => growth_demand_leaf * N_ratio ~ track

    growth_stem(growth_demand_stem, N_ratio) => growth_demand_stem * N_ratio ~ track

    growth_root(growth_demand_root, N_ratio) => growth_demand_root * N_ratio ~ track


    # C_available: total available ch2o available for growth & respiration

    # protein_leaf(N_growth_leaf, ) => N_avaiable * 
    # protein_stem(N_growth_stem, )
    # protein_root(N_growth_root, )
end