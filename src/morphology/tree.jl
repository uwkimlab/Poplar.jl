include("foliage.jl")
include("stem.jl")
include("root.jl")
include("storage.jl")

"Tree system"
@system Tree(Foliage, Stem, Root, Storage) begin

    #=========
    Parameters
    =========#

    "Initial total drymass"
    iW(iWS, iWF, iWR) => iWS + iWF + iWR ~ preserve(u"kg/ha")

    "Initial plant count"
    trees_init => 1000 ~ preserve(parameter, u"ha^-1")

    "Branch and bark fraction at age 0"
    fracBB0 => 0 ~ preserve(parameter) # Amichev
    
    "Branch and bark fraction for mature stands"
    fracBB1 => 0 ~ preserve(parameter) # Amichev
    
    "Age at which frac BB = (fracBB0 + fracBB1) / 2"
    tBB => 0 ~ preserve(parameter) # Amichev
    
    #######################################################################################

    "Minimum basic density (for young trees)"
    rho0 => 0.358 ~ preserve(parameter, u"kg/m^3") # Amichev
    
    "Maximum basic density (for older trees)"
    rho1 => 0.358 ~ preserve(parameter, u"kg/m^3") # Amichev
    
    "Age at which rho = (rhoMin + rhoMax) / 2"
    tRho => 4 ~ preserve(parameter) # Sands
    
    # Stem height
    "Constant in the stem height relationship"
    aH => 0.9740 ~ preserve(parameter) # Amichev
    
    "Power of DBH in the stem height relationship"
    nHB => 0.6816 ~ preserve(parameter) # Amichev
    
    "Power of stocking in the stem height relationship"
    nHN => 0.1064 ~ preserve(parameter) # Amichev
    
    # Stem volume
    "Constant in the stem volume relationship"
    aV => 0.0001 ~ preserve(parameter) # Amichev
    
    "Power of DBH in the stem volume relationship"
    nVB => 2.3270 ~ preserve(parameter) # Amichev
    
    "Power of stocking in the stem volume relationship"
    nVN => 1.0915 ~ preserve(parameter) # Amichev

    "Stem mass vs. diameter constant"
    aWs => 0.0771 ~ preserve(parameter) # Amichev
    
    "Stem mass vs. diameter exponent"
    nWs => 2.2704 ~ preserve(parameter) # Amichev
    
    #==========
    Stem Volume
    ==========#

    "Branch and bark fraction based on stand age"
    fracBB(stand_age, fracBB0, fracBB1, tBB) => begin
    fracBB1 + (fracBB0 - fracBB1) * exp(-log(2) * (stand_age / tBB))
    end ~ track

    "Density based on stand age"
    density(stand_age, rho0, rho1, tRho) => begin
        rho1 + (rho0 - rho1) * exp(-log(2) * (stand_age / tRho))
    end ~ track(u"kg/m^3")
    
    "Average diameter at breast height"
    avDBH(nounit(avStemMass), aWs, nWs) => begin
        (avStemMass / aWs) ^ (1 / nWs)
    end ~ track(u"cm")
    
    "Base area"
    basArea(avDBH, trees) => begin
        (((avDBH / 2) ^ 2) * pi) * trees
    end ~ track(u"m^2/ha") # base area
    
    "Canopy height"
    height(aH, nounit(avDBH), nHB, nHN, nounit(trees)) => begin
        aH * avDBH ^ nHB * trees ^ nHN * u"m"
    end ~ track(u"m")
    
    "Stand volume per hectare"
    standVol(WS, aV, nounit(avDBH), nVB, nVN, fracBB, nounit(trees), density) => begin
        if aV > 0
            aV * avDBH ^ nVB * trees ^ nVN * u"m^3/ha"
        else
            WS * (1 - fracBB) / density
        end
    end ~ track(u"m^3/ha")
    
    "Mean volume increment per hectare"
    MAI(standVol, stand_age) => ((stand_age > 0) ? (standVol / stand_age) : 0) ~ track(u"m^3/ha")

    trees_delta(#=mortality, =#thinning) => #=-mortality=# - thinning ~ track(u"ha^-1/hr")
    
    trees(trees_delta) ~ accumulate(init=trees_init, u"ha^-1")

    "Hourly change in tree drymass"
    dW(dWF, dWR, dWS) => dWF + dWR + dWS ~ track(u"kg/ha/hr")

    "Total tree drymass"
    W(dW) ~ accumulate(u"kg/ha", init=iW, min=0)

    "Total tree drymass in metric ton"
    W_ton(nounit(W)) => W / 1000 ~ track 

    # Do I need this? I don't think so.
    # W_lim(W, step) => W / step ~ track(u"kg/ha/hr")
end