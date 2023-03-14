@system Phenology begin
    # Calendar variable to reference date
    calendar(context) ~ ::Calendar
    
    "Initial age"
    iAge => 1 ~ preserve(parameter) # Initial age 

    # Age modifier
    "Maximum stand age used in age modifier"
    maxAge => 50 ~ preserve(parameter)
    
    "Power of relative age in function for fAge"
    nAge => 4 ~ preserve(parameter)
    
    "Relative age to give fAge = 0.5"
    rAge => 0.95 ~ preserve(parameter)

    "Age at canopy cover"
    fullCanAge => 3 ~ preserve(parameter)

    flagAge(nAge) => nAge != 0 ~ flag
    fAge(standAge, maxAge, rAge, nAge) => (1 / (1 + (standAge / maxAge / rAge) ^ nAge)) ~ track(when=flagAge, init=1)

    # Stand age in days and years
    standAgeHour => 1 ~ accumulate::Int64(init=iAge, timeunit=u"hr")
    standAge(calendar, standAgeHour) => standAgeHour / (24 * daysinyear(calendar.date')) ~ track
end