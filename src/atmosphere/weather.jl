@system Weather begin
    #=========
    Parameters
    =========#

    # DataFrame containing all hourly weather data should be
    # assigned to this variable during configuration.
    "Data"
    data ~ provide(init=time, parameter)

    "Ambient CO2"
    CO2 => 400 ~ preserve(u"μmol/mol", parameter)

    "Air pressure (kPa)"
    P_air: air_pressure => 100 ~ preserve(parameter, u"kPa")

    #================
    Weather Variables
    ================#

    "Solar Radiation"
    solrad: solar_radiation ~ drive(from=data, by=:SolRad, u"W/m^2")

    "Relative Humidity"
    RH: relative_humidity ~ drive(from=data, by=:RH, u"percent")

    "Air Temperature (°C)"
    T_air: air_temperature ~ drive(from=data, by=:Tair, u"°C")

    "Air Temperature (K)"
    Tk_air(T_air): absolute_air_temperature ~ track(u"K")

    "Wind Speed"
    wind: wind_speed ~ drive(from=data, by=:Wind, u"m/s")

    "Rain"
    rain ~ drive(from=data, by=:Rain, u"mm/hr")
end