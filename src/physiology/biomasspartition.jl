@system BiomassPartition begin
    
    #===========
     Parameters
    ===========#
    
    "Fertility rating"
    FR => 0.4582 ~ preserve(parameter) # 

    "Foliage:stem partitioning ratio at D=2cm"
    pFS2 => 0.8567 ~ preserve(parameter)
    
    "Foliage:stem partitioning ratio at D=20cm"
    pFS20 => 0.0590 ~ preserve(parameter)
    
    pfsPower(pFS2, pFS20) => log(pFS20 / pFS2) / log(20 / 2) ~ preserve
    
    pfsConst(pFS2, pfsPower) => pFS2 / 2 ^ pfsPower ~ preserve
    
    "Maximum fraction of NPP to roots"
    pRx => 0.34 ~ preserve(parameter)
    
    "Minimum fraction of NPP to roots"
    pRn => 0.13 ~ preserve(parameter)

    "Value of 'm1' when FR = 0"
    m0 => 0 ~ preserve(parameter)

    "Stomatal response to VPD"
    coeffCond => 0.05 ~ preserve(parameter, u"mbar^-1")
    
    "Soilwater modifier on root partitioning"
    fSW(ASW, maxASW, SWconst, SWpower) => begin
        1 / (1 + ((1 - (ASW / maxASW)) / SWconst) ^ SWpower)
    end ~ track

    "VPD modifier on root partitioning"
    fVPD(VPD, coeffCond) => begin
        exp(-coeffCond * VPD)
    end ~ track

    "Modifier for root partitioning based on VPD, SW, and Age"
    fPhysiology(fVPD, fSW, fAge) => begin
        min(fVPD, fSW) * fAge
    end ~ track
    
    #Total partitionable (?) partition
    # NPP_target ~ preserve(parameter, u"kg/ha/hr")

    "Specifies the fractional amount of root biomass that exceeds the aboveground requirements that can be supplied in a given month."
    frac => 0.02 ~ preserve(parameter)

    "Specifies the efficiency in converting root biomass into aboveground biomass."
    efficiency => 0.7  ~ preserve(parameter)

    # Coppicing mechanism included in the modified 3PG model from CSTARS.
    # root_partition(NPP, NPP_target, frac) => begin
    #     NPP_res = NPP_target - NPP
    #     if NPP_res > 0 && (WR/W) > pRx
    #         min(NPP_res, WR*(WR/W - pRx)*frac)
    #     else
    #         0
    #     end
    # end ~ remember(when=coppiced)

    # NPP(NPP) => begin
    #     NPP + root_partition
    # end ~ track(u"kg/ha/hr")

    #=================
    Paritioning Ratios
    =================#

    # TODO: Better variable name? Empirical value used in foliage to stem ratio.
    m1(m0, FR) => m0 + (1 - m0) * FR ~ preserve

    "Ratio of foliage to stem parititioning"
    pFS(pfsConst, nounit(avDBH), pfsPower) => pfsConst * avDBH ^ pfsPower ~ track

    "Root partitioning proportion"
    pR(pRx, pRn, fPhysiology, m1) => begin
        # (pRx * pRn) / (pRn + (pRx - pRn) * fPhysiology * m1) 
        0.14
    end ~ track # root partitions

    "Stem partitioning proportion"
    pS(pR, pFS) => begin
        # (1 - pR) / (1 + pFS)
        0.52
    end ~ track # stem partition

    "Foliage paritioning proportion"
    pF(pR, pS, pFS) => begin
        # 1 - pR - pS # foliage partition
        # (1 - pR) / (1 + (1 / pFS))
        0.34
    end ~ track 
end