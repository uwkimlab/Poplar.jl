@system Nitrogen begin




    # NUPTAK #############################



    # VEGGR

    N_supply(N_fixation, N_uptake, N_mined) => begin
        N_fixation + N_up + N_mined
    end ~ track

    N_stress(N_supply, N_demand_new, N_stress_factor) => begin
        N_supply / (N_demand_new * N_stress_factor)
    end ~ track
    

    N_fraction_leaf_max => 0 ~ preserve(parameter)

    N_fraction_stem_max => 0 ~ preserve(parameter)

    N_fraction_root_max => 0 ~ preserve(parameter)

    N_fraction_leaf_min => 0 ~ preserve(paramter)

    N_fraction_stem_min => 0 ~ preserve(parameter)

    N_fraction_root_min => 0 ~ preserve(parameter)


    N_demand_leaf_max(growth_leaf, N_fraction_leaf_max)  ~ track

    N_demand_stem_max(growth_stem, N_fraction_stem_max) ~ track

    N_demand_root_max(growth_root, N_fraction_root_max) ~ track

    N_demand_leaf_min(growth_leaf, N_fraction_leaf_min)

    N_demand_stem_min(growth_stem, N_fraction_stem_min)

    N_demand_root_min(growth_root, N_fraction_root_min)

    N_stressed(N_ratio) => N_ratio < 1 ~ flag

    N_ratio(N_available, N_growth) => N_available / N_growth

    growth_foliage2(growth_foliage, N_ratio) => growth_follage * N_ratio

    protein_leaf_growth
    protein_leaf_max

    protein_stem_growth
    protein_stem_max

    protein_root_growth
    protein_root_max

    ch2o_per_growth => begin
        if N_stressed
             AGRLF * pF * (1 - (protein_leaf_growth - protein_leaf_max)/(1 - protein_leaf_max)) +
            AGRSTM * pS * (1 - (protein_stem_growth - protein_stem_max)/(1 - protein_stem_max)) +
             AGRRT * pR * (1 - (protein_stem_growth - protein_stem_max)/(1 - protein_stem_max))
        else
            AGRLF * pF + AGRSTM * pS + AGRRT * pR
    end ~ preserve(parameter)


    growth_demand(GPP, CH2O_per_vegetative) => begin
        GPP / CH2O_per_growth
    end ~ track # CH2O to Vegetative mass conversion

    growth_demand_leaf(growth_demand, pF) ~ growth_demand * pF ~ track

    growth_demand_stem(growth_demand, pS) ~ growth_demand * pS ~ track

    growth_demand_root(growth_demand, pR) ~ growth_demand * pR ~ track

    N_demand_min(N_demand_leaf_min, N_demand_stem_min, N_demand_root_min) => begin
        N_demand_leaf_min + N_demand_stem_min + N_demand_root_min
    end

    N_ratio(N_available, N_up) => N_available / N_up ~ track(min=0, max=1)

    growth_leaf(growth_demand_leaf, N_ratio) => growth_demand_leaf * N_ratio ~ track

    growth_stem(growth_demand_stem, N_ratio) => growth_demand_stem * N_ratio ~ track

    growth_root(growth_demand_root, N_ratio) => growth_demand_root * N_ratio ~ track


    # PGAVL: total available ch2o available for growth & respiration

    protein_leaf(N_growth_leaf, ) => N_avaiable * 
    protein_stem(N_growth_stem, )
    protein_root(N_growth_root, )

    # MOBIL

    N_mined_actual(N_demand_new, N_uptake, N_mined_potential) => begin
        if N_demand_new - N_uptake > 1.e5 && N_mined_potential > 1.e4
            N_demand_new - N_uptake
        else
            0
        end
    end ~ track

    N_mined_R(N_mined_actual, N_mined_potential, N_mob_rate) => begin
        N_mined_actual / N_mined_potential * N_mob_rate
    end ~ track

    N_mobilized_leaf(N_mined_R, N_available_leaf)

    N_mobilized_root(N_mined_R, N_available_root)

    N_mobilized_stem(N_mined_R, N_available_stem)
end