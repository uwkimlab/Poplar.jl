include("foliage.jl")
include("stem.jl")
include("root.jl")

"This system represents the characteristics of the "
@system Tree(Foliage, Stem, Root) begin

    #=========
    Parameters
    =========#

    # Initialization
    "Initial total drymass"
    iW(iWS, iWF, iWR) => iWS + iWF + iWR ~ preserve(u"kg/ha")

    "Initial tree count"
    iStemNo => 1000 ~ preserve(parameter, u"ha^-1")

    # Branch and bark fraction
    "Branch and bark fraction at age 0"
    fracBB0 => 0 ~ preserve(parameter)
    
    "Branch and bark fraction for mature stands"
    fracBB1 => 0 ~ preserve(parameter)
    
    "Age at which frac BB = (fracBB0 + fracBB1) / 2"
    tBB => 0 ~ preserve(parameter)
    
    # Basic density
    "Minimum basic density (for young trees)"
    rho0 => 0.358 ~ preserve(parameter, u"kg/m^3")
    
    "Maximum basic density (for older trees)"
    rho1 => 0.358 ~ preserve(parameter, u"kg/m^3")
    
    "Age at which rho = (rhoMin + rhoMax) / 2"
    tRho => 4 ~ preserve(parameter) # 
    
    # Stem height
    "Constant in the stem height relationship"
    aH => 0.9740 ~ preserve(parameter)
    
    "Power of DBH in the stem height relationship"
    nHB => 0.6816 ~ preserve(parameter)
    
    "Power of stocking in the stem height relationship"
    nHN => 0.1064 ~ preserve(parameter)
    
    # Stem volume
    "Constant in the stem volume relationship"
    aV => 0.0001 ~ preserve(parameter)
    
    "Power of DBH in the stem volume relationship"
    nVB => 2.3270 ~ preserve(parameter)
    
    "Power of stocking in the stem volume relationship"
    nVN => 1.0915 ~ preserve(parameter)
    
    #==========
    Stem Volume
    ==========#

    "Branch and bark fraction based on stand age"
    fracBB(standAge, fracBB0, fracBB1, tBB) => begin
    fracBB1 + (fracBB0 - fracBB1) * exp(-log(2) * (standAge / tBB))
    end ~ track

    "Density based on stand age"
    density(standAge, rho0, rho1, tRho) => begin
        rho1 + (rho0 - rho1) * exp(-log(2) * (standAge / tRho))
    end ~ track(u"kg/m^3")
    
    "Average diameter at breast height"
    avDBH(nounit(avStemMass), aWs, nWs) => begin
        (avStemMass / aWs) ^ (1 / nWs)
    end ~ track(u"cm")
    
    "Base area"
    basArea(avDBH, stemNo) => begin
        (((avDBH / 2) ^ 2) * pi) * stemNo
    end ~ track(u"m^2/ha") # base area
    
    "Canopy height"
    height(aH, nounit(avDBH), nHB, nHN, nounit(stemNo)) => begin
        aH * avDBH ^ nHB * stemNo ^ nHN * u"m"
    end ~ track(u"m")
    
    "Stand volume per hectare"
    standVol(WS, aV, nounit(avDBH), nVB, nVN, fracBB, nounit(stemNo), density) => begin
        if aV > 0
            aV * avDBH ^ nVB * stemNo ^ nVN * u"m^3/ha"
        else
            WS * (1 - fracBB) / density
        end
    end ~ track(u"m^3/ha")
    
    "Mean volume increment per hectare"
    MAI(standVol, standAge) => ((standAge > 0) ? (standVol / standAge) : 0) ~ track(u"m^3/ha")

    dStemNo(mortality) => -mortality ~ track(u"ha^-1/hr")
    stemNo(dStemNo) ~ accumulate(init=iStemNo, u"ha^-1")

    "Average tree mass"
    avStemMass(WS, stemNo) => WS / stemNo ~ track(u"kg")

    dW(dWF, dWR, dWS) => dWF + dWR + dWS ~ track(u"kg/ha/d")

    "Total weight"
    W(dW) ~ accumulate(u"kg/ha", init=iW)
end