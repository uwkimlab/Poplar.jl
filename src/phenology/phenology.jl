include("age.jl")
include("budburst.jl")
include("dormancy.jl")
include("senescence.jl")
include("shooting.jl")

@system Phenology(Age, Budburst, Dormancy, Senescence)