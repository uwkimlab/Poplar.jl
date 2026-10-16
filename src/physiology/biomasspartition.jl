@system BiomassPartition begin

    #===========
     Parameters
    ===========#
    
    # 1--constant; 2--allometric DBH (original 3PG); 3--allometric VI (Hart, 2015)
    "Switch parameter to control partitioning type"
    partition_type => 1 ~ preserve(parameter)
    
    # Parameters for  both allometric allocation types
    "Fertility rating"
    FR => 0.4582 ~ preserve(parameter) # 
    
    "Value of 'm1' when FR = 0"
    m0 => 0 ~ preserve(parameter)

    "Maximum foliage:stem partitioning ratio"
    pFSmax => 2 ~ preserve(parameter) # Hart 2015

    "Minimum foliage:stem partitioning ratio"
    pFSmin => 0.1 ~ preserve(parameter) # limit based on range of calibration from Pontailler (1997)
    
    "Maximum fraction of NPP to roots"
    pRx => 0.34 ~ preserve(parameter)
    
    "Minimum fraction of NPP to roots"
    pRn => 0.13 ~ preserve(parameter)

    
    # Parameters for DBH based allocation
    "Foliage:stem partitioning ratio at D=2cm"
    pFS2 => 0.8567 ~ preserve(parameter)
    
    "Foliage:stem partitioning ratio at D=20cm"
    pFS20 => 0.0590 ~ preserve(parameter)
    
    pfsPower(pFS2, pFS20) => log(pFS20 / pFS2) / log(20 / 2) ~ preserve
    
    pfsConst(pFS2, pfsPower) => pFS2 / 2 ^ pfsPower ~ preserve

    # xTODO: should we reincorporate soil water effect on root allocation? - CC 4/20/26
    # "Stomatal response to VPD"
    # coeffCond => 0.05 ~ preserve(parameter, u"mbar^-1")

    # xTODO: turn on this modifier, replace with our water_stress factor - 4/24/26 Modeling meeting discussion
    #   DONE -- 4/28/26 CC
    # soil water no longer uses these variables
    # "Soilwater modifier on root partitioning"
    # fSW(ASW, maxASW, SWconst, SWpower) => begin
    #     1 / (1 + ((1 - (ASW / maxASW)) / SWconst) ^ SWpower)
    # end ~ track

    # Leave this off - 4/24/26 Modeling meeting discussion
    # "VPD modifier on root partitioning"
    # fVPD(VPD, coeffCond) => begin
    #     exp(-coeffCond * VPD)
    # end ~ track

    # incorporating SW and Age effects, leaving out VPD - 4/24/26 Modeling meeting
    "Modifier for root partitioning based on VPD, SW, and Age"
    fPhysiology(fAge, water_stress) => begin
        water_stress * fAge
    end ~ track
    # fPhysiology(fVPD, fSW, fAge) => begin
    #     min(fVPD, fSW) * fAge
    # end ~ track
    

    # TODO: Better variable name? Empirical value used in foliage to stem ratio.
    m1(m0, FR) => m0 + (1 - m0) * FR ~ preserve
    
    # #Total partitionable (?) partition
    # # NPP_target ~ preserve(parameter, u"kg/ha/hr")

    # "Specifies the fractional amount of root biomass that exceeds the aboveground requirements that can be supplied in a given month."
    # frac => 0.02 ~ preserve(parameter)

    # "Specifies the efficiency in converting root biomass into aboveground biomass."
    # efficiency => 0.7  ~ preserve(parameter)

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
    
    # ratio of foliage to stem partitioning based on DBH allometry (original 3PG)
    pFS_dbh(pfsConst, nounit(avDBH), pfsPower) => pfsConst * avDBH ^ pfsPower ~ track

    # ratio of foliage to stem partitioning based on VI allometry (Hart, 2015)
    pFS_vi(avStemMass_g, avTargetWF_vi) => begin
        avTargetWF_vi / avStemMass_g 
    end ~ track

    # to account for regrowth after winter defoliation, increase pFS to pFSmax
    # if foliage mass is below target
    b_pfs: pfs_smoothing_factor => 0.1 ~ preserve(parameter, u"kg")
    "Ratio of foliage to stem parititioning"
    pFS(partition_type, pFS_dbh, pFS_vi, pFSmax, avFoliageMass, avTargetWF, BBCH_stage, b_pfs) => begin
        if partition_type == 1
            pFS_star = 0 # pFS not used if partition_type = 1
        elseif partition_type == 2 
            pFS_star = pFS_dbh
        elseif partition_type == 3
            pFS_star = pFS_vi
        else
            @error "Invalid partition_type: $partition_type. Use 1, 2 or 3 for constant, DBH or VI, respectively"  
        end
        if BBCH_stage == :BBCH30 && avTargetWF > avFoliageMass
            (pFSmax - pFS_star) * (avTargetWF - avFoliageMass) / (avTargetWF - avFoliageMass + b_pfs) + pFS_star
            # pFSmax + (pFS_star - pFSmax) * avFoliageMass / avTargetWF
        else
            pFS_star
        end
    end ~ track(max=pFSmax, min=pFSmin)
    # pFS(partition_type, pFS_dbh, pFS_vi, pFSmax, avFoliageMass, avTargetWF, BBCH_stage) => begin
    #     if partition_type == 1
    #         0 # pFS not used if partition_type = 1
    #     elseif (partition_type == 2 || partition_type == 3) 
    #         if avFoliageMass < avTargetWF && BBCH_stage == :BBCH30
    #             pFSmax
    #         elseif partition_type == 2 
    #             pFS_dbh
    #         elseif partition_type == 3
    #             pFS_vi
    #         end
    #     else
    #         @error "Invalid partition_type: $partition_type. Use 1, 2 or 3 for constant, DBH or VI, respectively"  
    #     end
    # end ~ track(max=pFSmax, min=pFSmin)

    # ratios for BBCH30 (shoot development)
    pR30(pRx, pRn, fPhysiology, m1) => pRx * pRn / (pRn + ( pRx - pRn) * fPhysiology * m1) ~ track # root partition
    pS30(pR30, pFS) => (1 - pR30) / (1 + pFS) ~ track # stem partition
    pF30(pR30, pS30) => 1 - pR30 - pS30 ~ track # foliage partition

    # ratios for BBCH90 (senescent)
    pR90(pR30, pF30) => pR30 + pF30/2 ~ track
    pS90(pR90) => 1 - pR90 ~ track

    "Root partitioning proportion"
    pR(partition_type, BBCH_stage, BBCH_table, pR30, pR90) => begin
        if partition_type != 1 && BBCH_stage == :BBCH30
            pR30
        elseif partition_type != 1 && BBCH_stage == :BBCH90
            pR90
        else
            BBCH_table[BBCH_stage].root
        end
    end ~ track # root partition

    "Stem partitioning proportion"
    pS(partition_type, BBCH_stage, BBCH_table, pS30, pS90) => begin
        if partition_type != 1 && BBCH_stage == :BBCH30
            pS30
        elseif partition_type != 1 && BBCH_stage == :BBCH90
            pS90
        else
            BBCH_table[BBCH_stage].stem
        end
    end ~ track # stem partition

    "Foliage paritioning proportion"
    pF(partition_type, BBCH_stage, BBCH_table, pF30) => begin
        if partition_type != 1 && BBCH_stage == :BBCH30
            pF30
        else
            BBCH_table[BBCH_stage].leaf
        end
    end ~ track
end
