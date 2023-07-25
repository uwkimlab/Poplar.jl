@system Storage begin

    PCNSR(WTNSR, WSRI) => WRNSR / WSRI ~ track(u"percent")

    "Mobile CH2O concentration of storage"
    PCHOSRF => 0.040 ~ preserve(parameter)

    dWSR ~ track
    WSR(dWSR) ~ accumulate
end