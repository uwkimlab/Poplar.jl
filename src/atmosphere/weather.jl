@system Weather begin
    # calendar(context) ~ ::Calendar(override)
    # vp(context): vapor_pressure ~ ::VaporPressure
    
    data ~ provide(init=calendar.time, parameter)

    solrad: solar_radiation ~ drive(from=data, by=:SolRad, u"W/m^2")

    CO2 => 400 ~ preserve(u"μmol/mol", parameter)

    RH: relative_humidity ~ drive(from=data, by=:RH, u"percent")
    #RH => 0.6 ~ track # 0~1

    T_air: air_temperature ~ drive(from=data, by=:Tair, u"°C")
    #T_air => 25 ~ track # C

    Tk_air(T_air): absolute_air_temperature ~ track(u"K")

    wind: wind_speed ~ drive(from=data, by=:Wind, u"m/s")
    #wind => 2.0 ~ track # meters s-1

    #TODO: make P_air parameter?
    P_air: air_pressure => 100 ~ track(u"kPa")

    VPD(T_air, RH, D) => D(T_air, RH) ~ track(u"kPa")
    VPD_Δ(T_air, Δ): vapor_pressure_saturation_slope_delta => Δ(T_air) ~ track(u"kPa/K")
    VPD_s(T_air, P_air, ss): vapor_pressure_saturation_slope => ss(T_air, P_air) ~ track(u"K^-1")

    "Defines stomatal response to VPD"
    coeffCond => 0.05 ~ preserve(parameter, u"mbar^-1")

    fVPD(VPD, coeffCond) => begin
        exp(-coeffCond * VPD)
    end ~ track
end