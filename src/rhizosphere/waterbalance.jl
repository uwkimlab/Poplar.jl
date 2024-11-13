"""
`WaterBalance` keeps track of soil water balance.
Transpiration
"""
@system WaterBalance begin

    #=========
    Parameters
    =========#

    "Initial available soil water"
    iASW => 200 ~ preserve(parameter, u"mm")

    "Maximum available soil water"
    maxASW => 200 ~ preserve(parameter, u"mm")
    
    "Minimum available soil water"
    minASW => 0 ~ preserve(parameter, u"mm")

    "Irrigation"
    irrigation => 0 ~ preserve(parameter, u"mm/hr")

    "Fraction of excess water pooled"
    pool_fraction => 0 ~ preserve(parameter)

    "Maximum propotion of rainfall evaporated from canopy"
    maxInterception => 0.15 ~ preserve(parameter) # Sands

    "LAI for maximum rainfall interception"
    LAImaxInterception => 0 ~ preserve(parameter) # Sands

    # "Moisture ratio deficit for fTheta = 0.5"
    # SWconst0 => 0.7 ~ preserve(parameter)
    
    # SWconst(soil_class, SWconst0) => begin
    #     ((Int(soil_class) > 0) ? (0.8 - 0.1 * Int(soil_class)) : (SWconst0)) 
    # end ~ preserve

    # "Power of moisture ratio deficit"
    # SWpower0 => 9 ~ preserve(parameter)
    
    # SWpower(soil_class, SWpower0) => begin
    #     ((Int(soil_class) > 0) ? (11 - 2 * Int(soil_class)) : (SWpower0))
    # end ~ preserve

    fc => 0.5 ~ preserve(parameter)
    field_capacity(fc, maxASW) => fc * (maxASW + minASW) ~ preserve(u"mm")

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
    excessSW(ASWhour, maxASWhour, evapotranspiration, irrigation, rain, poolHour) => begin
        ASWhour + rain + poolHour - evapotranspiration + irrigation - maxASWhour
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly loss in water pool"
    lossPool(ASWhour, maxASWhour, evapotranspiration, irrigation, rain, poolHour) => begin
        maxASWhour - (ASWhour - evapotranspiration + irrigation + rain + poolHour)
    end ~ track(u"mm/hr", min=0u"mm/hr", max=poolHour)
    
    "Hourly gain in water pool"
    gainPool(excessSW, pool_fraction) => begin
        pool_fraction * excessSW
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly net change in water pool"
    dPool(gainPool, lossPool) => gainPool - lossPool ~ track(u"mm/hr")
    
    "Hourly runoff rate"
    dRunoff(pool_fraction, excessSW) => begin
        (1 - pool_fraction) * excessSW
    end ~ track(u"mm/hr")
    
    "Hourly change in avilable soil water"
    dASW(dPool, evapotranspiration#=, irrigation=#, rain) => begin
         -dPool - evapotranspiration#= + irrigation=# + rain
    end ~ track(u"mm/hr")
    
    flag_transpiration(transpiration) => transpiration > 0u"mm/hr" ~ flag

    "Production modifier for GPP"
    transpScaleFactor(evapotranspiration, transpiration, rainInterception) => begin
        evapotranspiration / (transpiration + rainInterception)
    end ~ track(when=flag_transpiration, init=1)
    
    ASW(dASW) ~ accumulate(u"mm", init=iASW, min=minASW, max=maxASW)
    pool(dPool) ~ accumulate(u"mm")
    runoff(dRunoff) ~ accumulate(u"mm")

    # ASW and MaxASW and pool in mm/hr
    ASWhour(ASW) => ASW / u"d" ~ track(u"mm/hr")
    maxASWhour(maxASW) => maxASW / u"d" ~ track(u"mm/hr")
    poolHour(pool) => pool / u"d" ~ track(u"mm/hr")
end
