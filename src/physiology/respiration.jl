@system Respiration begin
    # "Respiration required for biological N fixation"
    RFIXN => 2.830 ~ preserve(parameter)

    RCH2O => 1.242 ~ preserve(parameter)
    RLIP => 3.106 ~ preserve(parameter)
    RLIG => 2.174 ~ preserve(parameter)
    ROA => 0.929 ~ preserve(parameter)
    RMIN => 0.05 ~ preserve(parameter)
    PCH20 => 1.13 ~ preserve(parameter)

    PCARLF => 0.406 ~ preserve(parameter)
    PCARST => 0.585 ~ preserve(parameter)
    PCARRT => 0.711 ~ preserve(parameter)

    PLIPLF => 0.022 ~ preserve(parameter)
    PLIPST => 0.009 ~ preserve(parameter)
    PLIPRT => 0.020 ~ preserve(parameter)

    PLIGLF => 0.039 ~ preserve(parameter)
    PLIGST => 0.114 ~ preserve(parameter)
    PLIGRT => 0.070 ~ preserve(parameter)
    
    POALF => 0.050 ~ preserve(parameter)
    POAST => 0.050 ~ preserve(parameter)
    POART => 0.050 ~ preserve(parameter)

    PMINLF => 0.111 ~ preserve(parameter)
    PMINST => 0.048 ~ preserve(parameter)
    PMINRT => 0.057 ~ preserve(parameter)
    
    PROSRI => 0.092 ~ preserve(parameter)
    PROSRG => 0.064 ~ preserve(parameter)
    PROSRF => 0.056 ~ preserve(parameter)

    PCARSR => 0.711 ~ preserve(parameter)
    PLIPSR => 0.020 ~ preserve(parameter)
    PLIGSR => 0.070 ~ preserve(parameter)
    POASR => 0.050 ~ preserve(parameter)
    PMINSR => 0.057 ~ preserve(parameter)

    PROLFR => 0.220 ~ preserve(parameter)
    PROSRT => 0.110 ~ preserve(parameter)
    PRORTR => 0.101 ~ preserve(parameter)
    PROSRR => 0.092 ~ preserve(parameter)

    AGRLF(RLIP, RLIG, ROA, RMIN, RCH2O, PLIPLF, PLIGLF, POALF, PMINLF, PCARLF) => begin
        PLIPLF*RLIP + PLIGLF*RLIG + POALF*ROA + 
        PMINLF*RMIN + PCARLF*RCH2O
    end ~ preserve(parameter)

    AGRSTM(PLIPST, RLIP, PLIGST, RLIG, POAST, ROA, PMINST, RMIN, PCARST, RCH2O) => begin
        PLIPST*RLIP + PLIGST*RLIG + POAST*ROA +
        PMINST*RMIN + PCARST*RCH2O
    end ~ preserve(parameter)

    AGRRT(RLIP, RLIG, ROA, RMIN, RCH2O, PLIPRT, PLIGRT, POART, PMINRT, PCARRT) => begin
        PLIPRT*RLIP + PLIGRT*RLIG + POART*ROA +
        PMINRT*RMIN + PCARRT*RCH2O
    end ~ preserve(parameter)

    "Respiration required for protein synthesis"
    RPROAV(RFIXN) => begin
        RFIXN
        # ((RSPNO3 + RSPNO3) * 0.16 + NFIXN * RFIXN +
        # NMINEA * RPRO) / (N_uptake + )
    end ~ preserve
end