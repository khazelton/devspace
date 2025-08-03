# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Toolips.jl web application project. The main application module is `EmmysApp` located in `src/EmmysApp.jl` - a simple HTTP server that tracks client connections.

## Project Structure

```
.
├── Project.toml       # Julia project manifest with dependencies
├── src/
│   └── EmmysApp.jl    # Main application module
├── test/
│   └── runtests.jl    # Test suite
├── docs/              # Documentation directory
└── README.md          # Project documentation
```

## Key Architecture

### Module Structure
- Single module `EmmysApp` in `src/EmmysApp.jl`
- Uses Toolips web framework extensions for state management
- Client tracking implemented via `QuickExtension{:loadclients}`

### Core Components
1. **Server Extension**: Manages client count using server data dictionary
2. **Router**: Basic route handling with example custom router pattern
3. **Logger**: Simple logging functionality for tracking requests

## Development Commands

```julia
# Activate the project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Run tests
Pkg.test()

# Start the application
using EmmysApp
# Check the module for exact server start method
```

## Important Notes

1. **Standard Julia Structure**: The project now follows standard Julia package conventions with Project.toml and proper directory structure.

2. **Commented Features**: The code contains commented-out functionality for:
   - Public directory mounting
   - Components documentation route
   These may need to be implemented or removed based on requirements.

3. **Extension Pattern**: The app uses Toolips' extension system. When modifying, ensure compatibility with the `on_start` and `route!` methods.

4. **Testing**: Basic test suite exists in `test/runtests.jl`. Add tests for new features.

## Common Tasks

### Adding New Routes
Routes are defined in `src/EmmysApp.jl`. Follow the existing pattern:
```julia
new_route = route("/path") do c::Toolips.AbstractConnection
    # Route logic here
end
```

### Modifying Client Tracking
Client count is stored in `c[:clients]`. Access and modify through the server extension methods.

### Running Tests
```julia
using Pkg
Pkg.test()
```

### Working with Toolips
Refer to Toolips.jl documentation for framework-specific patterns and best practices.