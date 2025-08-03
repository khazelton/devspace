# julPg.
using Pkg
using DotEnv
using Plots
using Toolips
using Toolips: route, start!, Connection, AbstractConnection, write!
using Toolips.Components: div, h, p, a, button, form, input, table, tr, td, th, style!
# Define missing components
textarea(name::String; kwargs...) = Toolips.Components.Component("textarea", name; kwargs...)
using Tables
using ToolipsSession   
using LibPQ
using LibPQ: execute
using DataFrames

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Immutable Configuration =====

# Using `const` with NamedTuple creates an immutable data structure
# This follows the FP principle of avoiding mutable state
# Similar to: 
#   - Haskell: data Config = Config { host :: String, ... }
#   - TypeScript: readonly interface DbConfig { ... }
#   - Python: @dataclass(frozen=True) class DbConfig: ...

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Encapsulated State =====

# While mutable, the ConnectionPool encapsulates state changes
# This is similar to the State monad in Haskell or atoms in Clojure

mutable struct ConnectionPool
    connections::Vector{LibPQ.Connection}
    available::Vector{Bool}
    max_connections::Int
end

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Pure Function with Side Effects =====

# This function has side effects (creating connections) but returns
# a predictable result given the same inputs
# In pure FP languages, this would be wrapped in IO monad
function init_pool(config; max_connections=10)
    connections = LibPQ.Connection[]


    conn_string = "host=$(config.host) port=$(config.port) dbname=$(config.dbname) " * "user=$(config.user) password=$(config.password)"

    # Using list comprehension would be more functional:
    connections = [LibPQ.Connection(conn_string) for i in 1:max_connections]
    available = trues(max_connections)

    return ConnectionPool(connections, available, max_connections)
  end

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Partial Application =====

# These functions could be curried for partial application
# get_connection :: Pool -> (Connection, Index)

function get_connection(pool::ConnectionPool)
    # `findfirst` is a higher-order function that takes a predicate
    # Similar to: filter(id, pool.available)[0] in Python
    #            find id pool.available in Haskell
    idx = findfirst(pool.available)
    if idx === nothing
        error("No available connections in pool")
    end
    pool.available[idx] = false
    return pool.connections[idx], idx
end


function return_connection(pool::ConnectionPool, idx::Int)
    pool.available[idx] = true
end

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Higher-Order Function =====

# This is a classic HOF pattern - takes a function and applies it with resource management
# Similar patterns:
#   - Haskell: bracket :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c
#   - Python: with statement (context manager)
#   - TypeScript: async function withResource<T>(resource, fn: (r) => T): T
#   - Clojure: (with-open [conn (get-connection)] ...)
function with_connection(f::Function, pool::ConnectionPool)
    conn, idx = get_connection(pool)
    try
        # Apply the function to the connection
        return f(conn)
    finally
        # Ensure cleanup happens regardless of success/failure
        return_connection(pool, idx)
    end
end

# Initialize global connection pool
# In pure FP, this would be passed as a parameter to avoid global state

struct DbConfig
    host::String
    port::Int    
    dbname::String
    user::String
    password::String
end

config = DbConfig("localhost", 5432, "mydb", "kh", "qian1long")

println("Port = ", config.port)

const POOL = init_pool(config; max_connections=10)

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Side-Effect Function =====

# Database setup is inherently side-effectful
# In Haskell, this would return IO ()
function setup_database()
    # Using HOF to manage the connection lifecycle
    with_connection(POOL) do conn
        # Anonymous function (lambda) passed to with_connection
        execute(conn, """
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(100) UNIQUE NOT NULL,
                email VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        execute(conn, """
            CREATE TABLE IF NOT EXISTS posts (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id),
                title VARCHAR(255) NOT NULL,
                content TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
    end
end

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Function as Values (First-Class Functions) =====

# These are lambda expressions assigned to variables
# Demonstrates functions as first-class citizens
# Similar to:
#   - Haskell: queryUsers = \conn -> ...
#   - TypeScript: const queryUsers = (conn) => ...
#   - Python: query_users = lambda conn: ...
query_users = conn -> DataFrame(execute(conn, "SELECT * FROM users ORDER BY created_at DESC"))
query_posts = conn -> DataFrame(execute(conn, "SELECT * FROM posts ORDER BY created_at DESC"))

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Pure Functions with Parameters =====

# These functions are "pure" in terms of their database operations
# Given the same inputs, they produce the same SQL commands
function create_user(conn, username::String, email::String)
    execute(conn, """
        INSERT INTO users (username, email) 
        VALUES (\$1, \$2) 
        RETURNING id, username, email, created_at
    """, (username, email))
end

function create_post(conn, user_id::Int, title::String, content::String)
    execute(conn, """
        INSERT INTO posts (user_id, title, content) 
        VALUES (\$1, \$2, \$3)
        RETURNING id, title, content, created_at
    """, (user_id, title, content))
end

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Function Composition in HTML Generation =====

# The nested `do` blocks demonstrate function composition
# Each `h` function returns a component, and `do` blocks create anonymous functions
function main_route(c::Toolips.Connection)
    # Create main container
    container = div("container")
    style!(container, "max-width" => "800px", "margin" => "0 auto", "padding" => "20px")
    
    # Add heading
    push!(container, h("title", 1, text = "Toolips PostgreSQL Demo"))
    
    # Create User section
    push!(container, h("user-heading", 2, text = "Create User"))
    user_form = form("user-form", action = "/create-user", method = "POST")
    push!(user_form, input("username", type = "text", name = "username", placeholder = "Username", required = "true"))
    push!(user_form, input("email", type = "email", name = "email", placeholder = "Email", required = "true"))
    push!(user_form, button("submit-user", type = "submit", text = "Create User"))
    push!(container, user_form)
    
    # Users table section
    push!(container, h("users-heading", 2, text = "Users"))
    with_connection(POOL) do conn
        users = query_users(conn)
        if nrow(users) > 0
            users_table = table("users-table")
            # Header row
            header_row = tr("header-row")
            push!(header_row, th("id-header", text = "ID"))
            push!(header_row, th("username-header", text = "Username"))
            push!(header_row, th("email-header", text = "Email"))
            push!(header_row, th("created-header", text = "Created At"))
            push!(users_table, header_row)
            
            # Data rows
            for (i, row) in enumerate(eachrow(users))
                data_row = tr("user-row-$i")
                push!(data_row, td("id-$i", text = string(row.id)))
                push!(data_row, td("username-$i", text = row.username))
                push!(data_row, td("email-$i", text = row.email))
                push!(data_row, td("created-$i", text = string(row.created_at)))
                push!(users_table, data_row)
            end
            push!(container, users_table)
        else
            push!(container, p("no-users", text = "No users yet."))
        end
    end
    
    # Create Post section
    push!(container, h("post-heading", 2, text = "Create Post"))
    post_form = form("post-form", action = "/create-post", method = "POST")
    push!(post_form, input("user-id", type = "number", name = "user_id", placeholder = "User ID", required = "true"))
    push!(post_form, input("title", type = "text", name = "title", placeholder = "Title", required = "true"))
    push!(post_form, textarea("content", name = "content", placeholder = "Content", rows = "5"))
    push!(post_form, button("submit-post", type = "submit", text = "Create Post"))
    push!(container, post_form)
    
    # Posts table section
    push!(container, h("posts-heading", 2, text = "Posts"))
    with_connection(POOL) do conn
        posts = query_posts(conn)
        if nrow(posts) > 0
            posts_table = table("posts-table")
            # Header row
            header_row = tr("posts-header-row")
            push!(header_row, th("post-id-header", text = "ID"))
            push!(header_row, th("post-user-header", text = "User ID"))
            push!(header_row, th("post-title-header", text = "Title"))
            push!(header_row, th("post-content-header", text = "Content"))
            push!(header_row, th("post-created-header", text = "Created At"))
            push!(posts_table, header_row)
            
            # Data rows
            for (i, row) in enumerate(eachrow(posts))
                data_row = tr("post-row-$i")
                push!(data_row, td("post-id-$i", text = string(row.id)))
                push!(data_row, td("post-user-$i", text = string(row.user_id)))
                push!(data_row, td("post-title-$i", text = row.title))
                push!(data_row, td("post-content-$i", text = row.content))
                push!(data_row, td("post-created-$i", text = string(row.created_at)))
                push!(posts_table, data_row)
            end
            push!(container, posts_table)
        else
            push!(container, p("no-posts", text = "No posts yet."))
        end
    end
    
    write!(c, container)
end

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Pure Data Transformation =====

function create_user_route(c::Toolips.Connection)
    # Extract data using `get` with default values - defensive programming
    username = get(c.data, "username", [""])[1]
    email = get(c.data, "email", [""])[1]
    
    # Guard clause pattern - early return for invalid inputs
    if !isempty(username) && !isempty(email)
        try
            with_connection(POOL) do conn
                create_user(conn, username, email)
            end
        catch e
            # Error handling without mutation
            write!(c, "<h1>Error creating user: $(e)</h1><a href='/'>Go back</a>")
            return
        end
    end
    
    # Immutable response pattern
    c.http.status = 302
    push!(c.http.headers, "Location" => "/")
    write!(c, "")
end

function create_post_route(c::Toolips.Connection)
    # ===== FUNCTIONAL PATTERN: Safe Parsing with Maybe/Option Pattern =====

    # tryparse returns nothing (like Maybe/Option in Haskell/Rust)
    user_id = tryparse(Int, get(c.data, "user_id", ["0"])[1])
    title = get(c.data, "title", [""])[1]
    content = get(c.data, "content", [""])[1]
    
    # Pattern matching on Maybe-like value
    if user_id !== nothing && user_id > 0 && !isempty(title)
        try
            with_connection(POOL) do conn
                create_post(conn, user_id, title, content)
            end
        catch e
            write!(c, "<h1>Error creating post: $(e)</h1><a href='/'>Go back</a>")
            return
        end
    end
    
    c.http.status = 302
    push!(c.http.headers, "Location" => "/")
    write!(c, "")
end

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Function Composition =====

function api_route(c::Toolips.Connection)
    # ===== FUNCTIONAL PATTERN: Function Composition =====
    # Creates a new function by composing smaller functions
    # Similar to:
    #   - Haskell: fetchAllData = liftA2 (,) queryUsers queryPosts
    #   - TypeScript: const fetchAllData = pipe(queryUsers, queryPosts)
    fetch_all_data = conn -> (
        users = query_users(conn),
        posts = query_posts(conn)
    )
    
    # Apply the composed function
    data = with_connection(POOL) do conn
        fetch_all_data(conn)
    end
    
    # ===== FUNCTIONAL PATTERN: List Comprehension =====

    # Transform data using comprehensions - functional alternative to loops
    # Similar to:
    #   - Haskell: [User{..} | row <- users]
    #   - Python: [{"id": row.id, ...} for row in data.users]
    response = Dict(
        "users" => [Dict("id" => row.id, "username" => row.username, 
                        "email" => row.email, "created_at" => string(row.created_at)) 
                   for row in eachrow(data.users)],
        "posts" => [Dict("id" => row.id, "user_id" => row.user_id,
                        "title" => row.title, "content" => row.content,
                        "created_at" => string(row.created_at))
                   for row in eachrow(data.posts)]
    )
    
    c.http.headers["Content-Type"] = "application/json"
    write!(c, string(response))
end

# Wrap everything in a module for Toolips
module JulPgApp

using Toolips
using Toolips: route, Connection, write!
using Toolips.Components: div, h, p, a, button, form, input, table, tr, td, th, style!

# Import dependencies from Main
using Main: POOL, with_connection, query_users, query_posts, create_user, create_post, textarea, setup_database
using Main: main_route, create_user_route, create_post_route, api_route
using DataFrames: nrow, eachrow

# Initialize database
setup_database()

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Data as Configuration =====

# Routes defined as data structures, not imperative code
# This is declarative routing - similar to:
#   - Haskell Servant: type API = "users" :> Get '[JSON] [User]
#   - Clojure Compojure: (defroutes app (GET "/" [] main-handler))

# Create routes - must use Toolips.route since we're in a module
home = route(main_route, "/")
create_user_r = route(create_user_route, "/create-user")
create_post_r = route(create_post_route, "/create-post")
api = route(api_route, "/api")

# Export start! and all routes
export start!, home, create_user_r, create_post_r, api

end # module JulPgApp

# ===== FUNCTIONAL PROGRAMMING CONCEPT: Declarative Server Configuration =====

# Server configuration through data, not imperative setup
# Create and start server directly
println("Starting Toolips PostgreSQL app on http://127.0.0.1:8006")
println("API endpoint available at http://127.0.0.1:8006/api")

# Start the server
Toolips.start!(JulPgApp, "127.0.0.1":8006)

# ===== FUNCTIONAL PROGRAMMING PRINCIPLES DEMONSTRATED =====

# 1. Immutability: const DB_CONFIG, route definitions
# 2. Higher-Order Functions: with_connection, map operations
# 3. Function Composition: HTML builders, fetch_all_data
# 4. First-Class Functions: query_users, query_posts as values
# 5. Declarative Style: Route configuration, HTML generation
# 6. Pure Functions: Most query builders and transformations
# 7. Lazy Evaluation: eachrow iterators
# 8. Pattern Matching: tryparse with nothing checks
# 9. Referential Transparency: Configuration and route definitions
# 10. Side Effect Management: Isolated in with_connection blocks

