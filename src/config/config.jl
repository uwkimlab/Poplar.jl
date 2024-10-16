#====================================================================
This file contains a number of sample configurations for convenience.
====================================================================#

# Very important. Determines initial and final dates.
# Weather data MUST include the date range specified.
config_Calendar = @config(
    :Calendar => (
        init = ZonedDateTime(2014, 4, 5, tz"America/Los_Angeles"),
        last = ZonedDateTime(2021, 12, 31, tz"America/Los_Angeles"),
    )
)

# Weather data must be included.
config_Atmosphere = @config(
    :Atmosphere => (
        data = Poplar.loadwea(Poplar.datapath("CUH.wea"), tz"America/Los_Angeles"),
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

# Newly implemented. Made and tested by Sun Woo Chung
config_GasExchange_Newone = @config(
    :GasExchange => (
        Tp25 = 11.55, #from Kim and Lieth (2003)
        
        #Rd25 = 1.5, #from Poplar book (?)
        Rd25 = 0.38, #https://doi.org/10.1093/treephys/tpaa007

        Kc25 = 404, #from Pury and Farquhar (1997)
        Ko25 = 248, #from Pury and Farquhar (1997)
        Eac = 59.4, #from Pury and Farquhar (1997)
        Eao = 36.0, #from Pury and Farquhar (1997)
        Ear = 66.4, #from Pury and Farquhar (1997)
        Eag = 37.83, #from Pury and Farquhar (1997)

        #EaVc = 45.5, #from Kim and Lieth (2003)
        EaVc = 114.74, #https://doi.org/10.1093/treephys/tpaa007

        #Eaj = 43.3,  #from Kim and Lieth (2003)
        Eaj = 56.97,  #https://doi.org/10.1093/treephys/tpaa007

        EaTp = 47.1, #from Kim and Lieth (2003)

        #Hj = 219.4, #from Kim and Lieth (2003)
        Hj = 200.0, #https://doi.org/10.1093/treephys/tpaa007
        
        #Sj = 704.2, #from Kim and Lieth (2003)
        Sj = 657.0, #https://doi.org/10.1093/treephys/tpaa007

        #Γ25 = 36.9, #from Pury and Farquhar (1997)
        Γ25 = 55.72, #https://doi.org/10.1093/treephys/tpaa007

        #Vcm25 = 65.07387082971192, # from GH2306?
        Vcm25 = 105.57, #https://doi.org/10.1093/treephys/tpaa007
        #Jm25 = 118.2302458598954, # from GH2306?
        Jm25 = 119.62,  #https://doi.org/10.1093/treephys/tpaa007

        g1 = 9.670307198008624, # from GH2306?
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
