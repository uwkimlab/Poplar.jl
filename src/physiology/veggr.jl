@system Veggr begin
    N_supply(#=N_fixation, =#N_uptake#=, N_mined=#) => begin
        #=N_fixation + =#N_uptake#= + N_mined=#
    end ~ track(u"g/m^2/hr")

    N_stress_factor => 0.7 ~ preserve(parameter)

    N_stress(N_supply, N_demand_new, N_stress_factor) => begin
        # if N_supply < N_stress_factor * N_demand_new && N_demand_new > 0u"g/m^2/hr"
            N_supply / (N_demand_new * N_stress_factor)
        # end    
    end ~ track(max=1)

    AGRVG_p(AGRLF, AGRSTM, AGRRT, partition_foliage, partition_stem, partition_root) => begin
        (AGRLF * partition_foliage +
        AGRSTM * partition_stem +
        AGRRT * partition_root)
    end ~ track(u"g/g")

    growth_demand(C_available, AGRVG_p) => begin
        C_available / AGRVG_p
    end ~ track(u"g/m^2/hr")

    "Dry weight growth rate of new leaf tissue including N but not C reserves"
    growth_foliage_potential(partition_foliage, growth_demand) => partition_foliage * growth_demand ~ track(u"g/m^2/hr")

    "Potential growth rate stem"
    growth_stem_potential(partition_stem, growth_demand) => partition_stem * growth_demand ~ track(u"g/m^2/hr")

    "Potenttial Growth rate root"
    growth_root_potential(partition_root, growth_demand) => partition_root * growth_demand ~ track(u"g/m^2/hr")

    # "Potential Growth rate storage organ"
    # growth_storage_potential(partition_storage, growth_demand) => partition_storage  * growth_demand ~ track(u"g/m^2/hr")

    "Maximum N leaf"
    N_foliage_max(growth_foliage_potential, FNINL) => growth_foliage_potential * FNINL ~ track(u"g/m^2/hr")
    "Maximum N stem"
    N_stem_max(growth_stem_potential, FNINS) => growth_stem_potential * FNINS ~ track(u"g/m^2/hr")
    "Maximum N root"
    N_root_max(growth_root_potential, FNINR) => growth_root_potential * FNINR ~ track(u"g/m^2/hr")
    # "Maximum N storage"
    # N_storage_max(growth_foliage_potential, FNINSR) => growth_storage_potential * FNINSR ~ track(u"g/m^2/hr")
    "Maximum N vegetative"
    N_max(N_foliage_max, N_stem_max, N_root_max#=, N_storage_max=#) => begin
        N_foliage_max + N_stem_max + N_root_max#= + N_storage_max=#
    end ~ track(u"g/m^2/hr")

    "Minimum N leaf"
    N_foliage_min(growth_foliage_potential, FNINLG) => growth_foliage_potential * FNINLG ~ track(u"g/m^2/hr")
    "Minimum N stem"
    N_stem_min(growth_stem_potential, FNINSG) => growth_stem_potential * FNINSG ~ track(u"g/m^2/hr")
    "Minimum N root"
    N_root_min(growth_root_potential, FNINRG) => growth_root_potential * FNINRG ~ track(u"g/m^2/hr")
    # "Minimum N storage"
    # N_storage_min(growth_foliage_potential, FNINSRG) => growth_storage_potential * FNINSRG ~ track(u"g/m^2/hr")
    "Minimum N vegetative"
    N_min(N_foliage_min, N_stem_min, N_root_min#=, N_storage_min=#) => begin
        N_foliage_min + N_stem_min + N_root_min#= + N_storage_min=#
    end ~ track(u"g/m^2/hr")

    "Ratio of available N to minimum N required for vegetative growth"
    NRATIO(N_supply, N_min) => N_supply / N_min ~ track(max=1)

    "Leaf growth rate adjusted for nitrogen deficiency"
    growth_foliage(growth_foliage_potential, NRATIO) => begin
        # if N_supply < N_min
            growth_foliage_potential * NRATIO
        # else
        #     growth_foliage_potential
        # end
    end ~ track(u"g/m^2/hr")

    "Leaf growth rate adjusted for nitrogen deficiency"
    growth_stem(growth_stem_potential, NRATIO) => begin
        # if N_supply < N_min
            growth_stem_potential * NRATIO
        # else
        #     growth_stem_potential
        # end
    end ~ track(u"g/m^2/hr")

    "Leaf growth rate adjusted for nitrogen deficiency"
    growth_root(growth_root_potential, NRATIO) => begin
        # if N_supply < N_min
            growth_root_potential * NRATIO
        # else
        #     growth_root_potential
        # end
    end ~ track(u"g/m^2/hr")

    "N for leaf growth"
    NGRLF(N_supply, N_min, N_foliage_min, NRATIO, growth_foliage, growth_demand) => begin
        if N_supply < N_min
            N_foliage_min * NRATIO
        else
            N_supply * (growth_foliage / growth_demand)
        end
    end ~ track(max=N_foliage_max, u"g/m^2/hr")
    
    "N for stem growth"
    NGRST(N_supply, N_min, N_stem_min, NRATIO, growth_stem, growth_demand) => begin
        if N_supply < N_min
            N_stem_min * NRATIO
        else
            N_supply * (growth_stem / growth_demand)
        end
    end ~ track(max=N_stem_max, u"g/m^2/hr")

    NGRRT(N_supply, N_min, N_root_min, NRATIO, growth_root, growth_demand) => begin
        if N_supply < N_min
            N_root_min * NRATIO
        else
            N_supply * (growth_root / growth_demand)
        end
    end ~ track(max=N_root_max, u"g/m^2/hr")

    # NGRSR(N_supply, N_min, N_storage_min, NRATIO, growth_storage, growth_demand) => begin
    #     if N_supply < N_min
    #         N_stem_min * NRATIO
    #     else
    #         N_supply * (growth_storage / growth_demand)
    #     end
    # end ~ track(max=N_storage_max, u"g/m^2/hr")

    N_growth(NGRLF, NGRST, NGRRT#=, NGRSR=#) => NGRLF + NGRST + NGRRT#= + NGRSR =#~ track(u"g/m^2/hr")

    N_total(N_growth) ~ accumulate(init=0, u"g/m^2")

    # CH2O_per_growth => begin
    #     if N_stressed
    #          CH2O_req_leaf * partition_foliage * (1 - (protein_leaf_growth - protein_leaf_max)/(1 - protein_leaf_max)) +
    #         AGRSTM * partition_stem * (1 - (protein_stem_growth - protein_stem_max)/(1 - protein_stem_max)) +
    #          CH2O_req_root * partition_root * (1 - (protein_stem_growth - protein_stem_max)/(1 - protein_stem_max))
    #     else
    #         CH2O_req_leaf * partition_foliage + AGRSTM * partition_stem + CH2O_req_root * partition_root
    #     end
    # end ~ preserve(parameter)


    # growth_demand(GPP, CH2O_per_vegetative) => begin
    #     GPP / CH2O_per_growth
    # end ~ track # CH2O to Vegetative mass conversion

    # growth_demand_leaf(growth_demand, partition_foliage) ~ growth_demand * partition_foliage ~ track

    # growth_demand_stem(growth_demand, partition_stem) ~ growth_demand * partition_stem ~ track

    # growth_demand_root(growth_demand, partition_root) ~ growth_demand * partition_root ~ track

    # N_demand_min(N_demand_leaf_min, N_demand_stem_min, N_demand_root_min) => begin
    #     N_demand_leaf_min + N_demand_stem_min + N_demand_root_min
    # end

    # N_ratio(N_supply, N_up) => N_supply / N_up ~ track(min=0, max=1) ~ track

    # growth_leaf(growth_demand_leaf, N_ratio) => growth_demand_leaf * N_ratio ~ track

    # growth_stem(growth_demand_stem, N_ratio) => growth_demand_stem * N_ratio ~ track

    # growth_root(growth_demand_root, N_ratio) => growth_demand_root * N_ratio ~ track


    # C_available: total available ch2o available for growth & respiration

    # protein_leaf(N_growth_leaf, ) => N_avaiable * 
    # protein_stem(N_growth_stem, )
    # protein_root(N_growth_root, )
end