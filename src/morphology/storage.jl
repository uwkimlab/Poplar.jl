@system Storage begin
    
    PROSRI => 0.092 ~ preserve(parameter)
    PROSRG => 0.064 ~ preserve(parameter)
    PROSRF => 0.056 ~ preserve(parameter)

    FNINSR(PROSRI) => PROSRI * 0.16 ~ preserve
    FNINSRG(PROSRG) => PROSRG * 0.16 ~ preserve

    "Mobile CH2O concentration of storage"
    PCHOSRF => 0.040 ~ preserve(parameter)

    "Fraction of new storage growth that is mobile C"
    ALPHSR => 0.2 ~ preserve(parameter)

    N_storage_init(iWSR, PROSRG) => iWSR * PROSRG * 0.16 ~ preserve(u"g/m^2")

    N_storage_delta(growth_storage_N, SRNMINE, NSROFF, NADSR) => begin
        growth_storage_N - SRNMINE - NSROFF + NADSR
    end ~ track(u"g/m^2/hr")

    # NSROFF => 0 ~ preserve(u"g/m^2/hr")
    # CSROFF => 0 ~ preserve(u"g/m^2/hr")

    N_storage(N_storage_delta) ~ accumulate(u"g/m^2", init=N_storage_init)

    "N available for mobilization from storage above lower limit of mining"
    WNRSR(N_storage, PROSRF, WSR, WCRSR) => begin
        N_storage - PROSRF * 0.16 * (WSR - WCRSR)
    end ~ track(min=0, u"g/m^2")

    WCRSRDT(growth_storage, ALPHSR, CMINESR, CSROFF, CADSR) => begin
        growth_storage * ALPHSR - CMINESR - CSROFF + CADSR
    end ~ track(u"g/m^2/hr")

    WCRSRi(ALPHSR, WSR) => ALPHSR * WSR ~ preserve(u"g/m^2")

    WCRSR(WCRSRDT) ~ accumulate(u"g/m^2", init=WCRSRi)

    NADSR => 0 ~ track(u"g/m^2/hr")

    CADSR => 0 ~ track(u"g/m^2/hr")

    "Percent N in storage"
    PCNSR(N_storage, WSR) => N_storage / WSR ~ track(u"percent")

    "Percent CH2O in storage"
    RHOSR(WCRSR, WSR) => WCRSR / WSR ~ track(u"percent")

    iWSR => 200 ~ preserve(u"kg/ha", parameter)
    dWSR(growth_storage, senescence_storage) => growth_storage - senescence_storage ~ track(u"kg/ha/hr")
    WSR(dWSR) ~ accumulate(u"kg/ha", init=iWSR, min=0)
end