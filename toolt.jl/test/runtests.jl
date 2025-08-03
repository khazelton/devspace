using EmmysApp
using Test
using Toolips

@testset "EmmysApp.jl" begin
    @testset "Module Exports" begin
        # Test that the module exports what we expect
        @test isdefined(EmmysApp, :start!)
        @test isdefined(EmmysApp, :main)
        @test isdefined(EmmysApp, :logger)
        @test isdefined(EmmysApp, :load_clients)
        @test isdefined(EmmysApp, :toolips_docs)
    end
    
    @testset "Extensions" begin
        # Test that the load_clients extension exists
        @test EmmysApp.load_clients isa Toolips.QuickExtension{:loadclients}
        
        # Test that logger exists
        @test EmmysApp.logger isa Toolips.Logger
    end
    
    @testset "Routes" begin
        # Test that main route exists
        @test EmmysApp.main isa Toolips.Route
        @test EmmysApp.main.path == "/"
        
        # Test that toolips_docs route exists
        @test EmmysApp.toolips_docs isa Toolips.Route
    end
    
    @testset "Custom Router Types" begin
        # Test that AbstractCustomRoute is defined
        @test isdefined(EmmysApp, :AbstractCustomRoute)
        @test isdefined(EmmysApp, :CustomRoute)
        
        # Test that CustomRoute has the expected fields
        cr = EmmysApp.CustomRoute("/test", () -> nothing)
        @test cr.path == "/test"
        @test cr.page isa Function
    end
end