@system IntercellularSpace begin
    # A_net ~ hold
    #TODO: interface between boundary/stomata/intercellular space (i.e. soil layers?)
    # rvc ~ hold

    #FIXME: duplicate in Stomata
    Ca(CO2, P_air): co2_air => begin
	(CO2 * P_air) 
    end ~ track(u"μbar")


    #HACK: high temperature simulation requires higher upper bound
    Cimax(Ca): intercellular_co2_upper_limit => 2Ca ~ track(u"μbar")
    Cimin: intercellular_co2_lower_limit => 0 ~ preserve(u"μbar")
    Ci(Ca, Ci, A_net, rvc): intercellular_co2 => begin
	if abs(A_net)>1e-8u"μmol/m^2/s"
        	Ca - Ci ⩵ A_net * rvc
	else
		Ca - Ci ⩵ 0u"μbar"
	end	
    end ~ bisect(min=Cimin, upper=Cimax, u"μbar")


    ci_gradient(Ca, Ci) => begin
	Ca - Ci 
    end ~ track(u"μbar")


    ci_flux(A_net, rvc) => begin
	A_net * rvc 
    end ~ track(u"μbar")
end