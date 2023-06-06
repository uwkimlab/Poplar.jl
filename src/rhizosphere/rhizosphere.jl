include("soil.jl")
include("waterbalance.jl")

"""
Rhizosphere encompasses all rhizosphere-related systems as mixins.
"""
@system Rhizosphere(Soil, WaterBalance)