"""
This system calculate age and stress related mortality.
"""
@system Mortality begin
    "Mortality rate for large t"
    gammaN1 ~ preserve(parameter)
    
    "Seedling mortality rate (t=0)"
    gammaN0 ~ preserve(parameter)
    
    "Age at which mortality rate has median value"
    tgammaN ~ preserve(parameter)
    
    "Shape of mortality response"
    ngammaN ~ preserve(parameter)
    
    "Max. stem mass per tree at 1000 trees/hectare"
    wSx1000 ~ preserve(parameter, u"kg")
    
    "Power in self-thinning rule"
    thinPower ~ preserve(parameter)
    
    "Fraction mean single-tree foliage biomass lost per dead tree"
    mF ~ preserve(parameter)
    
    "Fraction mean single-tree root biomass lost per dead tree"
    mR ~ preserve(parameter)
    
    "Fraction mean single-tree stem biomass lost per dead tree"
    mS ~ preserve(parameter)

    # Thinning
    
    # Defoliation
    
    # Mortality rate (yearly)
    gammaN(standAge, gammaN0, gammaN1, tgammaN, ngammaN) => begin
        gammaN1 + (gammaN0 - gammaN1) * exp(-log(2) * (standAge / tgammaN) ^ ngammaN)
    end ~ track
    
    # Mortality rate (daily)
    gammaNhour(calendar, gammaN) => begin
        (1 - (1 - gammaN)^(1 / daysinyear(calendar.date') / 24)) / u"hr"
    end ~ track(u"hr^-1")
    
    # Mortality flag
    flagMortal(gammaNhour) => gammaNhour > 0u"hr^-1" ~ flag
    
    # Dead trees per hectare per day
    mortality(gammaNhour, stemNo) => gammaNhour * stemNo ~ track(u"ha^-1/hr", when=flagMortal)
end