@system Thinning begin
    thinning_date => [] ~ preserve::Vector(parameter, optional)
    thinning_value => [] ~ preserve::Vector(parameter, optional)
    thinning_WF => [] ~ preserve::Vector(parameter, optional)
    thinning_WS => [] ~ preserve::Vector(parameter, optional)
    thinning_WR => [] ~ preserve::Vector(parameter, optional)

    flag_thinning(thinning_date, date) => begin
        date in thinning_date
    end ~ flag

    thinning(date, thinning_date, thinning_value) => begin
        index = findfirst(x -> x == date, defoliation_date)
        defoliation_value[index]
    end ~ track(when=flag_defoliation)
end