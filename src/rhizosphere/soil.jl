@enum SoilClass N S SL CL #C

@system Soil begin
    soil_class => CL ~ preserve::SoilClass(parameter)

    NO3 => 25 ~ preserve(parameter, u"μg/g")
    NH4 => 25 ~ preserve(parameter, u"μg/g")

    soil_table => [
        63 365 135
        96 420 198
        181 506 332
    ] ~ tabulate(
        rows=(:S, :SL, :CL),
        columns=(:wilting_point,:saturation,:field_capacity),
        parameter
    )


end
