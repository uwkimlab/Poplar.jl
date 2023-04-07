@system Senescence begin
    # Pstart: critical_photoperiod_threshold ~ preserve(parameter)
    # Tb    : maximum_effective_temperature  ~ preserve(parameter, u"°C")
    # Ycrit : critical_senescence_threshold  ~ preserve(parameter)
    # x     : temperature_proportion         ~ preserve(parameter)
    # y     : photoperiod_proportion         ~ preserve(parameter)
    
    # YEAR(t = calendar.last) => Dates.year(t) ~ preserve::int
    # Sday(t): day_of_year    => Dates.dayofyear(t) ~ track::int(u"d")
    # Δt(context.clock.step) ~ preserve(u"d")
    
    # Rsen(Pd, Pstart, nounit(Td), nounit(Tb), x, y): senescence_rate => begin
    #     if Td < Tb && Pd < Pstart
    #         (Tb - Td)^x * (Pd/Pstart)^y
    #     else
    #         0
    #     end
    # end ~ track
    # Ssen(Rsen): senescence_accumulated ~ accumulate

    # m(Ssen, Ycrit): match      => (Ssen >= Ycrit) ~ flag
    # stop(m, s = calendar.stop) => (m || s)  ~ flag
end