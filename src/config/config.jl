configCalendar = @config(
    :Calendar => (
        init = ZonedDateTime(2007, 9, 1, tz"Asia/Seoul"),
        last = ZonedDateTime(2017, 8, 31, tz"Asia/Seoul"),
    )
)

configAtmosphere = @config(
    :Atmosphere => (
        lat = -41.4,
        CO2 = 350,
        data = Poplar.loadwea(Poplar.datapath("2007.wea"), tz"Asia/Seoul")
    )
)

configGasExchangeNI = @config(
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

configGasExchangeEI = @config(
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

configModel = @config(
    :Model => (
        # Initialization
        iAge = 0,
        iWF = 2000,
        iWS = 1000,
        iWR = 2000,
        iStemNo = 2100,
        iASW = 999,

        # Biomass partition
        FR = 0,

        # Mortality
        wSx1000 = 400,
        gammaN0 = 0,
        gammaN1 = 3,
        tgammaN = 3,

        # Water balance
        maxASW = 340,
        minASW = 0,

    )
)

Amichev = @config(
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

Headlee = @config(
    :Model => (
        pFS2 = 0.71,
        pFS20 = 0.12,
        aS = 0.081,
        nS= 2.46,
        pRx = 0.7,
        pRn = 0.17,
        gammaFx = 0.10,
        gammaF0 = 0.083,
        gammaR = 0.02,
        m0 = 1,
        fN0 = 0.26,
        fNn = 1,
        wSs1000 = 500,
        thinPower = -1.45,
        SLA0 = 19,
        SLA1 = 10,
        maxInterception = 0.24,
        LAImaxInterception = 7.3,
        coeffCond = 0.05,
        BLcond = 0.05,
        fracBB0 = 0.64,
        fracBB1 = 0.24,
        tBB = 3,
        rhoMin = 0.39,
        rhoMax = 0.35,
        tRho = 2,
        aH = 0.036,
        nHB = 1.335,
        nHN = 0.354,
        aV = 0.0072,
        nVB = 1.96,
        nVN = -0.3,
        tgammaF = 18,
        gammaN1 = 3.5,
        gammaN0 = 0,
        tgammaN = 1,
        ngammaN = 1,
    )
)

c1 = @config(
    configGasExchangeNI,
    Amichev,
    :Clock => :step => 1u"hr",
    :Calendar => (
        :init => ZonedDateTime(2007, 9, 1, tz"Asia/Seoul"),
        :last => ZonedDateTime(2017, 8, 31, tz"Asia/Seoul"),
    ),
    :Weather => :data => Poplar.loadwea(Poplar.datapath("2007.wea"), tz"Asia/Seoul"),
    :Model => (;
        :iAge => 2, # Initial Age
        :iWF => 4000, # Initial foliage mass (kg/ha)
        :iWR => 5000, # Initial root mass (kg/ha)
        :iWS => 4000, # Initial stem mass (kg/ha)
        :iStemNo => 1430, # Initial number of trees per hectare
        :leaf_angle_factor => 3
    ),
)


