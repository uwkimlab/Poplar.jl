"""
This system keeps track of soil water balance.
"""
@system WaterBalance begin
    "Initial available soil water"
    iASW => 1 ~ preserve(parameter, u"mm")

    "Maximum available soil water"
    maxASW => 1 ~ preserve(parameter, u"mm")
    
    "Minimum available soil water"
    minASW => 1 ~ preserve(parameter, u"mm")

    "Irrigation"
    irrigation => 0 ~ preserve(parameter, u"mm/hr")

    "Fraction of excess water pooled"
    poolFraction => 0 ~ preserve(parameter)

    "Maximum propotion of rainfall evaporated from canopy"
    maxInterception ~ preserve(parameter)

    "LAI for maximum rainfall interception"
    LAImaxInterception ~ preserve(parameter)

    "Proportion of rain intercepted"
    interception(LAI, maxInterception, LAImaxInterception) => begin
        (LAImaxInterception == 0) ? (maxInterception) : (maxInterception * min(1, LAI / LAImaxInterception))
    end ~ track

    "Intercepted rain"
    rainInterception(interception, rain) => interception * rain ~ track(u"mm/hr")
      
    "Canopy transpiration"
    evapotranspiration(transpiration, rainInterception) => begin
        transpiration + rainInterception
    end ~ track(u"mm/hr", max=ASWhour)
    
    "Hourly excess soil water"
    excessSW(ASWhour, maxASWhour, evapotranspiration, irrigation, rain) => begin
        ASWhour + rain + poolHour - evapotranspiration + irrigation - maxASWhour
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly loss in water pool"
    lossPool(ASWhour, maxASWhour, evapotranspiration, irrigation, rain, poolHour) => begin
        maxASWhour - (ASWhour - evapotranspiration + irrigation + rain + poolHour)
    end ~ track(u"mm/hr", min=0u"mm/hr", max=poolHour)
    
    "Hourly gain in water pool"
    gainPool(excessSW, poolFraction) => begin
        poolFraction * excessSW
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly net change in water pool"
    dPool(gainPool, lossPool) => gainPool - lossPool ~ track(u"mm/hr")
    
    "Hourly runoff rate"
    dRunoff(poolFraction, excessSW) => begin
        (1 - poolFraction) * excessSW
    end ~ track(u"mm/hr")
    
    "Hourly change in avilable soil water"
    dASW(dPool, evapotranspiration#=, irrigation=#, rain) => begin
         -dPool - evapotranspiration#= + irrigation=# + rain
    end ~ track(u"mm/hr")
    
    "Production modifier for GPP and NPP"
    transpScaleFactor(evapotranspiration, canTransp, rainIntcptn) => begin
        evapotranspiration / (canTransp + rainIntcptn)
    end ~ track
    
    ASW(dASW) ~ accumulate(u"mm", init=iASW, min=minASW, max=maxASW)
    pool(dPool) ~ accumulate(u"mm")
    runoff(dRunoff) ~ accumulate(u"mm")

    # ASW and MaxASW and pool in mm/hr
    ASWhour(ASW) => ASW / u"d" ~ track(u"mm/hr")
    maxASWhour(maxASW) => maxASW / u"d" ~ track(u"mm/hr")
    poolHour(pool) => pool / u"d" ~ track(u"mm/hr")
end
