include("soil.jl")
include("waterbalance.jl")
include("soilenergy.jl")

"""
Rhizosphere encompasses all rhizosphere-related systems as mixins.
"""
@system Rhizosphere(Soil, SoilEnergy, WaterBalance)
