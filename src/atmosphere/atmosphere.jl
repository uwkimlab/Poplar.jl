include("sun.jl")
include("vaporpressure.jl")
include("weather.jl")

@system Atmosphere(Sun, VaporPressure, Weather)