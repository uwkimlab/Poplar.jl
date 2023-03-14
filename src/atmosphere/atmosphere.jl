include("sun.jl")
include("vaporpressure.jl")
include("weather.jl")
include("../phenology/phenology.jl")

@system Atmosphere(Sun, VaporPressure, Weather)