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
    poolFractn => ~ preserve(parameter)

    "Maximum propotion of rainfall evaporated from canopy"
    maxIntcptn ~ preserve(parameter)

    "LAI for maximum rainfall interception"
    LAImaxIntcptn ~ preserve(parameter)

    "Proportion of rain intercepted"
    interception(maxIntcptn, LAI, LAImaxIntcptn) => begin
        (LAImaxIntcptn == 0) ? (maxIntcptn) : (maxIntcptn * min(1, LAI / LAImaxIntcptn))
    end ~ track

    "Intercepted rain"
    rainInterception(interception, rain) => interception * rain ~ track(u"mm/hr")
      
    "Canopy transpiration"
    evapotranspiration(transpiration, rainInterception) => begin
        transpiration + rainInterception
    end ~ track(u"mm/hr", max=ASWhour)
    
    "Hourly excess soil water"
    excessSW(ASWhour, maxASWhour, evapotranspiration, irrigation, rain) => begin
        ASWhour + rain + poolHour - evapTransp + irrigation - maxASWhour
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly loss in water pool"
    lossPool(ASWhour, maxASWhour, evapTransp, irrigation, rain, poolHour) => begin
        maxASWhour - (ASWhour - evapTransp + irrigation + rain + poolHour)
    end ~ track(u"mm/hr", min=0u"mm/hr", max=poolHour)
    
    "Hourly gain in water pool"
    gainPool(excessSW, poolFractn) => begin
        poolFractn * excessSW
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly net change in water pool"
    dPool(gainPool, lossPool) => gainPool - lossPool ~ track(u"mm/hr")
    
    "Hourly runoff rate"
    dRunoff(poolFractn, excessSW) => begin
        (1 - poolFractn) * excessSW
    end ~ track(u"mm/hr")
    
    "Hourly change in avilable soi water"
    dASW(dPool, evapTransp#=, irrigation=#, rain) => begin
         -dPool - evapTransp#= + irrigation=# + rain
    end ~ track(u"mm/hr")
    
    "Production modifier for GPP and NPP"
    transpScaleFactor(evapTransp, canTransp, rainIntcptn) => begin
        evapTransp / (canTransp + rainIntcptn)
    end ~ track
    
    ASW(dASW) ~ accumulate(u"mm", init=iASW, min=minASW, max=maxASW)
    pool(dPool) ~ accumulate(u"mm")
    runoff(dRunoff) ~ accumulate(u"mm")

    # ASW and MaxASW and pool in mm/hr
    ASWhour(ASW) => ASW / u"d" ~ track(u"mm/hr")
    maxASWhour(maxASW) => maxASW / u"d" ~ track(u"mm/hr")
    poolHour(pool) => pool / u"d" ~ track(u"mm/hr")
end