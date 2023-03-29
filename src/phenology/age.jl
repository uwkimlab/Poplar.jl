@system Age begin

    #=========
    Parameters
    =========#

    "Initial age"
    iAge => 1 ~ preserve(parameter, u"yr") # Initial age 

    "Maximum physiological age (determines rate of physiological decline of forest)"
    maxAge => 50 ~ preserve(parameter)
    
    "Power of relative age in function for fAge"
    nAge => 4 ~ preserve(parameter)
    
    "Relative age to give fAge = 0.5"
    rAge => 0.95 ~ preserve(parameter)
    
    #==
    Age
    ==#

    flagAge(nAge) => nAge != 0 ~ flag

    "Physiological modifier based on age"
    fAge(standAge, maxAge, rAge, nAge) => (1 / (1 + (standAge / maxAge / rAge) ^ nAge)) ~ track(when=flagAge, init=1)

    "Stand age (hours)"
    standAgeHour => 1 ~ accumulate::Int64(u"hr", init=iAge)

    "Stand age (years)"
    standAgeYear(standAgeHour) ~ track(u"yr")

    "Stand age"
    standAge(nounit(standAgeYear)) ~ track

    "Age-based physiological modifier"
    fAge(standAge, maxAge, rAge, nAge) => (1 / (1 + (standAge / maxAge / rAge) ^ nAge)) ~ track(when=flagAge, init=1)
end