include("biomasspartition.jl")
include("mortality.jl")
include("photosynthesis.jl")

"""
Physiology encompassses all physiology-related systems as mix-ins.
"""
@system Physiology(BiomassPartition, Mortality, Photosynthesis)