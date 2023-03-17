@system Phenology begin
    "Initial age"
    iAge => 1 ~ preserve(parameter, u"yr") # Initial age 

    # Age modifier
    "Maximum stand age used in age modifier"
    maxAge => 50 ~ preserve(parameter, u"yr")
    
    "Power of relative age in function for fAge"
    nAge => 4 ~ preserve(parameter)
    
    "Relative age to give fAge = 0.5"
    rAge => 0.95 ~ preserve(parameter)

    "Age at canopy cover"
    fullCanAge => 0 ~ preserve(parameter)

    flagAge(nAge) => nAge != 0 ~ flag
    fAge(standAge, maxAge, rAge, nAge) => (1 / (1 + (standAge / maxAge / rAge) ^ nAge)) ~ track(when=flagAge, init=1)

    # Stand age in days and years
    standAgeHour => 1 ~ accumulate::Int64(init=iAge, timeunit=u"hr")
    standAge(date, standAgeHour) => standAgeHour / (24 * daysinyear(date')) ~ track
end