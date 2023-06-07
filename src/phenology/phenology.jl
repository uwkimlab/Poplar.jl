include("age.jl")
include("BBCH.jl")
include("budburst.jl")
include("dormancy.jl")
include("leafexpansion.jl")
include("senescence.jl")
include("shooting.jl")

@system Phenology(Age, BBCH, Budburst, Dormancy, LeafExpansion, Senescence, Shooting)