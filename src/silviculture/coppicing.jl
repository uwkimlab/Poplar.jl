@system Coppicing begin
    # Coppicing dates in the form of a vector of ZonedDateTime values.
    # Example in configuration in config.jl
    coppicing_date => [] ~ preserve::Vector(parameter, optional)

    # Coppicing only possible when dormant (for now), 
    coppice(coppicing_date, time, dormant) => begin
        (time in coppicing_date) 
    end ~ flag

    # True after coppicing has occurred for the first time
    first_coppice(coppice) ~ flag(once)

    # Don't have to worry about foliage during dormancy
    coppicing(step, WS, growthStem, deathStem, thinning_WS, dBud) => begin
        (WS / step) - (growthStem - deathStem - thinning_WS - dBud)
    end ~ track(when=coppice, u"kg/ha/hr")

   # Days since last coppiced 
   coppice_days(coppice,first_coppice) => begin
        1
   end ~ accumulate(when=first_coppice, reset=coppice,init=0, u"d")


    # Coppiced when stem biomass is zero.
    coppiced(WS, W, first_coppice) => begin
        WS == 0u"kg/ha" && W != 0u"kg/ha" && first_coppice
    end ~ flag

    harvested_stem( WS, harvested_stem,coppice) => begin
	if(coppice)
        	harvested_stem + WS
	else 
		harvested_stem
	end
    end ~ track( u"kg/ha",init=0)


end