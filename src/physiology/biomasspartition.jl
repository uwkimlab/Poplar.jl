@system BiomassPartition begin
    
    #===================
    Biomass partitioning
    ====================#
    
    "Fertility rating"
    FR ~ preserve(parameter)

    "Foliage:stem partitioning ratio at D=2cm"
    pFS2 ~ preserve(parameter)
    
    "Foliage:stem partitioning ratio at D=20cm"
    pFS20 ~ preserve(parameter)
    
    pfsPower(pFS2, pFS20) => log(pFS20 / pFS2) / log(20 / 2) ~ preserve
    
    pfsConst(pFS2, pfsPower) => pFS2 / 2 ^ pfsPower ~ preserve
    
    "Stem mass vs. diameter constant"
    aWs ~ preserve(parameter)
    
    "Stem mass vs. diameter exponent"
    nWs ~ preserve(parameter)
    
    "Maximum fraction of NPP to roots"
    pRx ~ preserve(parameter)
    
    "Minimum fraction of NPP to roots"
    pRn ~ preserve(parameter)

    "Value of 'mR' when FR = 0"
    m0 ~ preserve(parameter)
    
    fPhysiology(fVPD#=, fSW=#, fAge) => begin
        min(fVPD#=, fSW,=#) * fAge
    end ~ track

    mR(m0, FR) => m0 + (1 - m0) * FR ~ preserve
    pFS(pfsConst, nounit(avDBH), pfsPower) => pfsConst * (avDBH ^ pfsPower) ~ track # foliage and stem partition
    pR(pRx, pRn, fPhysiology, mR) => pRx * pRn / (pRn + ( pRx - pRn) * fPhysiology * mR) ~ track # root partition
    pS(pR, pFS) => (1 - pR) / (1 + pFS) ~ track # stem partition
    pF(pR, pS) => 1 - pR - pS ~ track # foliage partition
end