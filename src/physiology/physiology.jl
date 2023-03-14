include("biomasspartition.jl")
include("mortality.jl")
include("photosynthesis.jl")

@system Physiology(BiomassPartition, Mortality, Photosynthesis)