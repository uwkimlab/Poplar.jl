@system NitrogenMobilization begin
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