# .env in project dir
# POSTGRES_HOST=localhost
# POSTGRES_PORT=5432
# POSTGRES_DB=mydb
# POSTGRES_USER=kh
# POSTGRES_PASSWORD=qian1long

using DotEnv
DotEnv.load!()

# Access the loaded environment variables
# db_host = ENV["POSTGRES_HOST"]
db_port = ENV["POSTGRES_PORT"]
# db_user = ENV["POSTGRES_USER"]
# db_pass = ENV["POSTGRES_PASS"]

# println("Database Host: ", db_host)
println("Database Port: ", db_port)
# println("Database User: ", db_user)
# println("Database Password: ", db_pass)
