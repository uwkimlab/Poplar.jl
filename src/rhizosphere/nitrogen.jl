@system Nitrogen begin

    # NITROGEN DEMAND CALCULATION

    # Nitrogen mobilization rate. Not sure what the numerical values represent.
    NMOBR(NVSMOD, NMOBMX, TDUMX) => begin
        NMOBMX * TDUMX2 * (1.0 + 0.5*(1.0 - SWFAC)) *
        (1.0 + 0.3 * (1.0 - NSTRES)) * (NVSMOB + (1 - NVSMOB) *
        max(XPOD, DXR57^2))
    end ~ track

    # Potential nitrogen mined.
    NMINEP(NMOBR, WNRLF, WNRST, WNRRT, WNRSH) => begin
        NMOBR * (WNRLF + WNRST + WNRRT + WNRSH)
    end

    # N demand for reproduction.
    # Reproduction is not a part of the model at the moment
    # so I am setting it as 0.
    NDMREP => 0 ~ preserve

    # N required for vegetative growth.
    # CDMVEG / AGRVG2 is for conversion of CH2O mass to vegetative tissue mass.
    # 
    NDMVEG(CDMVEG, AGRVG2, FRML, FNINL, FRSTM, FNINS, FRRT, FNINR) => begin
        (CDMVEG / AGRVG2) * (FRLF * FNINL + FRSTM * FNINS + FRRT * FNINR)
    end ~ track

    # NDMREP is 0 currently so NDMNEW is the same as NDMVEG.
    NDMNEW(NDMREP, NDMVEG) => NDMREP + NDMVEG ~ track

    # Minimum leaf protein composition after N mining.
    PROLFF

    # CROPGRO has two different calculations based on phenological phase.
    # This model does not include reproductive phase at the moment and only uses one
    # calculation. In CROPGRO, nitrogen content is higher in the tissue during later stages
    # of the reproductive cycle.
    NVSTL(PROLFR) => PROLFR * 0.16 ~ track
    NVSTS(PROSTR) => PROSTR * 0.16 ~ track
    NVSTR(PRORTR) => PRORTR * 0.16 ~ track

    # storage tissue???
    NVSTSR(PROSSR) => PROSRF * 0.16 ~ track

    #

    # Available CH2O after reprductive growth
    # (so all CH2O because there is no reproductive growth at the moment)
    CNOLD(PGAVL, CDMREP) => begin
        PGAVL - CDMREP
    end(min=0)

    CNOLD/RNO3C*0.16

    # Nitrogen demand for old tissue. Not sure where the value 0.16 comes from.
    NDMOLD(WTLF, SLDOT, WCRLF, PROLFR) => begin
        max(0, (WTLF - SLFDOR - WCRLF) * PROLFT * 0.16 - WTNST) +
        max(0, (STMWT - SDDOT - WCRST) * PROSTR * 0.16 - WTNST) +
        max(0, (STRWT - SSRDOT - WCRSR) * PROSSR * 0.16 - WTNSR)
    end

    NDM

    # Total nitrogen demand.
    NDMTOT(NDMREP, NDMVEG, NDMOLD) => begin
        NDMREP + NDMVEG + NDMOLD
    end

    # Maximum fraction of N to leaf
    leaf_N_fraction_max

    # Maximum fraction of N to stem
    stem_N_fraction_max

    # Maximum fraction of N to root
    root_N_fraction_max

    # specific leaf area factor?
    # TPHFAC()

    # Potential NH4 availability factor from CROPGRO.
    # Not sure why 0.04 and below is 0. Potentially unnecessary.
    NH4_factor(NH4) => begin
        f = 1 - exp(-0.08 * NH4)
        f < 0.04 ? 0 : f
    end ~ track(max=1)

    # Poptential NO3 availability factor from CROPGRO.
    # Not sure why 0.04 and belo is 0. Potentially unnecessary.
    NO3_factor(NO3) => begin
        f = 1 - exp(-0.08 * NH4)
        f < 0.04 ? 0 : f
    end ~ track(max=1) # Not sure why 0.04 and below is 0.

    # Relative drought factor from CROPGRO.
    # Not sure why minimum is 0.1.
    drought_factor(ASW, min_ASW, field_capacity) => begin
        if ASW > field_capacity
            1.0 - (ASW - field_capacity) / (max_ASW - field_capacity)
        else
            (ASW - min_ASW) / (field_capacity - min_ASW)
        end
    end ~ track(min=0.1) 

    # Nitrogen uptake conversion factor.
    # Essentially how much kg/ha of nitrogen for mg/cm of nitrogen (root) 
    N_uptake_factor(RLV, drought_factor, soil_depth) => begin
        RLV * sqrt(drought_factor) * soil_depth
    end ~ track

    # Nitrate uptake per unit root length
    NO3_per_length ~ preserve(parameter)

    # Ammonium uptake per unit root length
    NO4_per_length ~ preserve(parameter)

    # Nitrate uptake
    NO3_uptake(N_uptake_factor, NO3_factor, RTNO3) => begin
        N_uptake_factor * NO3_factor * RTNO3
    end(min=0)

    # Ammonium uptake
    NH4_uptake(N_uptake_factor, NH4_factor, RTNH4) => begin
        N_uptake_factor * NH4_factor * RTNH4
    end(min=0)

    # Total nitrogen uptake in a day
    N_uptake(NO3_up, NH4_up) => begin
        NO3_up + NH4_up
    end

    # Total crop N demand. 
    N_demand(N_demand_veg, N_demand_old#=, N_demand_seed, N_demand_rep=#)

    # Demand vs. uptake fraction.
    # Max set to 1 as nitrogen uptake cannot be greater than what is available.
    N_uptake_fraction(N_demand, N_uptake) => begin
        N_demand / N_uptake
    end ~ track(max=1)

    # Actual NO3 uptake based on N uptake fraction.
    NO3_up(NO3_uptake, N_uptake_fraction) => begin
        NO3_uptake * N_uptake_fraction
    end ~ track(max=NO3_up_max)

    # Actual NO3 uptake based on N uptake fraction.
    NH4_up(NH4_uptake, N_uptake_fraction) => begin
        NO3_uptake * N_uptake_fraction
    end ~ track(max=NH4_up_max)

    # Amount of NO3 that stays in soil
    NO3_min(KG2PPM) => 0.25 / KG2PPM ~ preserve(parameter)

    # Minimum NH4 uptake from soil
    NO3_up_max(NO3_soil, NO3_min) => NO3 - NO3_min ~ preserve(parameter)

    # Amount of NH4 that stays in soil
    NH4_min(KG2PPM) => 0.5 / KG2PPM

    # Maximum NH4 uptake from soil
    NH4_up_max(NH4_soil, NH4_min) => NH4 - NH4_min ~ preserve(parameter)

    # Total extractable ammonium in soil
    NH4_soil

    # Total extractable nitrate in soil
    NO3_soil

    # VEGGR

    # 
    N_supply(N_fixation, N_uptake, N_mined) => begin
        N_fixation + N_uptake + N_mined
    end ~ track

    N_stress(N_supply, N_demand_new, N_stress_factor) => begin
        N_supply / (N_demand_new * N_stress_factor)
    end ~ track

    N_fraction_leaf_max() ~ track

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