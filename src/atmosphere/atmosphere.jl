include("sun.jl")
include("vaporpressure.jl")
include("weather.jl")

"""
Parent system for Sun, VaporPressure, and Weather.
"""
@system Atmosphere(Sun, VaporPressure, Weather)