@system Senescence begin
    Pstart: critical_photoperiod_threshold => 12.87 ~ preserve(parameter, u"hr")
    Tsen  : maximum_effective_temperature => 20.93 ~ preserve(parameter, u"°C")
    Ycrit : critical_senescence_threshold => 8513.52 ~ preserve(parameter)
    x     : temperature_proportion => 1        ~ preserve(parameter)
    y     : photoperiod_proportion => 1        ~ preserve(parameter)

    flag_senescence(T_air, Tsen, day_length, Pstart, d) => begin
        (T_air < Tsen) && (day_length < Pstart) && (200u"d" < d)
    end ~ flag
    
    rSen(day_length, Pstart, nounit(T_air), nounit(Tsen), x, y): senescence_rate => begin
        (Tsen - T_air)^x * (day_length / Pstart)^y / 24
    end ~ track(when=flag_senescence)

    sSen(rSen) ~ accumulate

    # dSen(rSen, var) => 

    # m(Ssen, Ycrit): match      => (Ssen >= Ycrit) ~ flag
end