using Pkg; Pkg.add("ToolipsServables")
# or with the web-framework `Toolips`:
using Pkg; Pkg.add("Toolips")

using ToolipsServables
# using Toolips.Components

# creating components
myd::Component{:div} = div("example", text = "hello world!")

myheading::Component{:h1} = h1("myheading", text = "example")

elements::Vector{<:AbstractComponent} = [p("example", text = e) for e in 1:10]

# composing components
style!(myheading, "color" => "white", "font-size" => 10pt)
push!(myd, myheading)
set_children!(myheading, elements)
# writing components
buff = IOBuffer()
write!(buff, myd)
str = ""
write!(str, myd)
using Toolips
c = Toolips.SpoofConnection()
write!(c, myd)
