"""
This system keeps track of soil water balance.
"""
@system WaterBalance begin
    # "Initial available soil water"
    # iASW ~ preserve(parameter, u"mm")

    # "Maximum available soil water"
    # maxASW ~ preserve(parameter, u"mm")
    
    # "Minimum available soil water"
    # minASW ~ preserve(parameter, u"mm")

    # # TODO
    # # "Irrigation"
    # # irrigation ~ preserve(parameter, u"mm/d")

    # "Fraction of excess water pooled"
    # poolFractn ~ preserve(parameter)

    # "Maximum propotion of rainfall evaporated from canopy"
    # maxIntcptn ~ preserve(parameter)

    # "LAI for maximum rainfall interception"
    # LAImaxIntcptn ~ preserve(parameter)

    # "Minimum canopy conductance"
    # minCond ~ preserve(parameter, u"m/s")
    
    # "Maximum canopy conductance"
    # maxCond ~ preserve(parameter, u"m/s")
    
    # "LAI for maximum canopy conductance"
    # LAIgcx ~ preserve(parameter)
    
    # "Canopy boundary layer conductance"
    # BLcond ~ preserve(parameter, u"m/s")

    # # ASW and MaxASW and pool in mm/d
    # ASWhour(ASW) => ASW / u"d" ~ track(u"mm/d")
    # maxASWhour(maxASW) => maxASW / u"d" ~ track(u"mm/d")
    # poolDay(pool) => pool / u"d" ~ track(u"mm/d")
    
    # # Conductance modifier (ambient CO2)
    # fCg(fCg0, CO2) => fCg0 / (1 + (fCg0 - 1) * CO2 / 350) ~ track 
    
    # # Canopy conductance
    # cond(LAI, LAIgcx, minCond, maxCond) => minCond + (maxCond - minCond) * LAI / LAIgcx ~ track(u"m/s", max=maxCond)
    # canCond(cond, fPhysiology, fCg) => cond * fPhysiology * fCg ~ track(u"m/s")

    # # Constants in the Penman-Monteith formula (Landsberg & Gower, 1997)
    # e20 => 2.2 ~ preserve # Rate of change of saturated VP with T at 20C
    # rhoAir => 1.2 ~ preserve(u"kg/m^3") # Density of air
    # lambda => 2460000 ~ preserve(u"J/kg") # Latent heat of vaporization of H2O
    # VPDconv => 0.000622 ~ preserve(u"mbar^-1") # Convert VPD to saturation deficit
    
    # # Radiation in W/m^2
    # netRad(Qa, Qb, rad, daylength) => begin
    #     Qa + Qb * (rad / (daylength))
    # end ~ track(u"W/m^2")
        
    # # defTerm (?)
    # defTerm(rhoAir, lambda, VPDconv, VPD, BLcond) => begin
    #     rhoAir * lambda * (VPDconv * VPD) * BLcond
    # end ~ track(u"W/m^2")
        
    # # div (?)
    # div(e20, BLcond, canCond) => begin
    #     canCond * (1 + e20) + BLcond
    # end ~ track(u"m/s")
     
    # # eTransp (?)
    # eTransp(canCond, e20, netRad, defTerm, div) => begin
    #     canCond * (e20 * netRad + defTerm) / div 
    # end ~ track(u"J/s/m^2")
    
    # # Canopy transpiration
    # canTransp(eTransp, lambda, daylength) => begin
    #     eTransp / lambda * daylength * 1u"cm^3/g" # Water density
    # end ~ track(u"mm/d")
            
    # # Intercepted rainfall ratio
    # intcptn(maxIntcptn, LAI, LAImaxIntcptn) => begin
    #     (LAImaxIntcptn == 0) ? (maxIntcptn) : (maxIntcptn * min(1, LAI / LAImaxIntcptn))
    # end ~ track

    # # Intercepted rainfall
    # rainIntcptn(intcptn, rain) => intcptn * rain ~ track(u"mm/d")
      
    # # Canopy evapotranspiration
    # evapTransp(canTransp, rainIntcptn) => begin
    #     canTransp + rainIntcptn
    # end ~ track(u"mm/d", max=ASWday)
    
    # excessSW(ASWday, maxASWday, evapTransp, irrigation, rain) => begin
    #     ASWday + rain - evapTransp + irrigation - maxASWday
    # end ~ track(u"mm/d", min=0u"mm/d")
    
    # lossPool(ASWday, maxASWday, evapTransp, irrigation, rain, poolDay) => begin
    #     maxASWday - (ASWday - evapTransp + irrigation + rain + poolDay)
    # end ~ track(u"mm/d", min=0u"mm/d", max=poolDay)
    
    # gainPool(excessSW, poolFractn) => begin
    #     poolFractn * excessSW
    # end ~ track(u"mm/d", min=0u"mm/d")
    
    # # Daily change in water pool
    # dPool(gainPool, lossPool) => gainPool - lossPool ~ track(u"mm/d")
    
    # # Daily runoff
    # dRunoff(poolFractn, excessSW) => begin
    #     (1 - poolFractn) * excessSW
    # end ~ track(u"mm/d")
    
    # # Daily change in available soil water
    # dASW(dPool, evapTransp, irrigation, rain) => begin
    #      -dPool - evapTransp + irrigation + rain
    # end ~ track(u"mm/d")
    
    # # GPP modifier in case not enough moisture in soil
    # transpScaleFactor(evapTransp, canTransp, rainIntcptn) => begin
    #     evapTransp / (canTransp + rainIntcptn)
    # end ~ track
    
    # ASW(dASW) ~ accumulate(u"mm", init=iASW, min=minASW, max=maxASW)
    # pool(dPool) ~ accumulate(u"mm")
    # runoff(dRunoff) ~ accumulate(u"mm")
end