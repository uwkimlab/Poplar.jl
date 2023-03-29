"""
This system calculate age and stress related mortality.
"""
@system Mortality begin

    #=========
    Parameters
    ==========#
    "Mortality rate for large t"
    gammaN1 => 0 ~ preserve(parameter)
    
    "Seedling mortality rate (t=0)"
    gammaN0 => 0 ~ preserve(parameter)
    
    "Age at which mortality rate has median value"
    tgammaN => 0 ~ preserve(parameter)
    
    "Shape of mortality response"
    ngammaN => 1 ~ preserve(parameter)
    
    "Max. stem mass per tree at 1000 trees/hectare"
    wSx1000 => 200 ~ preserve(parameter, u"kg")
    
    "Power in self-thinning rule"
    thinPower => 1.5 ~ preserve(parameter)
    
    "Fraction mean single-tree foliage biomass lost per dead tree"
    mF => 0 ~ preserve(parameter)
    
    "Fraction mean single-tree root biomass lost per dead tree"
    mR => 0.2 ~ preserve(parameter)
    
    "Fraction mean single-tree stem biomass lost per dead tree"
    mS => 0.2 ~ preserve(parameter)

    #=====================
    Age & Stress Mortality
    =====================#
    "Mortality rate (yearly)"
    gammaNyear(standAge, gammaN0, gammaN1, tgammaN, ngammaN) => begin
        gammaN1 + (gammaN0 - gammaN1) * exp(-log(2) * (standAge / tgammaN) ^ ngammaN)
    end ~ track
    
    "Mortality rate (daily)"
    gammaNhour(date, gammaNyear) => begin
        (1 - (1 - gammaNyear)^(1 / daysinyear(date) / 24)) / u"hr"
    end ~ track(u"hr^-1")
    
    "Mortality flag"
    flagMortal(gammaNhour) => gammaNhour > 0u"hr^-1" ~ flag

    "Age & stress-related mortality rate (hourly)"
    asMortality(gammaNhour, stemNo) => gammaNhour * stemNo ~ track(u"ha^-1/hr", when=flagMortal)

    #============
    Self-thinning
    ============#
    "Accuracy of Newton-Raphson method"
    accuracy => 1/1000 ~ preserve

    "Self-thinning rate"
    selfThinning(accuracy, mS, stemNo, WS, wSx1000, thinPower) => begin
        n = stemNo / 1000u"ha^-1"
        x1 = mS * WS / stemNo
        i = 0
        while true
            x2 = wSx1000 * n ^ (1 - thinPower)
            fN = (x2) - (x1 * n) - ((1 - mS) * WS / 1000u"ha^-1")
            dfN = ((1 - thinPower) * x2 / n) - (x1)
            dN = -fN / dfN
            n = n + dN
            i = i + 1
            if abs(dN) <= accuracy || i >= 5
                break
            end
        end
        (stemNo - 1000u"ha^-1" * n) / u"hr"
    end ~ track(u"ha^-1/hr")

    #=======
    Thinning
    =======#
    
    #==========
    Defoliation
    ==========#


    #========
    Mortality
    ========#
    "Tree mortality rate"
    mortality(asMortality, selfThinning) => asMortality + selfThinning ~ track(u"ha^-1/hr", when=flagMortal)
end