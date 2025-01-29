include("boundarylayer.jl")
include("c3.jl")
include("energybalance.jl")
include("intercellularspace.jl")
include("irradiance.jl")
include("stomata.jl")
include("../../atmosphere/atmosphere.jl")


@system GasExchange(Atmosphere, BoundaryLayer, Calendar, Stomata, IntercellularSpace, Irradiance, EnergyBalance, C3) begin
    PPFD: photosynthetic_photon_flux_density ~ track(u"μmol/m^2/s" #= Quanta =#, override)
    LAI: leaf_area_index ~ track(override)
    drought_factor ~ track(override)

    A_net_total(A_net, LAI): net_photosynthesis_total => A_net * LAI ~ track(u"μmol/m^2/s" #= CO2 =#)
    A_gross_total(A_gross, LAI): gross_photosynthesis_total => A_gross * LAI ~ track(u"μmol/m^2/s" #= CO2 =#)
    E_total(E, LAI): transpiration_total => E * LAI ~ track(u"mmol/m^2/s" #= H2O =#)
end