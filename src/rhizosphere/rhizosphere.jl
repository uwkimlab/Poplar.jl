include("soil.jl")
include("waterbalance.jl")

@system Rhizosphere(Soil, WaterBalance)