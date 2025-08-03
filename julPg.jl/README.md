# JulPgProject

A Julia web application demonstrating functional programming concepts with PostgreSQL integration using Toolips framework.

## Features

- PostgreSQL database integration with connection pooling
- Web interface for managing users and posts
- RESTful API endpoints
- Demonstrates functional programming patterns in Julia

## Installation

```bash
cd JulPgProject
julia --project=.
```

In the Julia REPL:
```julia
using Pkg
Pkg.instantiate()
```

## Configuration

Set the following environment variables for database connection:
- `POSTGRES_HOST` (default: "localhost")
- `POSTGRES_PORT` (default: "5432")
- `POSTGRES_DB` (default: "julia_fp_demo")
- `POSTGRES_USER` (default: "postgres")
- `POSTGRES_PASSWORD` (default: "password")

## Running the Application

```julia
include("src/julPg.jl")
```

The server will start on `http://127.0.0.1:8006`

## Project Structure

```
JulPgProject/
├── Project.toml          # Project dependencies
├── src/
│   ├── JulPgProject.jl   # Main module file
│   └── julPg.jl          # Application code
├── test/
│   └── runtests.jl       # Test suite
├── docs/                 # Documentation directory
├── .gitignore           # Git ignore file
└── README.md            # This file
```

## Testing

Run tests with:
```julia
using Pkg
Pkg.test()
```