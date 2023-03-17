include("gasexchange/gasexchange.jl")

@system Photosynthesis begin
    # Calculating transpiration and photosynthesis with stomatal controlled by leaf water potential LeafWP Y
    #TODO: use leaf_nitrogen_content, leaf_width, ET_supply
    sunlit_gasexchange(context, PPFD=Q_sun, LAI=LAI_sunlit) ~ ::GasExchange
    shaded_gasexchange(context, PPFD=Q_sh, LAI=LAI_shaded) ~ ::GasExchange

    leaf_width => begin
        10 # for poplar?
    end ~ preserve(u"cm", parameter)

    #TODO how do we get LeafWP and ET_supply?
    # LWP(WP_leaf): leaf_water_potential ~ track(u"MPa")

    # evapotranspiration_supply(LAI, PD, ws=water_supply, ww=H2O_weight) => begin
    #     #TODO common handling logic for zero LAI
    #     #FIXME check unit conversion (w.r.t water_supply)
    #     # ? * (1/m^2) / (3600s/hour) / (g/umol) / (cm^2/m^2) = mol/m^2/s H2O
    #     # ? * (1/m^2) * (hour/3600s) * (umol/g) * (m^2/cm^2) = mol/m^2/s H2O
    #     # ?(g / hour) * (hour/3600s) * (umol/g) / cm^2
    #     s = ws * PD / 3600 / ww / LAI
    #     iszero(LAI) ? zero(s) : s
    # end ~ track(u"mol/m^2/s" #= H2O =#)

    A_gross(a=sunlit_gasexchange.A_gross_total, b=shaded_gasexchange.A_gross_total): gross_CO2_umol_per_m2_s => begin
        a + b
    end ~ track(u"μmol/m^2/s" #= CO2 =#)

    A_net(a=sunlit_gasexchange.A_net_total, b=shaded_gasexchange.A_net_total): net_CO2_umol_per_m2_s => begin
        a + b
    end ~ track(u"μmol/m^2/s" #= CO2 =#)

    # Canopy transpiration (sunlit + shaded)
    ET(a=sunlit_gasexchange.E_total, b=shaded_gasexchange.E_total): transpiration_H2O_mol_per_m2_s => begin
        a + b
    end ~ track(u"mmol/m^2/s" #= H2O =#)

    CO2_weight => 44.0098 ~ preserve(u"g/mol")
    C_weight => 12.0107 ~ preserve(u"g/mol")
    CH2O_weight => 30.031 ~ preserve(u"g/mol")
    H2O_weight => 18.01528 ~ preserve(u"g/mol")
    
    GPP(A_gross, w=CH2O_weight) => begin
        # grams carbo per plant per hour
        #FIXME check unit conversion between C/CO2 to CH2O
        A_gross * w
    end ~ track(u"kg/ha/hr")

    NPP(A_net, w=CH2O_weight) => begin
        # grams carbo per plant per hour
        #FIXME check unit conversion between C/CO2 to CH2O
        A_net * w
    end ~ track(u"kg/ha/hr")

    # Canopy transpiration
    transpiration(ET, w=H2O_weight) => begin
        # Units of Transpiration from sunlit->ET are mol m-2 (leaf area) s-1
        # Calculation of transpiration from ET involves the conversion to gr per plant per hour
        ET * w
    end ~ track(u"kg/ha/hr")

    # Canopy conductance
    conductance(gs_sun=sunlit_gasexchange.gs, LAI_sunlit, gs_sh=shaded_gasexchange.gs, LAI_shaded, LAI) => begin
        #HACK ensure 0 when one of either LAI is 0, i.e., night
        # average stomatal conductance Yang
        c = ((gs_sun * LAI_sunlit) + (gs_sh * LAI_shaded)) / LAI
        #c = max(zero(c), c)
        iszero(LAI) ? zero(c) : c
    end ~ track(u"mol/m^2/s/bar")
end