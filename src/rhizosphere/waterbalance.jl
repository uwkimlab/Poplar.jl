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

    # Addition of soil depth multiplier -- CC (8/24/2026)
    reference_depth => 1 ~ preserve(parameter, u"m") # Assumued depth from soil parameter source
    soil_depth => 2 ~ preserve(parameter, u"m") # Poplar rooting depth; soil depth for water balance

    depth_multiplier(reference_depth, soil_depth) => begin
        soil_depth/reference_depth
    end ~ preserve

    ### Soil parameters based on reference depth ### 
    soil_saturation(soil_table,soil_class, depth) => begin 
        soil_table[Symbol(soil_class)].saturation
    end ~ preserve(parameter, u"mm")

    field_capacity(soil_table,soil_class) => begin     	
        soil_table[Symbol(soil_class)].field_capacity
    end ~ preserve(parameter, u"mm")

    wilting_point(soil_table,soil_class) => begin
        soil_table[Symbol(soil_class)].wilting_point
    end ~ preserve(parameter, u"mm")

    minimum_soil_water(soil_table,soil_class) => begin
        soil_table[Symbol(soil_class)].wilting_point
    end ~ preserve(parameter, u"mm")

    ### Soil parameters based on actual soil depth ###
    "Maximum soil water/saturation"
    maxSW(soil_saturation, depth_multiplier) => begin
        soil_saturation * depth_multiplier
    end ~ preserve(u"mm")
 
    "Field capacity" 
    FC(field_capacity, depth_multiplier) => begin
        field_capacity * depth_multiplier
    end ~ preserve(u"mm")
 
    "Wilting point"
    WP(wilting_point, depth_multiplier) => begin
        wilting_point * depth_multiplier
    end ~ preserve(u"mm")

    "Minimum soil water"
    minSW(minimum_soil_water, depth_multiplier) => begin
        minimum_soil_water * depth_multiplier
    end ~ preserve(u"mm") 

    ### other parameters ###

    "Soil water constant"
    cθ(soil_table, soil_class) => begin
        soil_table[Symbol(soil_class)].cθ
    end ~ preserve(parameter)

    "Soil water power"
    nθ(soil_table, soil_class) => begin
        soil_table[Symbol(soil_class)].nθ
    end ~ preserve(parameter)

    "Fraction of excess water pooled"
    pool_fraction => 0 ~ preserve(parameter)

    "Maximum propotion of rainfall evaporated from canopy"
    maxInterception => 0.15 ~ preserve(parameter) # Sands

    "LAI for maximum rainfall interception"
    LAImaxInterception => 0 ~ preserve(parameter) # Sands

    "Daily drainage proportion"
    DRp: daily_drainage => 0.1 ~ preserve(parameter, u"cm^3/cm^3/d")

    #=== Replaced with cθ and nθ from soil table -- 4/28/26 CC ===
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
    ==============================================================#
    # fc => 0.5 ~ preserve(parameter) # not used

    "Proportion of rain intercepted"
    interception(LAI, maxInterception, LAImaxInterception) => begin
        (LAImaxInterception == 0) ? (maxInterception) : (maxInterception * min(1, LAI / LAImaxInterception))
    end ~ track

    "Intercepted rain"
    rainInterception(interception, rain) => interception * rain ~ track(u"mm/hr")

    "Drainage rate"
    drainage(SW, FC, DRp) => begin
        (SW - FC) * DRp
    end ~ track(u"mm/hr", min=0)

    "Excess rain and irrigation after transpiration"
    excessInput(rain, rainInterception, irrigation, transpiration, drainage) => begin
        rain - rainInterception + irrigation - transpiration - drainage
    end ~ track(u"mm/hr", min=0)
    
    # Changed to sigmoidal -- modeling meeting 5/1/26
    "Soil surface evaporation modifier"
    beta(rθ_def, cθ, nθ) => begin
        1 / (1 + ((1 - rθ_def) / cθ)^nθ) 
    end ~ track

    "Soil surface evaporation"
    surface_evaporation(potential_surface_evaporation, beta, excessInput) => begin
        if excessInput > potential_surface_evaporation
            potential_surface_evaporation
        else
            excessInput + beta * (potential_surface_evaporation - excessInput)
        end
    end ~ track(u"mm/hr", max=potential_surface_evaporation)
      
    "Canopy evapotranspiration"
    evapotranspiration(transpiration, rainInterception, surface_evaporation) => begin
        transpiration + rainInterception + surface_evaporation
    end ~ track(u"mm/hr", max=SWhour)

    "Potential canopy evapotranspiration"
    potential_evapotranspiration(transpiration, rainInterception, surface_evaporation) => begin
        transpiration + rainInterception + surface_evaporation
    end ~ track(u"mm/hr")
    
    "Hourly excess soil water"
    excessSW(SWhour, maxSWhour, evapotranspiration, irrigation, rain, poolHour, drainage) => begin
        SWhour + rain + poolHour - evapotranspiration + irrigation - drainage - maxSWhour
    end ~ track(u"mm/hr", min=0u"mm/hr")
    
    "Hourly loss in water pool"
    lossPool(SWhour, maxSWhour, evapotranspiration, irrigation, rain, poolHour, drainage) => begin
        maxSWhour - (SWhour - evapotranspiration + irrigation + rain + poolHour - drainage)
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
    
    "Hourly net change in soil water content"
    dSW(dPool, evapotranspiration, irrigation, rain, drainage) => begin
         -dPool - evapotranspiration - drainage + irrigation + rain
    end ~ track(u"mm/hr")
    
    flag_transpiration(transpiration) => transpiration > 0u"mm/hr" ~ flag

    #=== Not used -- 5/1/26 CC ===
    "Production modifier for GPP"
    transpScaleFactor(evapotranspiration, potential_evapotranspiration) => begin
        evapotranspiration / potential_evapotranspiration
    end ~ track(when=flag_transpiration, init=1)
    =============================#
    
    "Soil water content"
    SW(dSW) ~ accumulate(u"mm", init=iSW, min=minSW, max=maxSW)

    pool(dPool) ~ accumulate(u"mm")

    runoff(dRunoff) ~ accumulate(u"mm")

    # ASW and MaxASW and pool in mm/hr
    SWhour(SW) => SW / u"d" ~ track(u"mm/hr")
    maxSWhour(maxSW) => maxSW / u"d" ~ track(u"mm/hr")
    poolHour(pool) => pool / u"d" ~ track(u"mm/hr")

    #=== CC (8/24/2026) ================
    not necessary to include
    "Volumetric water content"
    VWC(SW, soil_depth) => begin
        SW / soil_depth
    end ~ track
    ===================================#

    #=== NOT USED -- 5/1/26 CC ===
    "Irrigation based on profiling VWC for Slit Loam"
    SLs => 0.486 ~ preserve(parameter) # Silt Loam - Saturated volumetric water content
    SLr => 0.05 ~ preserve(parameter) # Silt Loam - Residual volumetric water content

    "Calculate related water content"
    RWC(SLs, SLr, VWC) => begin
        (VWC - SLr) / (SLs - SLr)
    end ~ track

    "Field capacity as VWC"
    FC => 0.330 ~ preserve(parameter) # Field capacity for Slit Loam
    FC(field_capacity, soil_depth) => begin 
       (field_capacity / soil_depth) 
    end~ track

    "wilting point as VWC"
    WP => 0.133 ~ preserve(parameter) # Wilting point for Slit Loam
    WP(wilting_point, soil_depth) => begin 
       (field_capacity / soil_depth) 
    end~ track
    =============================#

    "Irrigation control parameters"
    irrigation_start_level => 1 ~ preserve(parameter) # as percent of ASW + WP
    irrigation_end_level => 1 ~ preserve(parameter) # as percent of ASW + WP
    irrigation_rate => 0.5 ~ preserve(parameter, u"mm/hr") # Irrigation rate mm/hr

    ### changed irrigation start/end/flag from VWC to mm
    irrigation_start(irrigation_start_level, FC, WP) => begin
        (irrigation_start_level * (FC - WP) + WP)
    end ~ preserve(parameter, u"mm") # Irrigation start point in mm 
    
    irrigation_end(irrigation_end_level, FC, WP) => begin
        (irrigation_end_level * (FC - WP) + WP)
    end ~ preserve(parameter, u"mm") # Irrigation end point in mm  
    
    "Update irrigation status based on VWC"
    flag_irrigation(SW, irrigation_start, irrigation_end, flag_irrigation) => begin
        (SW < irrigation_start) || (SW < irrigation_end && flag_irrigation)
    end ~ flag

    irrigation_cut_date ~ preserve::ZonedDateTime(parameter, optional)
    
    flag_irrigation_date(irrigation_cut_date, time) => begin
        if isnothing(irrigation_cut_date)
            true
        else
            time < irrigation_cut_date
        end
    end ~ flag
    
    irrigation(irrigation_rate, flag_irrigation, flag_irrigation_date, dormant) => begin
        if flag_irrigation & flag_irrigation_date & !dormant
            irrigation_rate
        else
            0
        end
    end ~ track(u"mm/hr")

    # scales water stress from excess water - waterlogging tolerant (0) to sensitive (1)
    wls: waterlogging_sensitivity => 0 ~ preserve(parameter, min=0, max=1)
    
    "Relative soil water saturation"
    rθ_sat(SW, maxSW, FC, wls) => begin
        1.0 - ((SW - FC) / (maxSW - FC)) * wls
    end ~ track(max=1)

    "Relative soil water deficit"
    rθ_def(SW, WP, FC) => begin
        (SW - WP) / (FC - WP)
    end ~ track(max=1)

    # Relative drought factor from CROPGRO. Used for N_uptake_conversion_factor.
    # Captures water stress due to both drought and water logging through reduction in stomatal conductance
    "Relative soil water content factor"
    rθ(SW, FC, rθ_sat, rθ_def) => begin
        SW > FC ? rθ_sat : rθ_def
    end ~ track(min=0.1, max=1)
    # rθ(SW, minSW, FC, maxSW, WP, wls) => begin
    #     if SW > FC
    #         1.0 - ((SW - FC) / (maxSW - FC)) * wls
    #     else
    #         1 * ((SW - WP) / (FC - WP))
    #     end
    # end ~ track(min=0.1, max=1)

    # fθ from 3PG with additional water logging effect
    # cθ and nθ shift curves for differnt soil types, reflecting hydraulic properties (Landsberg & Waring, 1997)
    "Relative soil water stress factor"
    water_stress(rθ, cθ, nθ) => begin
        1 / (1 + ((1 - rθ) / cθ)^nθ)
    end ~ track
        
    # annual cumulative water usage for comparing WUE
    IR_ac(irrigation) ~ accumulate(u"L/ha")
    # IR_annual(IR_ac) ~ remember(when=dormant, u"L/ha")
    T_ac(transpiration) ~ accumulate(u"L/ha")
    # T_annual(T_ac) ~ remember(when=dormant, u"L/ha")
    ET_ac(evapotranspiration) ~ accumulate(u"L/ha")
    # ET_annual(ET_ac) ~ remember(when=dormant, u"L/ha")
    rain_ac(rain) ~ accumulate(u"L/ha")
    waterIn_ac(rain, irrigation) => begin
        rain + irrigation
    end ~ accumulate(u"L/ha")
    
end

