@enum SoilClass N S SL CL #C

"""
WIP. 
"""
@system Soil begin
    soil_class => CL ~ preserve::SoilClass(parameter)
end