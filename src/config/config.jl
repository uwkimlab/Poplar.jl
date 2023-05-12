include("../morphology/radiation.jl")
include("../rhizosphere/soil.jl")

config_Clock = @config(
    :Clock => (
        step = 1u"hr",
    )
)

config_Calendar = @config(
    :Calendar => (
        init = ZonedDateTime(2008, 1, 1, tz"Asia/Seoul"),
        last = ZonedDateTime(2017, 8, 31, tz"Asia/Seoul"),
    )
)

config_Atmosphere = @config(
    :Atmosphere => (
        CO2 = 350,
        data = Poplar.loadwea(Poplar.datapath("2007.wea"), tz"Asia/Seoul")
    )
)

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

config_Model_Eucalyptus_globulus = @config(
    :Model => ( 
        # BiomassPartition
        FR = 1,
        pFS2 = 1,
        pFS20 = 0.15,
        aWs = 0.095,
        nWs = 2.4,
        pRx = 0.8,
        pRn = 0.25,
        m0 = 0,
        coeffCond = 0.05,

        # Mortality
        gammaN1 = 3,
        gammaN0 = 0,
        tgammaN = 3,
        ngammaN = 1,
        wSx1000 = 400,
        thinPower = 1.5,
        mF = 0,
        mR = 0.2,
        mS = 0.2,
         
        # Tree
        iStemNo= 1111,
        fracBB0 = 0.75,
        fracBB1 = 0.15,
        tBB = 2,
        rho0 = 0.450,
        rho1 = 0.450,
        tRho = 4,
        aH = 0,
        nHB = 0,
        nHN = 0,
        aV = 0,
        nVB = 0,
        nVN = 0,
         
        # Foliage
        iWF = 2000,
        SLA0= 11,
        SLA1= 4,
        tSLA= 2.5,
        gammaF1= 0.027,
        gammaF0= 0.001,
        tgammaF= 12,
        leaf_width= 3,
         
        # Stem
        iWS = 1000,
         
        # Root
        iWR = 2000,
        gammaR= 0.015,

        # Radiation
        leaf_angle = ellipsoidal,
        LAF = 3,
        scattering = 0.15,
        clumping = 1.0,

        # Age
        iAge = 1,
        maxAge = 50,
        nAge = 4,
        rAge = 0.95,

        # WaterBalance
        iASW = 999,
        maxASW = 300,
        minASW = 0,
        irrigation = 0,
        pool_fraction = 0,
        maxInterception = 0.15,
        LAImaxInterception = 0,
        SWconst0 = 0.7,
        SWpower0 = 9,

        # Soil
        soil_class = CL,
    )
)

config_1 = @config(
    config_Clock,
    config_Calendar,
    config_Atmosphere,
    config_GasExchange_NI,
    config_Model_Eucalyptus_globulus
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

config_Model_Amichev = @config(
    :Model => (
        # BiomassPartition
        pFS2 = 0.8567,
        pFS20 = 0.0590,
        stemConst = 0.0771,
        stemPower = 2.2704,
        pRx = 0.34,
        pRn = 0.13,
        gammaF0 = 0,
        gammaF1 = 0,
        tgammaF = 0,
        Rttover = 0.005,
        m0 = 0,
        fNo = 1,
        fNn = 0,
        coeffCond = 0.05,
        maxAge = 50,
        nAge = 4,
        rAge = 0.95,
        gammaN0 = 0,
        gammaN1 = 0,
        tgammaN = 0,
        ngammaN = 1,
        wSx1000 = 200,
        thinPower = 1.5,
        mF = 0,
        mR = 0.2,
        mS = 0.2,
        SLA0 = 10.8,
        SLA1 = 10.8,
        tSLA = 1,
        maxInterception = 0.15,
        LAImaxInterception = 0,
        fullCanAge = 0,
        fracBB0 = 0,
        fracBB1 = 0,
        tBB = 0,
        rhoMin = 0.358,
        rhoMax = 0.358,
        tRho = 4,
        aH = 0.9740,
        nHB = 0.6816,
        nHN = 0.1064,
        aV = 0.0001,
        nVB = 2.3270,
        nVN = 1.0915,
        Qa = -90,
        Qb = 0.8,
    )
)

# Headlee = @config(
#     :Model => (
#         pFS2 = 0.71,
#         pFS20 = 0.12,
#         aS = 0.081,
#         nS= 2.46,
#         pRx = 0.7,
#         pRn = 0.17,
#         gammaFx = 0.10,
#         gammaF0 = 0.083,
#         gammaR = 0.02,
#         m0 = 1,
#         fN0 = 0.26,
#         fNn = 1,
#         wSs1000 = 500,
#         thinPower = -1.45,
#         SLA0 = 19,
#         SLA1 = 10,
#         maxInterception = 0.24,
#         LAImaxInterception = 7.3,
#         coeffCond = 0.05,
#         BLcond = 0.05,
#         fracBB0 = 0.64,
#         fracBB1 = 0.24,
#         tBB = 3,
#         rhoMin = 0.39,
#         rhoMax = 0.35,
#         tRho = 2,
#         aH = 0.036,
#         nHB = 1.335,
#         nHN = 0.354,
#         aV = 0.0072,
#         nVB = 1.96,
#         nVN = -0.3,
#         tgammaF = 18,
#         gammaN1 = 3.5,
#         gammaN0 = 0,
#         tgammaN = 1,
#         ngammaN = 1,
#     )
# )

config_2 = @config(
    config_Clock,
    config_Calendar,
    config_Atmosphere,
    config_GasExchange_NI,
    config_Model_Eucalyptus_globulus,
    config_Model_Amichev
)