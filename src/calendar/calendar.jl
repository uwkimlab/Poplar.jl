"""
Calendar keeps track of date and time-related variables.
"""
@system Calendar begin
    "Initial date"
    init ~ preserve::datetime(extern, parameter)

    "Last date"
    last => nothing ~ preserve::datetime(extern, parameter, optional)

    "Time"
    time(t0=init, t=context.clock.time) => t0 + convert(Cropbox.Dates.Second, t) ~ track::datetime

    "Date"
    date(time) => Cropbox.Dates.Date(time) ~ track::date

    "Timestep"
    step(context.clock.step) ~ preserve(u"hr")

    stop(time, last) => begin
        isnothing(last) ? false : (time >= last)
    end ~ flag

    count(init, last, step) => begin
        if isnothing(last)
            nothing
        else
            (last - init) / step
        end
    end ~ preserve::int(round, optional)

    "Day of year"
    d(time) => Dates.dayofyear(time) ~ track::int(u"d")
    
    "Hour of day"
    h(time) => Dates.hour(time) ~ track::int(u"hr")
end