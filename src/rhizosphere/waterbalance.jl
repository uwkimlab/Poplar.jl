"""
`WaterBalance` keeps track of soil water balance.
Transpiration
"""
@system WaterBalance begin

    #=========
    Parameters
    =========#

    "Initial soil water"
    iSW => 200 ~ preserve(parameter, u"mm")

    "Maximum soil water/saturation"
    soil_saturation => begin 
        soil_table[Symbol(soil_class)].saturation
    end ~ preserve(parameter, u"mm")
    
    "Minimum soil water"
    minSW => begin
        soil_table[Symbol(soil_class)].wilting_point
    end ~ preserve(parameter, u"mm")

    "Wilting point"
    WP(saturation,soil_table,soil_class): wilting_point => begin
        soil_table[Symbol(soil_class)].wilting_point
    end ~ preserve(parameter, u"mm")

    
    # "Irrigation"
    # irrigation => 0 ~ preserve(parameter, u"mm/hr")

#     "Maximum available soil water"
#     maxASW => 200 ~ preserve(parameter, u"mm") # (Field capacity - Wilting point) * depth
#     #maxASW => 200 ~ preserve(parameter, u"mm") # previous
    
#     "Minimum available soil water"
#     minASW => 0 ~ preserve(parameter, u"mm") # need to be updated based on VWC by soil types

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
    #     ((Int(soil_class) > 0) ? (11 - 2 * Int(c)) : (SWpower0))
    # end ~ preserve

    fc => 0.5 ~ preserve(parameter)
    field_capacity(fc, soil_saturation, minSW) => fc * (soil_saturation + minSW) ~ preserve(u"mm")


    "Proportion of rain intercepted"
    interception(LAI, maxInterception, LAImaxInterception) => begin
        (LAImaxInterception == 0) ? (maxInterception) : (maxInterception * min(1, LAI / LAImaxInterception))
    end ~ track

    "Intercepted rain"
    rainInterception(interception, rain) => interception * rain ~ track(u"mm/hr")
      
    "Canopy evapotranspiration" # Looks like missing soil surface evaporation 
    evapotranspiration(transpiration, rainInterception) => begin
        transpiration + rainInterception
    end ~ track(u"mm/hr", max=SWhour)

    "Potential canopy evapotranspiration"
    potential_evapotranspiration(transpiration, rainInterception) => begin
        transpiration + rainInterception
    end ~ track(u"mm/hr")
    
    "Hourly excess soil water"
    excessSW(SWhour, maxSWhour, evapotranspiration, irrigation, rain, poolHour) => begin
        SWhour + rain + poolHour - evapotranspiration + irrigation - maxSWhour
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly loss in water pool"
    lossPool(SWhour, maxSWhour, evapotranspiration, irrigation, rain, poolHour) => begin
        maxSWhour - (SWhour - evapotranspiration + irrigation + rain + poolHour)
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
    
    dSW(dPool, evapotranspiration, irrigation, rain) => begin
         -dPool - evapotranspiration + irrigation + rain
    end ~ track(u"mm/hr")
    
    flag_transpiration(transpiration) => transpiration > 0u"mm/hr" ~ flag

    "Production modifier for GPP"
    transpScaleFactor(evapotranspiration, potential_evapotranspiration) => begin
        evapotranspiration / potential_evapotranspiration
    end ~ track(when=flag_transpiration, init=1)
    
    SW(dSW) ~ accumulate(u"mm", init=iSW, min=minSW, max=soil_saturation)
    pool(dPool) ~ accumulate(u"mm")
    runoff(dRunoff) ~ accumulate(u"mm")

    # ASW and MaxASW and pool in mm/hr
    SWhour(SW) => SW / u"d" ~ track(u"mm/hr")
    maxSWhour(soil_saturation) => soil_saturation / u"d" ~ track(u"mm/hr")
    poolHour(pool) => pool / u"d" ~ track(u"mm/hr")

    "Irrigation based on profiling VWC for Slit Loam"
    soil_depth => 2000 ~ preserve(parameter, u"mm") #Poplar rooting depth; soil depth for water balance
    SLs => 0.486 ~ preserve(parameter) # Silt Loam - Saturated volumetric water content
    SLr => 0.05 ~ preserve(parameter) # Silt Loam - Residual volumetric water content

    VWC(SW, soil_depth) => begin
        SW / soil_depth
    end ~ track(max = SLs)

    "Calculate related water content"
    RWC(SLs, SLr, VWC) => begin
        (VWC - SLr) / (SLs - SLr)
    end ~ track

    # "Field capacity as VWC"
    # FC => 0.330 ~ preserve(parameter) # Field capacity for Slit Loam
    #FC(field_capacity, soil_depth) => begin 
    #    (field_capacity / soil_depth) 
    #end~ track

    # "wilting point as VWC"
    # WP => 0.133 ~ preserve(parameter) # Wilting point for Slit Loam
    #WP(wilting_point, soil_depth) => begin 
    #    (field_capacity / soil_depth) 
    #end~ track

    "Irrigation control parameters"
    irrigation_start(WP, soil_depth) => WP / soil_depth ~ preserve(parameter) # Irrigation start point VWC- wilting point
    irrigation_end(field_capacity, soil_depth) => field_capacity / soil_depth ~ preserve(parameter) # Irrigation end point VWC - field capacity
    irrigation_rate => 0.5 ~ preserve(parameter, u"mm/hr") # Irrigation rate mm/hr

    "Update irrigation status based on VWC"
    irrigation(VWC, irrigation_rate, irrigation_start, irrigation_end) => begin
        if VWC < irrigation_start
            irrigation_rate
        elseif VWC > irrigation_end
            0
        else
            irrigation_rate
        end
    end ~ track(u"mm/hr")
end
