module Poplar

using Cropbox

include("atmosphere/atmosphere.jl")
include("morphology/morphology.jl")
include("phenology/phenology.jl")
include("physiology/physiology.jl")
include("rhizosphere/rhizosphere.jl")
include("utils/utils.jl")

@system Model(Atmosphere, Morphology, Phenology, Physiology, Rhizosphere, Controller)

export Model

end
