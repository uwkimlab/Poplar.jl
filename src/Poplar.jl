module Poplar

using Cropbox

include("atmosphere/atmosphere.jl")
include("morphology/morphology.jl")
include("phenology/phenology.jl")
include("physiology/physiology.jl")
include("rhizosphere/rhizosphere.jl")

@system Model(Atmosphere, Morphology, Phenology, Physiology, Rhizosphere, Controller)

end
