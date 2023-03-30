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
    
    "Stem mass vs. diameter constant"
    aWs => 0.0771 ~ preserve(parameter)
    
    "Stem mass vs. diameter exponent"
    nWs => 2.2704 ~ preserve(parameter)
    
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

    "?"
    m1(m0, FR) => m0 + (1 - m0) * FR ~ preserve
    pFS(pfsConst, nounit(avDBH), pfsPower) => pfsConst * avDBH ^ pfsPower ~ track # foliage and stem partition
    pR(pRx, pRn, fPhysiology, m1) => pRx * pRn / (pRn + (pRx - pRn) * fPhysiology * m1) ~ track # root partition
    pS(pR, pFS) => (1 - pR) / (1 + pFS) ~ track # stem partition
    pF(pR, pS) => 1 - pR - pS ~ track # foliage partition
end