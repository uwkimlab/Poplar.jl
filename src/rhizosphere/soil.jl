@enum SoilClass N S SL CL #C

@system Soil begin
    soil_class => CL ~ preserve::SoilClass(parameter)

    NO3 => 25 ~ preserve(parameter, u"μg/g")
    NH4 => 25 ~ preserve(parameter, u"μg/g")
end