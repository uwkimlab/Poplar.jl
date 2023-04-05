@system Defoliation begin
    defoliation_date => [] ~ preserve::Vector(parameter, optional)
    defoliation_value => [] ~ preserve::Vector(parameter, optional)

    flag_defoliation(defoliation_date, date) => begin
        date in defoliation_date
    end ~ flag

    defoliation(date, defoliation_date, defoliation_value, WF) => begin
        index = findfirst(x -> x == date, defoliation_date)
        WF * defoliation_value[index] / u"hr"
    end ~ track(u"kg/ha/hr", when=flag_defoliation)
end