""
@system Mobilization begin

    "Maximum C pool mobilization rate (g[CH2O]/m^2/d)"
    C_mobilization_rate_max ~ preserve(parameter, u"g/m^2/d")

    "Maximum C pool mobilization rate (g[CH2O]/m^2/d)"
    N_mobilization_rate_max ~ preserve(parameter, u"g/m^2/d")

    #=
    Calculate potential N mobilitation for the day
    =#

    "Minimum relative rate of reproductive development under long days and optimal temperature"
    THVAR => 1 ~ preserve(parameter) 

    "Sensitivity to photoperiod; Slope of the relative rate of development for day lengths above CSDVAR (1/hr)"
    PPSEN => 0.2 ~ preserve(parameter)

    "Critical daylength above which development rate decreases (prior to flowering)"
    CSDVAR => 0 ~ preserve(parameter)

    "Critical daylength above which development rate remains at min value (prior to flowering) (hours)"
    CLDVAR(PPSEN, CSDVAR, THVAR) => begin
        if PPSEN >= 0
            CSDVAR + (1 - THVAR) / max(PPSEN, 0.000001)
        elseif PPSEN < 0
            CSDVAR + (1 - THVAR) / min(PPSEN, -0.000001)
        end
    end

    "Photoperiod days which occur in a real day (photoperiod days / day)"
    DRPP(CSDVAR, CLDVAR, THVAR, DAYL) => curve("inl", CSDVAR, CLDVAR, THVAR, DAYL) ~ track

    "Thermal time that occurs in a single real day based on early reproductive development temperature function (thermal days / day)"
    TNTFAC(T_air) => curve("lin", 3, 25, 33, 45, T_air) ~ track

    "Photo-thermal time that occurs in a real day based on early reproductive development temperature function"
    TDUMX(TNTFAC, DRPP) => TNTFAC * DRPP

    "Relative rate of N mining during vegetative stage to that in reproductive stage"
    NVSMOB => 1 ~ preserve(parameter)

    "Maximum fraction of N which can be mobilized in a day"
    NMOBMX => 0.08 ~ preserve(parameter)

    # I don't know why this is here it should be in nitrogen mobilization?
    # Nitrogen mobilization rate. Not sure what the numerical values represent.
    # NMOBR is mining rate as a fraction of the maximum rate, NMOBMX
    "Stage dependent N mining rate"
    NMOBR(NVSMOD, NMOBMX, TDUMX) => begin
        NVSMOB * NMOBMX * TDUMX
    end ~ track

    "Potential mobile N available from leaf (g[N]/m^2)"
    NMINELF(NMOBR, WNRLF) => NMOBR * WNRLF ~ track
    
    "Today's maximum potential N mobilization from leaf (g[N]/m^2)"
    LFNMINE(LFSNMOB, NMINELF) => LFSNMOB + NMINELF ~ track
    LFSNMOB(LFNMINE) 

    "Potential mobile N available from stem (g[N]/m^2)"
    NMINEST(NMOBR, WNRST) =>  NMOBR * WNRST ~ track

    "Today's maximum potential N mobilization from stem (g[N]/m^2)"
    STNMINE(STSNMOB, NMINEST) => STSNMOB + NMINEST ~ track
    STSNMOB(STNMINE)

    "Potential mobile N available from root (g[N]/m^2)"
    NMINERT(NMOBR, PPMFAC, WNRRT) => NMOBR * PPMFAC * WNRRT ~ track

    "Today's maximum potential N mobilization from root"
    RTNMINE(RTSNMOB, NMINERT) => RTSNMOB + NMINERT ~ track

    "Potential mobile N available from storage (g[N]/m^2)"
    NMINESR(NMOBSR, WNRSR) => NMOBR * WNRSR ~ track

    "Today's maximum potential N mobilization from storage"
    SRNMINE(SRSNMOB, NMINESR) => SRSNMOB + NMINESR ~ track

    "Potential whole-plant N mobilization from storage (g[N]/m^2/d)"
    NMINEP(LFNMINE, STNMINE, RTNMINE, SRNMINE) => begin
        LFNMINE + STNMINE + RTNMINE + SRNMINE
    end

    "DSSAT4 potential N mobilization from storage (g[N)/m^2/d)"
    NMINEO(NMINELF, NMINEST, NMINERT, NMINESR) => begin
        NMINELF + NMINEST + NMINERT + NMINESR
    end

    "Total plant N mobilized from tissues lost to natural and low-light senescence"
    TSNMOB(LFSNMOB, STSNMOB, SRSNMOB, RTSNMOB) => begin
        LFSNMOB + STSNMOB + SRSNMOB + RTSNMOB
    end

    LFSENWT(SENRTE, NMINELF) => SENRTE * NMINELF / 0.16 ~ track(max=WTLF)
    
    STSENWT(LFSENWT, PORPT) => LFSENWT * PORPT ~ track

    N_mined_actual(N_demand_new, N_uptake, N_mined_potential) => begin
        if N_demand_new - N_uptake > 1.e5 && N_mined_potential > 1.e4
            N_demand_new - N_uptake
        else
            0
        end
    end ~ track

    N_mined_R(N_mined_actual, N_mined_potential, N_mob_rate) => begin
        N_mined_actual / N_mined_potential * N_mob_rate
    end ~ track

    N_mobilized_leaf(N_mined_R, N_available_leaf)

    N_mobilized_root(N_mined_R, N_available_root)

    N_mobilized_stem(N_mined_R, N_available_stem)

    # I don't know why this is here it should be in nitrogen mobilization?
    # Nitrogen mobilization rate. Not sure what the numerical values represent.
    # NMOBR is mining rate as a fraction of the maximum rate, NMOBMX
    # NMOBR(NVSMOD, NMOBMX, TDUMX) => begin
    #     NMOBMX * TDUMX2 * (1.0 + 0.5*(1.0 - SWFAC)) *
    #     (1.0 + 0.3 * (1.0 - NSTRES)) * (NVSMOB + (1 - NVSMOB) *
    #     max(XPOD, DXR57^2))
    # end ~ track

    # # Potential nitrogen mined. Nitrogen mobilization rate * N mined from each organ.
    # # Get rid of shell?
    # NMINEP(NMOBR, WNRLF, WNRST, WNRRT, WNRSH) => begin
    #     NMOBR * (WNRLF + WNRST + WNRRT + WNRSH)
    # end

    #=
    C mobilization
    =#

    LFSNMOB(SLMDOT, PCNL, SENNLV) => begin
        LMDOT * (PCNL/100 - 
        (SENNLV * (PCNL / 100 - PROLFF*0.16) + PROLFF*0.16)) 
        + LTSEN * (PCNL / 100 - PROLFF * 0.16)
    end

    STSNMOB() => begin
        SSMDOT * (PCNST/100 - 
        (SENNSV * (PCNST / 100 - PROSTF*0.16) + PROSTF*0.16)) 
        + STLTSEN * (PCNST / 100 - PROSTF * 0.16)
    end

    SRSNMOB() => begin

    # IF (PLME .EQ. 'T' .AND. YRPLT .EQ. YRDOY) THEN
    #     K = TSELC(2)
    #     FT(2) = CURV(CTMP(2),TB(K),TO1(K),TO2(K),TM(K),ATEMP)
    #     PHZACC(2) = FT(2) * SDAGE
    #   ENDIF

    RTSEN => 0.008 ~ preserve(parameter)
    SRSEN => 0.009 ~ preserve(parameter)
    LFSEN => 0.01 ~ preserve(parameter)

    DTX => curve(linear, 3, 25, 33, 45, T_air)

    # Root length senesced?
    RLSEN(RLV, RTSEN, DTX) => RLV * RTSEN * DTX ~ track

    SRMDOT(RLSEN, RFAC) => RLSEN / RFAC ~ track(u"g/m^2")

    SSRMDOT => 

    SLMDOT => WTLF * LFSEN * DTX

    SSMDOTmin => 0.1 * STMWT
    SSMDOT => SLMDOT * PORPT ~ track(min=SSMDOTmin)

    # leaf mob natural senescence
    LFSNMOB(SLMDOT, PCNL, SENNLV, PROLFF, LTSEN) => begin
        SLMDOT * (PCNL/100 - (SENNLV * (PCNL / 100 - PROLFF * 0.16) + PROLFF * 0.16))+
        LTSEN * (PCNL / 100 - PROLFF * 0.16)
    end ~ track

    STSNMOB(SSMDOT, PCNST, SENNSV, PCNST, PROSTF, STLFSEN) => begin
        SSMDOT * (PCNST / 100 - (SENNSV * (PCNST / 100 - PROSTF * 0.16) + PROSTF * 0.16)) +
        STLTSEN * (PCNST / 100 - PROSTF * 0.16)
    end ~ track

    RTSNMOB(SRMDOT, PCNRT, SENNRV, PRORTF) => begin
        SRMDOT * (PCNRT / 100 - (SENNRV * (PCNRT / 100 - PRORTF*0.16) + PRORTF*0.16))
    end ~ track

    SRSNMOB(SSRMDOT, PCNSR, SENNSRV, PCNSR, PROSRF) => begin
        SSRMDOT * (PCNSR / 100 - (SENNSRV * (PCNSR / 100 - PROSRF*0.16) + PROSRF*0.16))
    end ~ track

    "Potential mobile N available from leaf"
    NMINELF(NMOBR, WNRLF) => NMOBR * WNRLF ~ track
    ""
    LFNMINE(LFSNMOB, NMINELF) => LFSNMOB + NMINELF ~ track

    "Potential mobile N available from stem"
    NMINEST(NMOBR, WNRST) => NMOBR * WNRST ~ track
    ""
    STNMINE(STSNMOB, NMINEST) => STSNMOB + NMINEST ~ track

    "Potential mobile N available from root"
    NMINERT(NMOBR, PPMFAC, WNRRT) => NMOBR * PPMFAC * WNRRT ~ track
    ""
    RTNMINE(RTSNMOB, NMINERT) => RTSNMOB + NMINERT ~ track

    "Potential mobile N available from storage"
    NMINESR(NMOBSR, WNRSR) => NMOBSR * WNRSR ~ track
    ""
    SRNMINE(SRSNMOB, NMINESR) => SRSNMOB + NMINESR ~ track
 
    "Total plant N movilized from tissue lost to natural and low-light senescence"
    TSNMOB(LFNMINE, STNMINE, RTNMINE, SRNMINE) => begin
        LFNMINE + STSNMINE + SRNMINE + RTNMINE
    end ~ track(u"g/m^2/hr")

    "Potential mobile CH2O available from leaf"
    CMINELF(CMOBX, DTX, WCRLF, WF, PCHOLFF) => begin
        CMOBMX * DTX * (WCRLF - WF * PCHOLFF)
    end ~ track(u"g/m^2/hr")

    "Potential mobile CH2O available from stem"
    CMINEST(CMOBX, DTX, WCRST, WS, PCHOSTF) => begin
        CMOBMX * DTX * (WCRST - WS * PCHOSTF)
    end ~ track(u"g/m^2/hr")

    "Potential mobile CH2O available from root"
    CMINERT(CMOBX, DTX, WCRRT, WR, PCHORTF) => begin
        CMOBX * DTX * PPMFAC * (WCRRT - WR * PCHORTF)
    end ~ track(u"g/m^2/hr")

    "Potential mobile CH2O available from storage"
    CMINESR(CMOBX, DTX, WCRSR, ) => begin
        CMOBSR * DTX * (WCRSR - WSR * PCHOSRF)
    end ~ track(u"g/m^2/hr")

    "N available for mobilization from foliage above lower limit of mining"
    WNRLF(WTNLF, PROLFF, WF, WCRLF) => begin
        WTNLF - PROLFF * 0.16 * (WF - WCRLF)
    end ~ track(min=0, u"g/m^2")

    "N available for mobilization from stem above lower limit of mining"
    WNRST(WTNST, PROSTF, WS, WCRST) => begin
        WTNST - PROSTF * 0.16 * (WS - WCRST)
    end ~ track(min=0, u"g/m^2")

    "N available for mobilization from root above lower limit of mining"
    WNRRT(WTNRT, PRORTF, WR, WCRRT) => begin
        WTNRT - PRORTF * 0.16 * (WR - WCRRT)
    end ~ track(min=0, u"g/m^2")

    "N available for mobilization from storage above lower limit of mining"
    WNRSR(WTNSR, PROSRF, WSR, WCRSR) => begin
        WTNST - PROSRF * 0.16 * (WSR - WCRSR)
    end ~ track(min=0, u"g/m^2")
end