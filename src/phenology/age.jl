@system Age begin

    #=========
    Parameters
    =========#

    "Initial age" # In years. Unreasonable to define initial age in hours.
    iAge => 1 ~ preserve(parameter, u"yr") # Initial age 

    "Maximum physiological age (check fAge for equation)"
    maxAge => 50 ~ preserve(parameter)
    
    "Power of relative age in function for fAge (check fAge for equation)"
    nAge => 4 ~ preserve(parameter)
    
    "Relative age to give fAge = 0.5 (check fAge for equation)"
    rAge => 0.95 ~ preserve(parameter)
    
    #==
    Age
    ==#

    # flag to check if nAge is 0. If nAge is 0, fAge is 1.
    flagAge(nAge) => nAge != 0 ~ flag

    # Keeps track of stand age in hours.
    "Stand age (hours)"
    standAgeHour ~ advance(u"hr", init=iAge)

    # Age-related equations from 3PG use age in years.
    "Stand age (years)"
    standAgeYear(standAgeHour) ~ track(u"yr")

    # Stand age without units due to empirical formulas conflicting with units.
    "Stand age"
    standAge(nounit(standAgeYear)) ~ track

    # Empirical age-based modifier for physiology.
    # Used in another modifier variable, fPhysiology.
    "Age-based physiological modifier"
    fAge(standAge, maxAge, rAge, nAge) => begin
        (1 / (1 + (standAge / maxAge / rAge) ^ nAge)) 
    end ~ track(when=flagAge, init=1)
end