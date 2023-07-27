@system Demand begin

    "Mass of CH2O required for protein in vegetative tissue growth"
    CH2O_for_protein(RPROAV, partition_foliage, PROLFI, partition_stem, PROSTI, partition_root, PRORTI) => begin
        RPROAV *
       (partition_foliage * PROLFI +
        partition_stem * PROSTI +
        partition_root * PRORTI)
    end ~ track(u"g/g")

    "Mass of CH2O required for vegetative tissue growth including stoichiometry and respiration (at N saturation)"
    CH2O_for_veg_protein(CH2O_for_protein, AGRLF, AGRSTM, AGRRT, partition_foliage, partition_stem, partition_root) => begin
        CH2O_for_protein +
       (AGRLF * partition_foliage +
        AGRSTM * partition_stem +
        AGRRT * partition_root)
    end ~ track(u"g/g")

    "CH2O demand for vegetative growth"
    C_demand_veg_p(C_available) ~ track(u"g/m^2/hr") # C demand might need to get reduced based on CHO available for nitrogen
    
    # N required for vegetative growth.
    # CDMVEG / AGRVG2 is for conversion of CH2O mass to vegetative tissue mass.
    "Nitrogen demand for vegetative growth"
    N_demand_veg_p(C_demand_veg_p, CH2O_for_veg_protein, partition_foliage, FNINL, partition_stem, FNINS, partition_root, FNINR) => begin
        (C_demand_veg_p / CH2O_for_veg_protein) * (partition_foliage * FNINL + partition_stem * FNINS + partition_root * FNINR)
    end ~ track(u"g/m^2/hr")

    # NDMREP is 0 currently so NDMNEW is the same as NDMVEG.
    # N_demand_new(#=N_demand_rep, =#N_demand_veg) => N_demand_rep + N_demand_veg ~ track

    "Available CH2O after reproductive growth"
    CNOLD(C_available) => C_available ~ track(min=0, u"g/m^2/hr")

    "Maximum N demand for old tissue"
    N_demand_old_max(CNOLD, RNO3C) => CNOLD / RNO3C * 0.16 ~ track(u"g/m^2/hr")

    # Nitrogen demand for old tissue. Not sure where the value 0.16 comes from.
    "N demand for old tissue"
    N_demand_old_p(N_demand_old_max) => begin
        N_demand_old_max
        # max(0, (WF - SLDOT - WCRLF) * PROLFT * 0.16 - N_stem) +
        # max(0, (WS - SDDOT - WCRST) * PROSTR * 0.16 - N_stem) +
        # max(0, (WR - SSRDOT - WCRSR) * PROSSR * 0.16 - N_storage)
    end ~ track(max=N_demand_old_max, u"g/m^2/hr")

    # Available CH2O after reproductive growth. There is no reproductive growth currently,
    # so all of C_available

    "CHO required for uptake and reduction of N to fully refill old N tissue"
    CHOPRO(N_demand_old_p, RNO3C) => begin
        N_demand_old_p * 6.25 * RNO3C # Not sure where 6.25 comes from...
    end ~ track(u"g/m^2/d")

    KCOLD => 0.01 ~ preserve(parameter)

    "Fraction of max potential N demand "
    FROLDA(KCOLD, C_demand_veg_p, CHOPRO) => begin
        if CHOPRO == 0u"g/m^2/d"
            0
        else
            1 - exp(-KCOLD * (C_demand_veg_p / CHOPRO))
        end
    end ~ track

    ""
    C_demand_old_p(CHOPRO, FROLDA) => begin
        CHOPRO * FROLDA
    end ~ track(u"g/m^2/hr")

    N_demand_old(FROLDA, N_demand_old_p) => begin
        FROLDA * N_demand_old_p
    end ~ track(u"g/m^2/hr")

    C_demand_old(N_demand_old, RNO3C) => begin
        N_demand_old * RNO3C / 0.16
    end ~ track(u"g/m^2/hr") # Final C demand based on final N demand

    C_demand_veg(C_demand_veg_p, C_demand_old_p) => begin
        C_demand_veg_p - C_demand_old_p
    end ~ track(u"g/m^2/hr")

    N_demand_veg(C_demand_veg, CH2O_for_veg_protein, partition_foliage, FNINL, partition_stem, FNINS, partition_root, FNINR) => begin
        (C_demand_veg / CH2O_for_veg_protein) * (partition_foliage*FNINL + partition_stem * FNINS + partition_root * FNINR#= + FRSTR * FNINSR=#)
    end ~ track(u"g/m^2/hr")

    N_demand_new(N_demand_veg) => begin
        N_demand_veg
    end ~ track(u"g/m^2/hr")
    
    N_demand(N_demand_veg, N_demand_old) => begin
        N_demand_veg + N_demand_old
    end ~ track(u"g/m^2/hr")

    N_demand2(N_demand) ~ track(u"kg/ha/hr")

    C_demand(C_demand_veg, C_demand_old) => begin
        C_demand_veg + C_demand_old
    end ~ track(u"g/m^2/hr")

    # CROPGRO has two different calculations based on phenological phase.
    # This model does not include reproductive phase at the moment and only uses one
    # calculation. In CROPGRO, nitrogen content is higher in the tissue during later stages
    # of the reproductive cycle.

    # "Nitrogen content in leaves (fraction)"
    # NVSTL(PROLFR) => PROLFR * 0.16 ~ track

    # "Nitrogen content in stem (fraction)"
    # NVSTS(PROSTR) => PROSTR * 0.16 ~ track

    # "Nitrogen content in root (fraction)"
    # NVSTR(PRORTR) => PRORTR * 0.16 ~ track

    # Curvature factor (K value) for exponential function limiting N_demand_old when C_available is low.

    # Fraction of max potential NDMOLD allowed to be met given
    # today's level of CDMVEG.  Prevents refilling old tissue
    # without allowing any new growth due to low PG.
    # FROLDA(CDMVEG, CHOPRO, KCOLD) => begin
    #     1 - exp(-KCOLD * (C_demand_veg / CHOPRO))
    # end

    # C_demand_old(CHOPRO, FROLDA) => begin
    #     FROLDA * FROLDA
    # end

    # N_demand_old(FROLDA, N_demand_old) => begin
    #     FROLDA * N_demand_old
    # end

    # N_demand(N_demand_veg, N_demand_old#=, N_demand_rep=#) => begin
    #     N_demand_veg + N_demand_old#= + N_demand_rep=#
    # end

    # C_demand(C_demand_veg, N_demand_old, RNO3C#=, C_demand_rep=#) => begin
    #     C_demand_veg + N_demand_old * RNO3C / 0.16#= + C_demand_rep=#
    #     # Average nitrogen content for protein is 16%
    # end
end