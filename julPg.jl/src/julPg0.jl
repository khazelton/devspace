# julPg.
using Pkg
Pkg.add("DotEnv")
using DotEnv
Pkg.add("Plots")
using Plots
Pkg.add("Toolips")
using Toolips
Pkg.add("ToolipsSession")
using ToolipsSession
Pkg.add("Compat")
using Compat
Pkg.add("LibPQ")
using LibPQ
Pkg.add("Tables")
using Tables
Pkg.add("DataFrames")
using DataFrames

function main()
    time = 0:0.01:10             # step range from 0 to 10 step 0.1
    u = sin.(time * 5)          # signal with a frequency of 5 rad/s
    step = 1 .- 1 ./ exp.(time)  # step response
    df = DataFrame(; time, u, step)
    plt = plot(df.time, u, legend=false)
    plot!(df.time, step)
    plt
end
plt = main()
