@system Soil begin
    T_soil => 10 ~ track(u"°C")
    WP_leaf => 0 ~ track(u"MPa") # pressure - leaf water potential MPa...
    total_root_weight => 0 ~ track(u"g")
end