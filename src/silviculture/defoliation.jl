@system Defoliation begin

    # Defining defoliation dates and values
    # Example of configuration in config.jl
    
    defoliation_date => [] ~ preserve::Vector(parameter, optional)
    defoliation_value => [] ~ preserve::Vector(parameter, optional)

    flag_defoliation(defoliation_date, time) => begin
        time in defoliation_date
    end ~ flag

    defoliation(time, defoliation_date, defoliation_value, WF) => begin
        index = findfirst(x -> x == time, defoliation_date)
        WF * defoliation_value[index] / u"hr"
    end ~ track(u"kg/ha/hr", when=flag_defoliation)
end