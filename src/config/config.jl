#====================================================================
This file contains a number of sample configurations for convenience.
====================================================================#

include("../morphology/radiation.jl")
include("../rhizosphere/soil.jl")

# Very important. Determines initial and final dates.
# Weather data MUST include the date range specified.
config_Calendar = @config(
    :Calendar => (
        init = ZonedDateTime(2014, 4, 5, tz"UTC-8"),
        last = ZonedDateTime(2021, 12, 31, tz"UTC-8"),
    )
)

# Weather data must be included.
config_Atmosphere = @config(
    :Atmosphere => (
        data = Poplar.loadwea(Poplar.datapath("CUH.wea"), tz"UTC-8"),
    )
)

# Default parameters for GasExchange (WIP).
config_GasExchange_NI = @config(
    :GasExchange => (
        Tp25 = 11.55,
        Rd25 = 1.5, 
        Kc25 = 404,
        Ko25 = 248,
        Eac = 59.4,
        Eao = 36.0,
        Ear = 66.4,
        EaVc = 45.5,
        Eaj = 43.3,
        EaTp = 47.1,
        Hj = 219.4,
        Sj = 704.2,
        Γ25 = 36.9,
        Vcm25 = 56.95822653317411,
        Jm25 = 98.9269941286961,
        g1 = 9.670307198008624,
    )
)

# GasExchange parameters for endophyte inoculation (WIP).
config_GasExchange_EI = @config(
    :GasExchange => (
        Tp25 = 11.55,
        Rd25 = 1.5, 
        Kc25 = 404,
        Ko25 = 248,
        Eac = 59.4,
        Eao = 36.0,
        Ear = 66.4,
        EaVc = 45.5,
        Eaj = 43.3,
        EaTp = 47.1,
        Hj = 219.4,
        Sj = 704.2,
        Γ25 = 36.9,
        Vcm25 = 65.07387082971192,
        Jm25 = 118.2302458598954,
        g1 = 8.187614565131721,
    )
)

config_Model = @config(
    config_Calendar,
    config_Atmosphere
)

config_defoliation = @config(
    :Model => (
        defoliation_date = [ZonedDateTime(2009, 9, 1, tz"Asia/Seoul")],
        defoliation_value = [0.25]
    )
)

config_thinning = @config(
    :Model => (
        thinning_date = [ZonedDateTime(2010, 9, 1, tz"Asia/Seoul"), ZonedDateTime(2013, 9, 1, tz"Asia/Seoul")],
        thinning_value = [800u"ha^-1", 400u"ha^-1"],
        thinning_F = [1, 0.5],
        thinning_S = [1, 1],
        thinning_R = [1, 1],
    )
)

config_coppicing = @config(
    :Model => (
        coppicing_date = [
            ZonedDateTime(2008, 12, 31, tz"Asia/Seoul"),
            ZonedDateTime(2009, 12, 31, tz"Asia/Seoul"),
        ],
    )
)