""
@system Mobilization begin

    #========================
    N from natural senescence
    ========================#

    SENNLV => 1 ~ preserve

    # LTSEN(DTX, XLAI, LCMP, TCMP) => begin
    #     DTX * (XLAI - LCMP) / TCMP
    # end

    "Nitrogen mobilized from natural leaf senescence"
    LFSNMOB(senescence_leaf, PCNL, SENNLV, PROLFF#=, LTSEN=#) => begin
        senescence_leaf * (PCNL/100 - (SENNLV * (PCNL / 100 - PROLFF * 0.16) + PROLFF * 0.16))
        # LTSEN * (PCNL / 100 - PROLFF * 0.16)
    end ~ track(u"g/m^2/hr")

    SENNSV => 1 ~ preserve

    "Nitrogen mobilized from natural stem senescence"
    STSNMOB(senescence_stem, PCNST, SENNSV, PCNST, PROSTF#=, STLFSEN=#) => begin
        senescence_stem * (PCNST / 100 - (SENNSV * (PCNST / 100 - PROSTF * 0.16) + PROSTF * 0.16))
        #STLTSEN * (PCNST / 100 - PROSTF * 0.16)
    end ~ track(u"g/m^2/hr")

    SENNRV => 1 ~ preserve
    
    "Nitrogen mobilized from natural root senescence"
    RTSNMOB(senescence_root, PCNRT, SENNRV, PRORTF) => begin
        senescence_root * (PCNRT / 100 - (SENNRV * (PCNRT / 100 - PRORTF*0.16) + PRORTF*0.16))
    end ~ track(u"g/m^2/hr")

    SENNSRV => 1 ~ preserve

    "Nitrogen mobillized from natural storage senescence"
    SRSNMOB(senescence_storage, PCNSR, SENNSRV, PCNSR, PROSRF) => begin
        senescence_storage * (PCNSR / 100 - (SENNSRV * (PCNSR / 100 - PROSRF*0.16) + PROSRF*0.16))
    end ~ track(u"g/m^2/hr")

    #======================
    N mined from old tissue
    ======================#

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
    end ~ track

    "Photoperiod factor? (The value seems to be 1 anyways, given the parameters provided in DSSAT)"
    DRPP(CSDVAR, CLDVAR, THVAR, nounit(day_length)) => curve("inl", 1, CSDVAR, CLDVAR, THVAR, day_length) ~ track

    "Thermal factor (between 0 and 1)"
    TNTFAC(nounit(T_air)) => curve("lin", 3, 25, 33, 45, T_air) ~ track

    "Photo-thermal factor"
    TDUMX(TNTFAC, DRPP) => TNTFAC * DRPP ~ track

    "Relative rate of N mining during vegetative stage to that in reproductive stage"
    NVSMOB => 1 ~ preserve(parameter)

    "Maximum fraction of N which can be mobilized in an HOUR"
    NMOBMX => 1 - (1 - 0.08) ^ (1/24) ~ preserve(u"hr^-1", parameter)

    "Maximum fraction of C which can be mobilzed in an HOUR"
    CMOBMX => 1 - (1 - 0.055) ^ (1/24) ~ preserve(u"hr^-1", parameter)

    "Nitrogen mining rate"
    NMOBR(NVSMOB, NMOBMX, TDUMX) => begin
        NVSMOB * NMOBMX * TDUMX
    end ~ track(u"hr^-1")

    "Potential mobile N available from leaf (g[N]/m^2)"
    NMINELF(NMOBR, WNRLF) => NMOBR * WNRLF ~ track(u"g/m^2/hr")

    "Potential mobile N available from stem (g[N]/m^2)"
    NMINEST(NMOBR, WNRST) =>  NMOBR * WNRST ~ track(u"g/m^2/hr")

    # FIX
    PPMFAC => 1 ~ preserve(parameter)

    "Potential mobile N available from root (g[N]/m^2)"
    NMINERT(NMOBR, PPMFAC, WNRRT) => NMOBR * PPMFAC * WNRRT ~ track(u"g/m^2/hr")

    "Potential mobile N available from storage (g[N]/m^2)"
    NMINESR(NMOBR, WNRSR) => NMOBR * WNRSR ~ track(u"g/m^2/hr")

    #================
    Total N mobilized
    ================#

    "Maximum potential N mobilization from leaf (g[N]/m^2)"
    LFNMINE(LFSNMOB, NMINELF) => LFSNMOB + NMINELF ~ track(u"g/m^2/hr")

    "Maximum potential N mobilization from stem (g[N]/m^2)"
    STNMINE(STSNMOB, NMINEST) => STSNMOB + NMINEST ~ track(u"g/m^2/hr")

    "Maximum potential N mobilization from root"
    RTNMINE(RTSNMOB, NMINERT) => RTSNMOB + NMINERT ~ track(u"g/m^2/hr")

    "Maximum potential N mobilization from storage"
    SRNMINE(SRSNMOB, NMINESR) => SRSNMOB + NMINESR ~ track(u"g/m^2/hr")


    # "Potential whole-plant N mobilization from storage (g[N]/m^2/d)"
    # NMINEP(LFNMINE, STNMINE, RTNMINE, SRNMINE) => begin
    #     LFNMINE + STNMINE + RTNMINE + SRNMINE
    # end ~ track(u"g/m^2/hr")

    # "DSSAT4 potential N mobilization from storage (g[N)/m^2/d)"
    # NMINEO(NMINELF, NMINEST, NMINERT, NMINESR) => begin
    #     NMINELF + NMINEST + NMINERT + NMINESR
    # end ~ track(u"g/m^2/hr")

    "Total plant N mobilized from tissues lost to natural and low-light senescence"
    C_mobilized(LFNMINE, STNMINE, SRNMINE, RTNMINE) => begin
        LFNMINE + STNMINE + SRNMINE + RTNMINE
    end ~ track(u"g/m^2/hr")

    #==========================
    Potential CH2O mobilization
    ==========================#

    "Potential mobile CH2O available from leaf"
    CMINELF(CMOBMX, DTX, WCRLF, WF, PCHOLFF) => begin
        CMOBMX * DTX * (WCRLF - WF * PCHOLFF)
    end ~ track(u"g/m^2/hr")

    "Potential mobile CH2O available from stem"
    CMINEST(CMOBMX, DTX, WCRST, WS, PCHOSTF) => begin
        CMOBMX * DTX * (WCRST - WS * PCHOSTF)
    end ~ track(u"g/m^2/hr")

    "Potential mobile CH2O available from root"
    CMINERT(CMOBMX, DTX, WCRRT, WR, PCHORTF, PPMFAC) => begin
        CMOBMX * DTX * PPMFAC * (WCRRT - WR * PCHORTF)
    end ~ track(u"g/m^2/hr")

    # FIX
    "Potential mobile CH2O available from storage"
    CMINESR(CMOBMX, DTX, WCRSR, WSR, PCHOSRF) => begin
        CMOBMX * DTX * (WCRSR - WSR * PCHOSRF)
    end ~ track(u"g/m^2/hr")

    # LFSENWT(SENRTE, NMINELF) => SENRTE * NMINELF / 0.16 ~ track(max=WTLF)
    
    # STSENWT(LFSENWT, PORPT) => LFSENWT * PORPT ~ track

    # N_mined_actual(N_demand_new, N_uptake, N_mined_potential) => begin
    #     if N_demand_new - N_uptake > 1.e5 && N_mined_potential > 1.e4
    #         N_demand_new - N_uptake
    #     else
    #         0
    #     end
    # end ~ track

    # N_mined_R(N_mined_actual, N_mined_potential, N_mob_rate) => begin
    #     N_mined_actual / N_mined_potential * N_mob_rate
    # end ~ track

    # N_mobilized_leaf(N_mined_R, N_available_leaf)

    # N_mobilized_root(N_mined_R, N_available_root)

    # N_mobilized_stem(N_mined_R, N_available_stem)

    # #=
    # C mobilization
    # =#

    # LFSNMOB(senescence_leaf, PCNL, SENNLV) => begin
    #     LMDOT * (PCNL/100 - 
    #     (SENNLV * (PCNL / 100 - PROLFF*0.16) + PROLFF*0.16)) 
    #     + LTSEN * (PCNL / 100 - PROLFF * 0.16)
    # end

    # STSNMOB() => begin
    #     senescence_stem * (PCNST/100 - 
    #     (SENNSV * (PCNST / 100 - PROSTF*0.16) + PROSTF*0.16)) 
    #     + STLTSEN * (PCNST / 100 - PROSTF * 0.16)
    # end

    # SRSNMOB() => begin



    # "Potential mobile N available from leaf"
    # NMINELF(NMOBR, WNRLF) => NMOBR * WNRLF ~ track
    # ""
    # LFNMINE(LFSNMOB, NMINELF) => LFSNMOB + NMINELF ~ track

    # "Potential mobile N available from stem"
    # NMINEST(NMOBR, WNRST) => NMOBR * WNRST ~ track
    # ""
    # STNMINE(STSNMOB, NMINEST) => STSNMOB + NMINEST ~ track

    # "Potential mobile N available from root"
    # NMINERT(NMOBR, PPMFAC, WNRRT) => NMOBR * PPMFAC * WNRRT ~ track
    # ""
    # RTNMINE(RTSNMOB, NMINERT) => RTSNMOB + NMINERT ~ track

    # "Potential mobile N available from storage"
    # NMINESR(NMOBSR, WNRSR) => NMOBSR * WNRSR ~ track
    # ""
    # SRNMINE(SRSNMOB, NMINESR) => SRSNMOB + NMINESR ~ track
 
    # "Total plant N movilized from tissue lost to natural and low-light senescence"
    # TSNMOB(LFNMINE, STNMINE, RTNMINE, SRNMINE) => begin
    #     LFNMINE + STSNMINE + SRNMINE + RTNMINE
    # end ~ track(u"g/m^2/hr")
end