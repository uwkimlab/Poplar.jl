@enum SoilClass N S SL CL #C

@system Soil begin
    soil_class => CL ~ preserve::SoilClass(parameter)

    NO3 => 25 ~ preserve(parameter, u"μg/g")
    NH4 => 25 ~ preserve(parameter, u"μg/g")

    soil_table => [
	    0 200 200
        71 377 144
        93 418 198
        184 502 321
    ] ~ tabulate(
        rows=(:N, :S, :SL, :CL),
        columns=(:wilting_point,:saturation,:field_capacity),
        parameter
    )




end
