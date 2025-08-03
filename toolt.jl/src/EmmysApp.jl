module EmmysApp

using Toolips
# using Toolips.Components
    
#== extensions ==#
# Logger: A Toolips utility for tracking and recording server events
# Creates a logging instance that can write messages to track application behavior
logger = Toolips.Logger()
        
# QuickExtension: A lightweight extension system in Toolips for adding functionality
# The {:loadclients} symbol creates a parameterized type that uniquely identifies this extension
# Extensions in Toolips allow modular server behavior without modifying core functionality
load_clients = Toolips.QuickExtension{:loadclients}()

# creating a server extension (QuickExtension):
import Toolips: route!, on_start

# on_start: Called when the server starts, used for initialization
# Parameters:
#   - ext: The extension being initialized
#   - data: Server's shared data dictionary for storing state across requests
#   - routes: Vector of all registered routes in the application
function on_start(ext::Toolips.QuickExtension{:loadclients}, data::Dict{Symbol, Any}, 
    routes::Vector{<:AbstractRoute})
    # Initialize a client counter in the server's data storage
    # This will persist across all requests and connections
    data[:clients] = 0
end

# route!: Called for each incoming request, allows extensions to process connections
# This method is invoked before the main route handler
# Parameters:
#   - c: The connection object containing request/response data
#   - ext: The extension processing this connection
function route!(c::AbstractConnection, ext::Toolips.QuickExtension{:loadclients})
    # Increment the client counter for each new connection
    # The connection object acts like a dictionary for storing request-scoped data
    c[:clients] += 1
end

#== routes ==#

# route: Creates an HTTP endpoint that responds to requests
# The do-block syntax creates an anonymous function that handles the request
# Parameter c is an AbstractConnection containing all request/response functionality
main = route("/") do c::Toolips.AbstractConnection
    # get_post: Extracts POST data from the request (form submissions, JSON, etc.)
    post_data = get_post(c)
    
    # get_args: Extracts URL query parameters (e.g., ?name=value&foo=bar)
    args = get_args(c)
    
    # Access the client number from the connection's data storage
    # This was set by our extension's route! method
    client_number = string(c[:clients])
    
    # log: Records an event using our logger instance
    log(logger, "served client " * client_number)
    
    # write!: Sends response data back to the client
    # Can write strings, HTML, or other content types
    write!(c, "hello client #" * client_number)
end

# files:
# mount: Creates a static file server route
# Maps URL path "/public" to local directory "public"
# Uncomment to serve CSS, JS, images, etc.
public = mount("/public" => "public")

# make your own documentation: (/docs/toolips && /docs/toolipsservables)
# (this works with any module)
# make_docroute: Automatically generates documentation pages for any Julia module
# Creates interactive documentation browser at /docs/[modulename]
# Extracts docstrings and function signatures from the specified module
toolips_docs = Toolips.make_docroute(Toolips)

components_docs = Toolips.make_docroute(Toolips.Components)

#== custom router example ==#
# custom router? no problem!

# AbstractHTTPRoute: Base type for all HTTP routes in Toolips
# Creating a subtype allows custom routing logic beyond standard path matching
abstract type AbstractCustomRoute <: Toolips.AbstractHTTPRoute end

# Custom route implementation that can have specialized behavior
# Could be used for pattern matching, authentication, or other routing logic
mutable struct CustomRoute <: AbstractCustomRoute
    path::String
    page::Function
end
# Custom router implementation
# This route! method demonstrates how to create custom routing logic
# It's called for routes of type AbstractCustomRoute instead of standard routes
# Parameters:
#   - c: The connection object
#   - routes: Collection of routes with our custom type
route!(c::AbstractConnection, routes::Routes{AbstractCustomRoute}) = begin
    # get_target: Retrieves the requested URL path from the connection
    target = get_target(c)
    
    # Example custom routing logic: check if URL contains "@" (like a username)
    # This could be used for user profile pages like "/user/@johndoe"
    if contains(target, "@")
        # File: Represents a file to be served to the client
        # This would serve a static HTML file for user profiles
        write!(c, File("user_html/@sampleuser.html"))
    end
end

# make sure to export!
# Export symbols that should be available when the module is used
# - start!: The server startup function (provided by Toolips)
# - main: Our main route handler
# - default_404: Default 404 error handler (from Toolips)
# - logger: Our logging instance
# - load_clients: Our client tracking extension
# - toolips_docs: The auto-generated documentation route
export start!, main, default_404, logger, load_clients, toolips_docs #, components_docs
end # - module EmmysApp <3