@system Thinning begin
    
    # Defining thinning dates, values and ratios
    # Probably should use a tabulate variable instead
    # Example of configuration in config.jl

    thinning_date => [] ~ preserve::Vector(parameter, optional)
    thinning_value => [] ~ preserve::Vector(parameter, optional)
    thinning_F => [] ~ preserve::Vector(parameter, optional)
    thinning_S => [] ~ preserve::Vector(parameter, optional)
    thinning_R => [] ~ preserve::Vector(parameter, optional)

    flag_thinning(thinning_date, time) => begin
        time in thinning_date
    end ~ flag

    thinning_index(time, thinning_date) => begin
        findfirst(x -> x == time, thinning_date)
    end ~ track::Int(when=flag_thinning)

    thinning(stemNo, thinning_index, thinning_value) => begin
        (stemNo - thinning_value[thinning_index]) / u"hr"
    end ~ track(u"ha^-1/hr", when=flag_thinning)

    delN(stemNo, thinning) => begin
         thinning * u"hr" / stemNo
    end ~ track(when=flag_thinning)

    thinning_WF(thinning_index, delN, thinning_date, thinning_F, WF) => begin
        WF * delN * thinning_F[thinning_index] / u"hr"
    end ~ track(u"kg/ha/hr", when=flag_thinning)

    thinning_WS(thinning_index, delN, stemNo, thinning_date, thinning_S, WS) => begin
        WS * delN * thinning_S[thinning_index] / u"hr"
    end ~ track(u"kg/ha/hr", when=flag_thinning)

    thinning_WR(thinning_index, delN, stemNo, thinning_date, thinning_R, WR) => begin
        WR * delN * thinning_R[thinning_index] / u"hr"
    end ~ track(u"kg/ha/hr", when=flag_thinning)
end