@system Weather begin
    #=========
    Parameters
    =========#

    "Dataframe"
    data ~ provide(init=time, parameter)

    "Ambient CO2"
    CO2 => 400 ~ preserve(u"μmol/mol", parameter)

    "Air pressure (kPa)"
    P_air: air_pressure => 100 ~ preserve(parameter, u"kPa")

    "Stomatal response to VPD"
    coeffCond => 0.05 ~ preserve(parameter, u"mbar^-1")

    #================
    Weather Variables
    ================#

    solrad: solar_radiation ~ drive(from=data, by=:SolRad, u"W/m^2")

    RH: relative_humidity ~ drive(from=data, by=:RH, u"percent")

    T_air: air_temperature ~ drive(from=data, by=:Tair, u"°C")

    Tk_air(T_air): absolute_air_temperature ~ track(u"K")

    wind: wind_speed ~ drive(from=data, by=:Wind, u"m/s")

    rain ~ drive(from=data, by=:Rain, u"mm/hr")

    #==============
    VPD Calculation
    ==============#

    "VPD"
    VPD(T_air, RH, D) => D(T_air, RH) ~ track(u"kPa")

    "Vapor pressure saturation slope delta"
    VPD_Δ(T_air, Δ): vapor_pressure_saturation_slope_delta => Δ(T_air) ~ track(u"kPa/K")

    "Vapor pressure saturation slope"
    VPD_s(T_air, P_air, ss): vapor_pressure_saturation_slope => ss(T_air, P_air) ~ track(u"K^-1")

    "VPD modifier on root partitioning"
    fVPD(VPD, coeffCond) => begin
        exp(-coeffCond * VPD)
    end ~ track
end