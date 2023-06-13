module Poplar
using Cropbox

include("utils/utils.jl")
include("atmosphere/atmosphere.jl")
include("calendar/calendar.jl")
include("config/config.jl")
include("morphology/morphology.jl")
include("phenology/phenology.jl")
include("physiology/physiology.jl")
include("rhizosphere/rhizosphere.jl")
include("silviculture/silviculture.jl")

@system Model(Atmosphere, Calendar, Morphology, Phenology, Physiology, Rhizosphere, Silviculture, Controller)

weather = Poplar.loadwea(Poplar.datapath("2007.wea"), tz"Asia/Seoul")
CUH = Poplar.loadwea(Poplar.datapath("CUH.wea"), tz"UTC-8")

export Model

end