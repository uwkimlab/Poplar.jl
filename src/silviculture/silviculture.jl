include("coppicing.jl")
include("defoliation.jl")
include("thinning.jl")

@system Silviculture(Coppicing, Defoliation, Thinning)