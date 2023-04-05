@system Defoliation begin
    defoliation_time => [] ~ preserve::Vector(parameter, optional)
    defoliation_value => [] ~ preserve::Vector(parameter, optional)

    flag_defoliation(defoliation_time, time) => begin
        time in defoliation_time
    end ~ flag

    defoliation(time, defoliation_time, defoliation_value, WF) => begin
        index = findfirst(x -> x == time, defoliation_time)
        WF * defoliation_value[index] / u"hr"
    end ~ track(u"kg/ha/hr", when=flag_defoliation)
end