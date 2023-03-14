include("foliage.jl")
include("stem.jl")
include("root.jl")

@system Tree(Foliage, Stem, Root) begin
    "Initial total drymass"
    iW(iWS, iWF, iWR) => iWS + iWF + iWR ~ preserve(u"kg/ha")

    "Initial tree count"
    iStemNo ~ preserve(parameter, u"ha^-1")

    # Branch and bark fraction
    "Branch and bark fraction at age 0"
    fracBB0 ~ preserve(parameter)
    
    "Branch and bark fraction for mature stands"
    fracBB1 ~ preserve(parameter)
    
    "Age at which frac BB = (fracBB0 + fracBB1) / 2"
    tBB ~ preserve(parameter)
    
    # Basic density
    "Minimum basic density (for young trees)"
    rho0 ~ preserve(parameter, u"kg/m^3")
    
    "Maximum basic density (for older trees)"
    rho1 ~ preserve(parameter, u"kg/m^3")
    
    "Age at which rho = (rhoMin + rhoMax) / 2"
    tRho ~ preserve(parameter) # 
    
    # Stem height
    "Constant in the stem height relationship"
    aH ~ preserve(parameter)
    
    "Power of DBH in the stem height relationship"
    nHB ~ preserve(parameter)
    
    "Power of stocking in the stem height relationship"
    nHN ~ preserve(parameter)
    
    # Stem volume
    "Constant in the stem volume relationship"
    aV ~ preserve(parameter)
    
    "Power of DBH in the stem volume relationship"
    nVB ~ preserve(parameter)
    
    "Power of stocking in the stem volume relationship"
    nVN ~ preserve(parameter)

    dW(dWF, dWR, dWS) => dWF + dWR + dWS ~ track(u"kg/ha/d")
    W(dW) ~ accumulate(u"kg/ha", init=iW) # total drymass
    
    # Branch and bark fraction based on stand age (years)
    fracBB(standAge, fracBB0, fracBB1, tBB) => begin
    fracBB1 + (fracBB0 - fracBB1) * exp(-log(2) * (standAge / tBB))
    end ~ track

    # Density based on stand age (years)
    density(standAge, rho0, rho1, tRho) => begin
        rho1 + (rho0 - rho1) * exp(-log(2) * (standAge / tRho))
    end ~ track(u"kg/m^3")
    
    # Average tree mass
    avStemMass(WS, stemNo) => WS / stemNo ~ track(u"kg")
    
    # Average diameter at breast height
    avDBH(nounit(avStemMass), aWs, nWs) => begin
        (avStemMass / aWs) ^ (1 / nWs)
    end ~ track(u"cm")
    
    # Base area
    basArea(avDBH, stemNo) => begin
        (((avDBH / 2) ^ 2) * pi) * stemNo
    end ~ track(u"m^2/ha") # base area
    
    # Height
    height(aH, nounit(avDBH), nHB, nHN, stemNo) => begin
        aH * avDBH ^ nHB * stemNo ^ nHN
    end ~ track
    
    # Stand volume per hectare
    standVol(WS, aV, avDBH, nVB, nVN, fracBB, stemNo, density) => begin
        if aV > 0
            aV * avDBH ^ nVB * stemNo ^ nVN
        else
            WS * (1 - fracBB) / density
        end
    end ~ track(u"m^3/ha")
    
    # Mean volume increment per hectare
    MAI(standVol, standAge) => ((standAge > 0) ? (standVol / standAge) : 0) ~ track(u"m^3/ha")

    dStemNo(mortality) => -mortality ~ track(u"ha^-1/hr")
    stemNo(dStemNo) ~ accumulate(init=iStemNo, u"ha^-1")
end