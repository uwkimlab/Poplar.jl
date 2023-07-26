@system Veggr begin
    N_supply(N_uptake, N_mined#=, N_fixation=#) => begin
        N_uptake + N_mined#= + N_fixation=#
    end ~ track(u"g/m^2/hr")

    N_stress_factor => 0.7 ~ preserve(parameter)

    N_stress(N_supply, N_demand_new, N_stress_factor) => begin
        if (N_demand_new * N_stress_factor) == 0u"g/m^2/hr"
            1
        else
        # if N_supply < N_stress_factor * N_demand_new && N_demand_new > 0u"g/m^2/hr"
            N_supply / (N_demand_new * N_stress_factor)
        end    
    end ~ track(max=1)

    "Potential CH2O required for vegetative tissue (stoichiometry and respiration)"
    CH2O_for_veg(AGRLF, AGRSTM, AGRRT, partition_foliage, partition_stem, partition_root) => begin
        (AGRLF * partition_foliage +
        AGRSTM * partition_stem +
        AGRRT * partition_root)
    end ~ track(u"g/g")

    "Carbon demand for vegetative growth"
    growth_demand(C_available, CH2O_for_veg) => begin
        C_available / CH2O_for_veg
    end ~ track(u"g/m^2/hr")

    "Potential foliage growth rate (possible reduction due to N deficiency)"
    growth_foliage_potential(partition_foliage, growth_demand) => partition_foliage * growth_demand ~ track(u"g/m^2/hr")

    "Potential stem growth rate (possible reduction due to N deficiency)"
    growth_stem_potential(partition_stem, growth_demand) => partition_stem * growth_demand ~ track(u"g/m^2/hr")

    "Potential root growth rate (possible reduction due to N deficiency)"
    growth_root_potential(partition_root, growth_demand) => partition_root * growth_demand ~ track(u"g/m^2/hr")

    "Potential storage growth rate (possible reduction due to N deficiency)"
    growth_storage_potential(partition_storage, growth_demand) => partition_storage  * growth_demand ~ track(u"g/m^2/hr")

    "Maximum N required for leaf growth"
    growth_foliage_N_max(growth_foliage_potential, FNINL) => growth_foliage_potential * FNINL ~ track(u"g/m^2/hr")

    "Maximum N required for stem growth"
    growth_stem_N_max(growth_stem_potential, FNINS) => growth_stem_potential * FNINS ~ track(u"g/m^2/hr")

    "Maximum N required for root growth"
    growth_root_N_max(growth_root_potential, FNINR) => growth_root_potential * FNINR ~ track(u"g/m^2/hr")

    "Maximum N requiried for storage growth"
    growth_storage_N_max(growth_foliage_potential, FNINSR) => growth_storage_potential * FNINSR ~ track(u"g/m^2/hr")

    "Maximum N required for vegetative growth"
    growth_N_max(growth_foliage_N_max, growth_stem_N_max, growth_root_N_max, growth_storage_N_max) => begin
        growth_foliage_N_max + growth_stem_N_max + growth_root_N_max + growth_storage_N_max
    end ~ track(u"g/m^2/hr")

    "Minimum N required for leaf growth"
    growth_foliage_N_min(growth_foliage_potential, FNINLG) => growth_foliage_potential * FNINLG ~ track(u"g/m^2/hr")

    "Minimum N required for stem growth"
    growth_stem_N_min(growth_stem_potential, FNINSG) => growth_stem_potential * FNINSG ~ track(u"g/m^2/hr")

    "Minimum N requred for root growth"
    growth_root_N_min(growth_root_potential, FNINRG) => growth_root_potential * FNINRG ~ track(u"g/m^2/hr")
    # "Minimum N storage"
    # N_storage_min(growth_foliage_potential, FNINSRG) => growth_storage_potential * FNINSRG ~ track(u"g/m^2/hr")

    "Minimum N required for vegetative growth"
    growth_N_min(growth_foliage_N_min, growth_stem_N_min, growth_root_N_min#=, N_storage_min=#) => begin
        growth_foliage_N_min + growth_stem_N_min + growth_root_N_min#= + N_storage_min=#
    end ~ track(u"g/m^2/hr")

    "Ratio of available N to minimum N required for vegetative growth"
    NRATIO(N_supply, growth_N_min) => begin
        if growth_N_min == 0u"g/m^2/hr"
            0
        else
            N_supply / growth_N_min
        end
    end ~ track(max=1)

    "Leaf growth rate adjusted for nitrogen deficiency"
    growth_foliage(growth_foliage_potential, NRATIO) => begin
        # if N_supply < growth_N_min
            growth_foliage_potential * NRATIO
        # else
        #     growth_foliage_potential
        # end
    end ~ track(u"g/m^2/hr")

    "Leaf growth rate adjusted for nitrogen deficiency"
    growth_stem(growth_stem_potential, NRATIO) => begin
        # if N_supply < growth_N_min
            growth_stem_potential * NRATIO
        # else
        #     growth_stem_potential
        # end
    end ~ track(u"g/m^2/hr")

    "Leaf growth rate adjusted for nitrogen deficiency"
    growth_root(growth_root_potential, NRATIO) => begin
        # if N_supply < growth_N_min
            growth_root_potential * NRATIO
        # else
        #     growth_root_potential
        # end
    end ~ track(u"g/m^2/hr")

    growth_storage(growth_storage_potential, NRATIO) => begin
    # if N_supply < growth_N_min
        growth_storage_potential * NRATIO
    # else
    #     growth_root_potential
    # end
    end ~ track(u"g/m^2/hr")

    "Actual N required for leaf growth"
    growth_foliage_N(N_supply, growth_N_min, growth_foliage_N_min, NRATIO, growth_foliage, growth_demand) => begin
        if N_supply < growth_N_min
            growth_foliage_N_min * NRATIO
        else
            N_supply * (growth_foliage / growth_demand)
        end
    end ~ track(max=growth_foliage_N_max, u"g/m^2/hr")
    
    "Actual N required for stem growth"
    growth_stem_N(N_supply, growth_N_min, growth_stem_N_min, NRATIO, growth_stem, growth_demand) => begin
        if N_supply < growth_N_min
            growth_stem_N_min * NRATIO
        else
            N_supply * (growth_stem / growth_demand)
        end
    end ~ track(max=growth_stem_N_max, u"g/m^2/hr")

    "Actual N required for root growth"
    growth_root_N(N_supply, growth_N_min, growth_root_N_min, NRATIO, growth_root, growth_demand) => begin
        if N_supply < growth_N_min
            growth_root_N_min * NRATIO
        else
            N_supply * (growth_root / growth_demand)
        end
    end ~ track(max=growth_root_N_max, u"g/m^2/hr")

    "Actual N required for storage"
    growth_storage_N(N_supply, growth_N_min, N_storage_min, NRATIO, growth_storage, growth_demand) => begin
        if N_supply < growth_N_min
            growth_stem_N_min * NRATIO
        else
            N_supply * (growth_storage / growth_demand)
        end
    end ~ track(max=growth_storage_N_max, u"g/m^2/hr")

    "Protein fraction for new leaf growth"
    PROLFT(growth_foliage_N, growth_foliage) => begin
        if growth_foliage == 0u"g/m^2/hr"
            0
        else
            growth_foliage_N * (1 / 0.16) / growth_foliage
        end
    end ~ track

    "Protein fraction for new stem growth"
    PROSTT(growth_stem_N, growth_stem) => begin
        if growth_stem == 0u"g/m^2/hr"
            0
        else
            growth_stem_N * (1 / 0.16) / growth_stem
        end
    end ~ track

    "Protein fraction for new root growth"
    PRORTT(growth_root_N, growth_root) => begin
        if growth_root == 0u"g/m^2/hr"
            0
        else
            growth_root_N * (1 / 0.16) / growth_root
        end
    end ~ track

    "Protein fraction for new storage growth"
    PROSRT(growth_storage_N, growth_storage) => begin
        if growth_storage == 0u"g/m^2/hr"
            0
        else
            growth_storage_N * (1 / 0.16) / growth_storage
        end
    end ~ track

    # PGLEFT(C_available, growth_foliage, growth_stem, growth_root, growth_storage, AGRVG3) => begin
    #     C_available - (growth_foliage + growth_stem + growth_root + growth_storage) * AGRVG3
    # end ~ track

    N_growth(growth_foliage_N, growth_stem_N, growth_root_N, growth_storage_N) => growth_foliage_N + growth_stem_N + growth_root_N + growth_storage_N ~ track(u"g/m^2/hr")

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