@enum SoilClass N S SL CL LS #C

@system Soil begin
    soil_class => CL ~ preserve::SoilClass(parameter)

    NO3 => 25 ~ preserve(parameter, u"μg/g")
    NH4 => 25 ~ preserve(parameter, u"μg/g")

    soil_table => [
	    0   200 200 0.70 9
        71  377 144 0.70 9
	    88  402 169 0.65 8
        93  418 198 0.60 7
        184 502 321 0.50 5 
    ] ~ tabulate(
        rows=(:N, :S, :LS, :SL, :CL),
        columns=(:wilting_point, :saturation, :field_capacity, :cθ, :nθ),
        parameter
    )

end
