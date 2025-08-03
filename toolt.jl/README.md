# EmmysApp

A simple Toolips.jl web application that tracks client connections.

## Features

- Client connection tracking
- Simple HTTP server with route handling
- Extensible architecture using Toolips extensions
- Custom router example implementation

## Installation

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## Usage

### Starting the Server

```julia
using EmmysApp

# Start the server (assuming default Toolips conventions)
# Check the module documentation for exact method
```

### Routes

- `/` - Main route that greets clients with their connection number
- `/docs/toolips` - Auto-generated Toolips documentation

### Extensions

The application includes a custom extension (`load_clients`) that tracks the number of clients that have connected to the server.

## Project Structure

```
.
├── Project.toml      # Project dependencies and metadata
├── README.md         # This file
├── CLAUDE.md         # Developer guidance for Claude Code
├── src/
│   └── EmmysApp.jl   # Main module file
├── test/
│   └── runtests.jl   # Test suite
└── docs/             # Documentation directory
```

## Development

### Running Tests

```julia
using Pkg
Pkg.test()
```

### Adding New Routes

Routes can be added in the `src/EmmysApp.jl` file following the pattern:

```julia
new_route = route("/path") do c::Toolips.AbstractConnection
    # Route logic here
end
```

## Dependencies

- [Toolips.jl](https://github.com/ChifiSource/Toolips.jl) - Web framework for Julia

## License

[Add your license here]