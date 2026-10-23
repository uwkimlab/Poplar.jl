using Poplar
using Test
using Cropbox

@testset "Poplar.jl" begin
    include("waterbalance.jl")
    include("irrigation_integration.jl")
    include("budburst.jl")
    include("conversion.jl")
    include("senescence.jl")
    include("stomata.jl")
    @testset "default soil parameter construction" begin
        s = instance(Model; config=Poplar.config_Model)
        @test s.maxSW' == 1004u"mm"
        # Record the existing initialization clamp; this is not a new water input.
        @test s.iSW' == 200u"mm"
        @test s.SW' == s.minSW' == 368u"mm"
    end
end
