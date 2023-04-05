@enum SoilClass N S SL CL C

@system Soil begin
    soil_class => CL ~ preserve::SoilClass(parameter)
end