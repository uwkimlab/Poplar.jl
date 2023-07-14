include("biomasspartition.jl")
include("demand.jl")
include("mobilization")
include("mortality.jl")
include("photosynthesis.jl")
include("uptake.jl")
include("veggr.jl")

"""
Physiology encompassses all physiology-related systems as mix-ins.
"""
@system Physiology(BiomassPartition, Mortality, Photosynthesis)