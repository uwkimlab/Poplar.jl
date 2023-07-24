"""
`WaterBalance` keeps track of soil water balance.
"""
@system WaterBalance begin

    #=========
    Parameters
    =========#

    "Initial available soil water"
    ASW_init: available_soil_water_initial => 200 ~ preserve(parameter, u"mm")

    "Maximum available soil water"
    ASW_max => 200 ~ preserve(parameter, u"mm")
    
    "Minimum available soil water"
    ASW_min => 0 ~ preserve(parameter, u"mm")

    "Irrigation"
    irrigation => 0 ~ preserve(parameter, u"mm/hr")

    "Fraction of excess water pooled"
    pool_fraction => 0 ~ preserve(parameter)

    "Maximum propotion of rainfall evaporated from canopy"
    interception_max => 0.15 ~ preserve(parameter) # Sands

    field_capacity(ASW_max) => 0.5 * ASW_max ~ preserve(u"mm")

    "Proportion of rain intercepted"
    interception(LAI, interception_max, LAI_interception_max) => begin
        (LAI_interception_max == 0) ? (interception_max) : (interception_max * min(1, LAI / LAI_interception_max))
    end ~ track

    "Intercepted rain"
    rain_interception(interception, rain) => interception * rain ~ track(u"mm/hr")
      
    "Canopy transpiration"
    evapotranspiration(transpiration, rain_interception) => begin
        transpiration + rain_interception
    end ~ track(u"mm/hr", max=ASW_hour)
    
    "Hourly excess soil water"
    excessSW(ASW_hour, ASW_hour_max, evapotranspiration, irrigation, rain, pool_hour) => begin
        ASW_hour + rain + pool_hour - evapotranspiration + irrigation - ASW_hour_max
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly loss in water pool"
    pool_loss(ASW_hour, ASW_hour_max, evapotranspiration, irrigation, rain, pool_hour) => begin
        ASW_hour_max - (ASW_hour - evapotranspiration + irrigation + rain + pool_hour)
    end ~ track(u"mm/hr", min=0u"mm/hr", max=pool_hour)
    
    "Hourly gain in water pool"
    pool_gain(excessSW, pool_fraction) => begin
        pool_fraction * excessSW
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly net change in water pool"
    pool_delta(pool_gain, pool_loss) => pool_gain - pool_loss ~ track(u"mm/hr")
    
    "Hourly runoff rate"
    runoff_delta(pool_fraction, excessSW) => begin
        (1 - pool_fraction) * excessSW
    end ~ track(u"mm/hr")
    
    "Hourly change in avilable soil water"
    ASW_delta(pool_delta, evapotranspiration#=, irrigation=#, rain) => begin
         -pool_delta - evapotranspiration#= + irrigation=# + rain
    end ~ track(u"mm/hr")
    
    flag_transpiration(transpiration) => transpiration > 0u"mm/hr" ~ flag

    "Production modifier for GPP"
    transpiration_scale_factor(evapotranspiration, transpiration, rain_interception) => begin
        evapotranspiration / (transpiration + rain_interception)
    end ~ track(when=flag_transpiration, init=1)
    
    ASW(ASW_delta) ~ accumulate(u"mm", init=ASW_init, min=ASW_min, max=ASW_max)
    pool(pool_delta) ~ accumulate(u"mm")
    runoff(runoff_delta) ~ accumulate(u"mm")

    # ASW and ASW_max and pool in mm/hr
    ASW_hour(ASW) => ASW / u"d" ~ track(u"mm/hr")
    ASW_hour_max(ASW_max) => ASW_max / u"d" ~ track(u"mm/hr")
    pool_hour(pool) => pool / u"d" ~ track(u"mm/hr")
end
