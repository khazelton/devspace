module JulPgModule

using Pkg
using DotEnv
using Plots
using Toolips
using Toolips: route, WebServer, Connection, AbstractConnection, write!
using Toolips.Components: div, h, p, a, button, form, input, table, tr, td, th, style!
# Define missing components
textarea(name::String; kwargs...) = Toolips.Components.Component("textarea", name; kwargs...)
using Tables
using ToolipsSession   
using LibPQ
using LibPQ: execute
using DataFrames

# Database configuration
mutable struct ConnectionPool
    connections::Vector{LibPQ.Connection}
    available::Vector{Bool}
    max_connections::Int
end

function init_pool(config; max_connections=10)
    connections = LibPQ.Connection[]
    conn_string = "host=$(config.host) port=$(config.port) dbname=$(config.dbname) " * "user=$(config.user) password=$(config.password)"
    connections = [LibPQ.Connection(conn_string) for i in 1:max_connections]
    available = trues(max_connections)
    return ConnectionPool(connections, available, max_connections)
end

function get_connection(pool::ConnectionPool)
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

function with_connection(f::Function, pool::ConnectionPool)
    conn, idx = get_connection(pool)
    try
        return f(conn)
    finally
        return_connection(pool, idx)
    end
end

struct DbConfig
    host::String
    port::Int    
    dbname::String
    user::String
    password::String
end

config = DbConfig("localhost", 5432, "mydb", "kh", "qian1long")
const POOL = init_pool(config; max_connections=10)

function setup_database()
    with_connection(POOL) do conn
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

query_users = conn -> DataFrame(execute(conn, "SELECT * FROM users ORDER BY created_at DESC"))
query_posts = conn -> DataFrame(execute(conn, "SELECT * FROM posts ORDER BY created_at DESC"))

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

function create_user_route(c::Toolips.Connection)
    username = get(c.data, "username", [""])[1]
    email = get(c.data, "email", [""])[1]
    
    if !isempty(username) && !isempty(email)
        try
            with_connection(POOL) do conn
                create_user(conn, username, email)
            end
        catch e
            write!(c, "<h1>Error creating user: $(e)</h1><a href='/'>Go back</a>")
            return
        end
    end
    
    c.http.status = 302
    push!(c.http.headers, "Location" => "/")
    write!(c, "")
end

function create_post_route(c::Toolips.Connection)
    user_id = tryparse(Int, get(c.data, "user_id", ["0"])[1])
    title = get(c.data, "title", [""])[1]
    content = get(c.data, "content", [""])[1]
    
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

function api_route(c::Toolips.Connection)
    fetch_all_data = conn -> (
        users = query_users(conn),
        posts = query_posts(conn)
    )
    
    data = with_connection(POOL) do conn
        fetch_all_data(conn)
    end
    
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

# Initialize database
setup_database()

# Define routes
home = route(main_route, "/")
create_user_r = route(create_user_route, "/create-user")
create_post_r = route(create_post_route, "/create-post")
api = route(api_route, "/api")

# Export everything needed
export start!, home, create_user_r, create_post_r, api

end # module