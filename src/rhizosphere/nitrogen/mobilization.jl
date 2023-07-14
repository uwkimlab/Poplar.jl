@system NitrogenMobilization begin

    "Maximum C pool mobilization rate (g[CH2O]/m^2/d)"
    C_mobilization_rate_max ~ preserve(parameter, u"g/m^2/d")

    "Maximum C pool mobilization rate (g[CH2O]/m^2/d)"
    N_mobilization_rate_max ~ preserve(parameter, u"g/m^2/d")

    #=
    Calculate potential N mobilitation for the day
    =#

    DRPP(CSDVAR, CLDVAR, THVAR, DAYL) => curve("inl", CSDVAR, CLDVAR, RHVAR, DAYL) ~ track
    TNTFAC(T_air) => curve("lin", 3, 25, 33, 45, T_air) ~ track 
    TDUMX(TNTFAC, DRPP) => TNTFAC * DRPP

    # I don't know why this is here it should be in nitrogen mobilization?
    # Nitrogen mobilization rate. Not sure what the numerical values represent.
    # NMOBR is mining rate as a fraction of the maximum rate, NMOBMX
    NMOBR(NVSMOD, NMOBMX, TDUMX) => begin
        NMOBMX * TDUMX2 * (1.0 + 0.5*(1.0 - SWFAC)) *
        (1.0 + 0.3 * (1.0 - NSTRES)) * (NVSMOB + (1 - NVSMOB) *
        max(XPOD, DXR57^2))
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

    CMINELF => begin
        CMOBMX * (DTX + DXR57) * (WCRLF - WRLF * PCHOLFF)
    end

    CMINEST => begin
        CMOBMX * (DTX + DXR57) * (WCRST - STMWT * PCHOSTF)
    end

    CMINERT => begin
        CMOBX * (DTX * DXR457) * PPMFAC * (WCRRT - RTWT * PCHORTF)
    end

    CMINESR => begin
        CMOBSR * (DTX + DXR57) * (WCRSR - STRWT * PCHOSRF)
    end



    # IF (PLME .EQ. 'T' .AND. YRPLT .EQ. YRDOY) THEN
    #     K = TSELC(2)
    #     FT(2) = CURV(CTMP(2),TB(K),TO1(K),TO2(K),TM(K),ATEMP)
    #     PHZACC(2) = FT(2) * SDAGE
    #   ENDIF

    TNTFAC
end