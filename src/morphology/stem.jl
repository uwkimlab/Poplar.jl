@system Stem begin
    #=========
    Parameters
    =========#


    init_ps =>0.05 ~ preserve(parameter)

    "Initial stem drymass"
    iWS(init_ps,init_weight,iStemNo) => init_weight*init_ps*iStemNo ~ preserve(parameter, u"kg/ha")

    "Stem nitrogen ratio"
    N_ratio_stem => 0.01 ~ preserve(parameter)

    #=====
    Growth
    =====#

    growthStem(NPP, pS) => NPP * pS ~ track(u"kg/ha/hr", when=growthFlag) 

	#=======================
	Respiration from biomass
	=======================#

    mRStem(NPP, Rp, Stem_Rp) => abs(NPP * Stem_Rp / Rp) ~ track(u"kg/ha/hr", when=!growthFlag)
	
    #========
    Mortality
    ========#

    deathStem(WS, mS, mortality, stemNo) => begin
        mS * mortality * (WS / stemNo)
    end ~ track(u"kg/ha/hr", max=WS_lim) #, when=flagMortal) removed flagMortal so selfThinning reduces biomass -- CC 3/20/26

    #=====
    Weight
    =====#

    dWS(growthStem, N_stress, mRStem, deathStem, thinning_WS, dBud, coppicing, dShoot, root_conversion_efficiency) => begin
		growthStem * N_stress - mRStem - deathStem - thinning_WS - dBud - coppicing + root_conversion_efficiency * dShoot 
	end ~ track(u"kg/ha/hr")
    
    "Average stem mass"
    avStemMass(WS, stemNo) => WS / stemNo ~ track(u"kg")

    "Average stem mass in grams"
    avStemMass_g(avStemMass) ~ track(u"g")
    
    root_conversion_efficiency_cutting => .6  ~ preserve(parameter)
    
    root_conversion_efficiency_coppice => .75 ~ preserve(parameter)
	
    # Follow the establishment phase after the cutting flag has been evaluated.
    # TODO: The old root_conversion_efficiency parameter override is now silently
    # ignored because this selector is a track. Preserve or explicitly reject that
    # legacy setting. For now, configure the two phase-specific parameters above;
    # set both to the same value when a constant efficiency is intended. JHJ
    root_conversion_efficiency(cutting, root_conversion_efficiency_cutting, root_conversion_efficiency_coppice)  => begin
	    if cutting
		    root_conversion_efficiency_cutting
	    else
		    root_conversion_efficiency_coppice
	    end
    end ~ track


    # Reset when coppice == true (not sure if it resets in the beginning or the end of the loop)
    WS_lim(WS, step) => WS / step ~ track(u"kg/ha/hr") 
    WS(dWS) ~ accumulate(u"kg/ha", init=iWS, min=0) # stem drymass
    WS_ton(nounit(WS)) => WS / 1000 ~ track

    # stem respiration
    Q10_stem_below30C: stem_temperature_sensitivity_conefficient_below30C => 2.0 ~ preserve(parameter) #dimensionless
    Q10_stem_above30C: stem_temperature_sensitivity_conefficient_above30C => 1.61 ~ preserve(parameter) #dimensionless
    k_stem_20: stem_maintenance_rate_at_20C => 2.4 * 1000 ~ preserve(parameter, u"ng/kg/s"#=gCHO 20to30oC=#)
    k_stem_30(q=Q10_stem_below30C, k_stem_20): stem_maintenance_rate_at_30C => begin
        k_stem_20 * q^((30-20)/10)
    end~track(u"ng/kg/s"#=gCHO 30to40oC=#)

    Stem_Rp(k_stem_20, k_stem_30, WS, a = Q10_stem_below30C, b=Q10_stem_above30C, nounit(T_air)): stem_maintenance_respiration => begin
        if T_air < 30
            k_stem_20 * WS * a^((T_air-20) / 10)
        else
            k_stem_30 * WS * b^((T_air-30) / 10)
        end
    end ~ track(u"g/ha/hr"#=g CHO=#)


end
