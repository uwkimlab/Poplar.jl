"""
`SoilEnergy` keeps track of soil energy balance.
potential soil surface evaporation is determined from a modified Priestly-Taylor model
(Yan & Shugart, 2010) - doi:10.1029/2009JD013598
"""

@system SoilEnergy begin

    #=========
    Parameters
    =========#

    λ: latent_heat_of_vaporization_at_25 => 44 ~ preserve(u"kJ/mol", parameter) # should be a function of temp?
    Cp: specific_heat_of_air => 29.3 ~ preserve(u"J/mol/K", parameter)

    pt: priestly_taylor_parameter => 1.35 ~ preserve(parameter) # (Yan and Shugart, 2010)

    ghr: ground_heat_ratio => 0 ~ preserve(parameter) # ASSUMPTION: ground heat flux is negligible

    H2O_weight => 18.01528 ~ preserve(u"g/mol")
    H2O_density => 997 ~ preserve(u"kg/m^3")

    #=================
    =================#

    R_soil(solrad, R_sw): radiation_input_to_soil_surface => begin
        solrad - R_sw
    end ~ track(u"W/m^2")

    G(R_soil,ghr): ground_heat_flux => begin
        ghr * R_soil
    end ~ track(u"W/m^2")

    psychrometric_constant(Cp,P_air,λ) => begin
        Cp * P_air / λ
    end ~ track(u"kPa/K")

    λE_soil(pt,RH,R_soil,G,d=VPD_Δ,g=psychrometric_constant): soil_latent_heat_flux => begin
        pt * RH * d / (d + g) * (R_soil - G)
    end ~ track(u"W/m^2")

    E0_soil(λE_soil,λ): potential_soil_evaporation_mmol_per_m2_s => begin
        λE_soil / λ
    end ~ track(u"mmol/m^2/s")

    # Conversion to mm/hr to match water balance.
    "potential surface evaporation in mm/hr"
    potential_surface_evaporation(E0_soil, w=H2O_weight, d=H2O_density) => begin
        E0_soil * w / d
    end ~ track(u"mm/hr")

end