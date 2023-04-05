@system Coppicing begin
    coppicing_date => [] ~ preserve::Vector(parameter, optional)
    coppicing_value => [] ~ preserve::Vector(parameter, optional)

    flag_coppicing(coppicing_date, date) => begin
        date in coppicing_date
    end ~ flag

    coppicing(coppicing_date, coppicing_value, date) => begin
        index = findfirst(x -> x == date, coppicing_date)
        coppicing_value[index]
    end ~ track(when=flag_coppicing)
end