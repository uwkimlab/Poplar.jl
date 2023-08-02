"Age-related variables"
@system Age begin
    #=========
    Parameters
    =========#
    "Initial age"
    iAge => 1 ~ preserve(parameter, u"yr") # Initial age 

    "Stand age (hours)"
    stand_age_hour ~ advance(u"hr", init=iAge)

    "Stand age (years)"
    stand_age_year(stand_age_hour) ~ track(u"yr")

    # Stand age without units due to empirical formulas with conflicting units.
    "Stand age"
    stand_age(nounit(stand_age_year)) ~ track
end