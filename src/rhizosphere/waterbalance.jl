"""
This system keeps track of soil water balance.
"""
@system WaterBalance begin
    "Initial available soil water"
    iASW ~ preserve(parameter, u"mm")

    "Maximum available soil water"
    maxASW ~ preserve(parameter, u"mm")
    
    "Minimum available soil water"
    minASW ~ preserve(parameter, u"mm")

    "Irrigation"
    irrigation => 0 ~ preserve(parameter, u"mm/hr")

    "Fraction of excess water pooled"
    poolFractn ~ preserve(parameter)

    "Maximum propotion of rainfall evaporated from canopy"
    maxIntcptn ~ preserve(parameter)

    "LAI for maximum rainfall interception"
    LAImaxIntcptn ~ preserve(parameter)

    "Minimum canopy conductance"
    minCond ~ preserve(parameter, u"m/s")
    
    "Maximum canopy conductance"
    maxCond ~ preserve(parameter, u"m/s")
    
    "LAI for maximum canopy conductance"
    LAIgcx ~ preserve(parameter)

    # ASW and MaxASW and pool in mm/d
    ASWhour(ASW) => ASW / u"d" ~ track(u"mm/d")
    maxASWhour(maxASW) => maxASW / u"d" ~ track(u"mm/d")
    poolHour(pool) => pool / u"d" ~ track(u"mm/d")
            
    # Intercepted rainfall ratio
    interception(maxIntcptn, LAI, LAImaxIntcptn) => begin
        (LAImaxIntcptn == 0) ? (maxIntcptn) : (maxIntcptn * min(1, LAI / LAImaxIntcptn))
    end ~ track

    # Intercepted rainfall
    rainInterception(intcptn, rain) => intcptn * rain ~ track(u"mm/hr")
      
    # Canopy evapotranspiration
    evapTransp(canTransp, rainIntcptn) => begin
        canTransp + rainIntcptn
    end ~ track(u"mm/d", max=ASWday)
    
    excessSW(ASWday, maxASWday, evapTransp, irrigation, rain) => begin
        ASWday + rain - evapTransp + irrigation - maxASWday
    end ~ track(u"mm/d", min=0u"mm/d")
    
    lossPool(ASWday, maxASWday, evapTransp, irrigation, rain, poolDay) => begin
        maxASWday - (ASWday - evapTransp + irrigation + rain + poolDay)
    end ~ track(u"mm/d", min=0u"mm/d", max=poolDay)
    
    gainPool(excessSW, poolFractn) => begin
        poolFractn * excessSW
    end ~ track(u"mm/d", min=0u"mm/d")
    
    # Daily change in water pool
    dPool(gainPool, lossPool) => gainPool - lossPool ~ track(u"mm/d")
    
    # Daily runoff
    dRunoff(poolFractn, excessSW) => begin
        (1 - poolFractn) * excessSW
    end ~ track(u"mm/d")
    
    # Daily change in available soil water
    dASW(dPool, evapTransp#=, irrigation=#, rain) => begin
         -dPool - evapTransp#= + irrigation=# + rain
    end ~ track(u"mm/hr")
    
    # evapTransp has a max
    transpScaleFactor(evapTransp, canTransp, rainIntcptn) => begin
        evapTransp / (canTransp + rainIntcptn)
    end ~ track
    
    # ASW(dASW) ~ accumulate(u"mm", init=iASW, min=minASW, max=maxASW)
    # pool(dPool) ~ accumulate(u"mm")
    # runoff(dRunoff) ~ accumulate(u"mm")
end