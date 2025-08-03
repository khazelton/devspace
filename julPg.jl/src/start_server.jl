# Load the module
include("julPgModule.jl")
using .JulPgModule
using Toolips

println("Starting Toolips PostgreSQL app on http://127.0.0.1:8006")
println("API endpoint available at http://127.0.0.1:8006/api")

# Start the server
start!(JulPgModule, "127.0.0.1":8006)