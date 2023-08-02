include("biomasspartition.jl")
include("demand.jl")
include("mobilization.jl")
include("mortality.jl")
include("photosynthesis.jl")
include("respiration.jl")
include("uptake.jl")
include("veggr.jl")

"""
Physiology encompassses all physiology-related systems as mix-ins.
"""
@system Physiology(BiomassPartition, Demand, Mobilization, Mortality, Photosynthesis, Respiration, Uptake, Veggr)