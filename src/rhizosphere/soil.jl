@enum SoilClass N S SL CL C

@system Soil begin
    soilClass => CL ~ preserve::SoilClass(parameter)
end