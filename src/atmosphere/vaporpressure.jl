@system VaporPressure begin
    # Campbell and Norman (1998), p 41 Saturation vapor pressure in kPa
    a => 0.611 ~ preserve(u"kPa", parameter)
    b => 17.502 ~ preserve(parameter)
    c => 240.97 ~ preserve(parameter) # °C

    es(a, b, c; T(u"°C")): saturation => (t = Cropbox.deunitfy(T); a*exp((b*t)/(c+t))) ~ call(u"kPa")
    ea(es; T(u"°C"), RH(u"percent")): ambient => es(T) * RH ~ call(u"kPa")
    D(es; T(u"°C"), RH(u"percent")): deficit => es(T) * (1 - RH) ~ call(u"kPa")
    RH(es; T(u"°C"), VPD(u"kPa")): relative_humidity => 1 - VPD / es(T) ~ call(u"NoUnits")

    # slope of the sat vapor pressure curve: first order derivative of Es with respect to T
    Δ(es, b, c; T(u"°C")): saturation_slope_delta => (e = es(T); t = Cropbox.deunitfy(T); e*(b*c)/(c+t)^2 / u"K") ~ call(u"kPa/K")
    ss(Δ; T(u"°C"), P(u"kPa")): saturation_slope => Δ(T) / P ~ call(u"K^-1")

    #==============
    VPD Calculation
    ==============#

    "VPD"
    VPD(T_air, RH, D) => D(T_air, RH) ~ track(u"kPa")

    "Vapor pressure saturation slope delta"
    VPD_Δ(T_air, Δ): vapor_pressure_saturation_slope_delta => Δ(T_air) ~ track(u"kPa/K")

    "Vapor pressure saturation slope"
    VPD_s(T_air, P_air, ss): vapor_pressure_saturation_slope => ss(T_air, P_air) ~ track(u"K^-1")
end