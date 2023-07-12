@system NitrogenDemand begin
    # I don't know why this is here it should be in nitrogen mobilization?
    # Nitrogen mobilization rate. Not sure what the numerical values represent.
    # NMOBR is mining rate as a fraction of the maximum rate, NMOBMX
    # NMOBR(NVSMOD, NMOBMX, TDUMX) => begin
    #     NMOBMX * TDUMX2 * (1.0 + 0.5*(1.0 - SWFAC)) *
    #     (1.0 + 0.3 * (1.0 - NSTRES)) * (NVSMOB + (1 - NVSMOB) *
    #     max(XPOD, DXR57^2))
    # end ~ track

    # # Potential nitrogen mined. Nitrogen mobilization rate * N mined from each organ.
    # # Get rid of shell?
    # NMINEP(NMOBR, WNRLF, WNRST, WNRRT, WNRSH) => begin
    #     NMOBR * (WNRLF + WNRST + WNRRT + WNRSH)
    # end

    PROLFI ~ preserve(parameter)
    PROLFG ~ preserve(parameter)
    PROSTI ~ preserve(parameter)
    PROSTG ~ preserve(parameter)
    PRORTI ~ preserve(parameter)
    PRORTG ~ preserve(parameter)

    "Maximum fraction of nitrogen for growing leaf tissue"
    FNINL(PROLFI) => PROLFI * 0.16
    "Minimum fraction of nitrogen for growing leaf tissue"
    FNINLG(PROLFG) => PROLFG * 0.16

    "Maximum fraction of nitrogen for growing stem tissue"
    FNINS(PROSTI) => PROSTI * 0.16
    "Minimum fraction of nitrogen for growing stem tissue"
    FNINSG(PROSTG) => PROSTG * 0.16

    "Maximum fraction of nitrogen for growing root tissue"
    FNINR(PRORTI) => PRORTI * 0.16
    "Minimum fraction of nitrogen for growing root tissue"
    FNINRG(PRORTG) => PRORTG * 0.16
                       
    # C_demand_rep => 0 ~ preserve

    # CAVTOT => 0 ~ preserve

    # Entire C_available will be dedicated to vegetative tissue because
    # there is no reproductive demand in the current model.
    C_demand_veg(C_available) => C_available ~ track

    # N demand for reproduction.
    # Reproduction is not a part of the model at the moment
    # so I am setting it as 0.
    NDMREP => 0 ~ preserve

    # g[CH2O] / g[tissue]
    "Mass of CH2O required for protein in vegetative tissue growth"
    CH2O_req_protein() => begin
        RPROAV *
       (partition_foliage * PROLFI +
        partition_stem * PROSTI +
        partition_root * PRORTI)
    end ~ track

    # Total mass of CH2O required for vegetative tissue growth
    # g[CH2O] / g[tissue
    # RPROAV in forage.jl
    "Mass of CH2O required for vegetative tissue growth including stoichiometry and respiration"
    CH2O_req_veg(CH2O_req_protein) => begin
        CH2O_req_protein +
       (CH2O_req_leaf * partition_foliage +
        CH2O_req_stem * partition_stem +
        CH2O_req_root * partition_root)
    end ~ track

    # N required for vegetative growth.
    # CDMVEG / AGRVG2 is for conversion of CH2O mass to vegetative tissue mass.
    # 
    NDMVEG(CDMVEG, AGRVG2, FRML, FNINL, FRSTM, FNINS, FRRT, FNINR) => begin
        (CDMVEG / AGRVG2) * (FRLF * FNINL + FRSTM * FNINS + FRRT * FNINR)
    end ~ track

    # NDMREP is 0 currently so NDMNEW is the same as NDMVEG.
    NDMNEW(NDMREP, NDMVEG) => NDMREP + NDMVEG ~ track

    # Available CH2O after reproductive growth. There is no reproductive growth currently,
    # so all of C_available
    CNOLD(C_available, C_demand_rep) => C_available - C_demand_rep ~ track(min=0)

    # Minimum leaf protein composition after N mining.
    PROLFF

    # CROPGRO has two different calculations based on phenological phase.
    # This model does not include reproductive phase at the moment and only uses one
    # calculation. In CROPGRO, nitrogen content is higher in the tissue during later stages
    # of the reproductive cycle.

    "Nitrogen content in leaves (fraction)"
    NVSTL(PROLFR) => PROLFR * 0.16 ~ track

    "Nitrogen content in stem (fraction)"
    NVSTS(PROSTR) => PROSTR * 0.16 ~ track

    "Nitrogen content in root (fraction)"
    NVSTR(PRORTR) => PRORTR * 0.16 ~ track

    N_demand_old_max(CNOLD, RNO3C) => CNOLD / RNO3C * 16 ~ track

    # Nitrogen demand for old tissue. Not sure where the value 0.16 comes from.
    NDMOLD(WTLF, SLDOT, WCRLF, PROLFR) => begin
        max(0, (WF - SLDOT - WCRLF) * PROLFT * 0.16 - WTNST) +
        max(0, (WS - SDDOT - WCRST) * PROSTR * 0.16 - WTNST) +
        max(0, (WR - SSRDOT - WCRSR) * PROSSR * 0.16 - WTNSR)
    end(max=N_demand_old_max)

    # Curvature factor (K value) for exponential function limiting N_demand_old when C_available is low.
    KCOLD => 0.01 ~ preserve(parameter) # DSSAT CROPGRO perennial

    # CHO required for uptake and reduction of N to fully refill old tissue N (g[CH2O] / m2 / d)
    CHOPRO(N_demand_old, RNO3C) => begin
        N_demand_old * RNO3C * 6.25 # Not sure what the 6.25 value represents.
    end

    # Fraction of max potential NDMOLD allowed to be met given
    # today's level of CDMVEG.  Prevents refilling old tissue
    # without allowing any new growth due to low PG.
    FROLDA(CDMVEG, CHOPRO, KCOLD) => begin
        1 - exp(-KCOLD * (C_demand_veg / CHOPRO))
    end

    C_demand_old(CHOPRO, FROLDA) => begin
        FROLDA * FROLDA
    end

    N_demand_old(FROLDA, N_demand_old) => begin
        FROLDA * N_demand_old
    end

    N_demand(N_demand_veg, N_demand_old#=, N_demand_rep=#) => begin
        N_demand_veg + N_demand_old#= + N_demand_rep=#
    end

    C_demand(C_demand_veg, N_demand_old, RNO3C#=, C_demand_rep=#) => begin
        C_demand_veg + N_demand_old * RNO3C / 0.16#= + C_demand_rep=#
        # Average nitrogen content for protein is 16%
    end
end