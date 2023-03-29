include("age.jl")
include("budburst.jl")
include("senescence.jl")

@system Phenology(Age, Budburst, Senescence)