@system Calendar begin
    init ~ preserve::datetime(extern, parameter)
    last => nothing ~ preserve::datetime(extern, parameter, optional)
    time(t0=init, t=context.clock.time) => t0 + convert(Cropbox.Dates.Second, t) ~ track::datetime
    date(time) => Cropbox.Dates.Date(time) ~ track::date
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

    d(time) => Dates.dayofyear(t) ~ track::int(u"d")
    h(time) => Dates.hour(t) ~ track::int(u"hr")
end