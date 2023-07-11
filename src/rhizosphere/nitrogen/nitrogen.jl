include("demand.jl")
include("mobilization")
include("uptake.jl")
include("veggr.jl")

@system Nitrogen(NitrogenDemand, NitrogenMobilization, NitrogenUptake, NitrogenVeggr)