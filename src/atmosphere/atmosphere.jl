include("sun.jl")
include("vaporpressure.jl")
include("weather.jl")

"""
Atmosphere
"""
@system Atmosphere(Sun, VaporPressure, Weather)