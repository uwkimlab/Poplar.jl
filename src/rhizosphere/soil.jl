@enum SoilClass begin
    N  # No soil effect
    S  # Sandy
    SL # Sandy Loam
    CL # Clay Loam
    C  # Clay
end

"""
Soil.
"""
@system Soil begin
    soil_class => CL ~ preserve::SoilClass(parameter)

    NO3 => 25 ~ preserve(parameter, u"μg/g")
    NH4 => 25 ~ preserve(parameter, u"μg/g")
end