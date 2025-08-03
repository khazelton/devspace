# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace Overview

This is a multi-project workspace focused on scientific computing, applied category theory, and web development. The workspace contains several independent projects, primarily using Julia for mathematical computing and Python for data analysis.

## Common Development Commands

### Julia Projects

For most Julia projects in this workspace:

```julia
# Activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Run tests
Pkg.test()

# Build documentation (if docs/ exists)
julia docs/make.jl
```

### TypeScript/React Projects

For the openid-federation-browser project:

```bash
npm install
npm start      # Development server
npm run build  # Production build
npm run lint   # Run Prettier
npm run proxy  # Run proxy server
```

### Python Projects

For projects with Pipfile (e.g., Py3.pyt):
```bash
pipenv install
pipenv shell
```

For projects with requirements:
```bash
pip install -r requirements.txt
```

## Code Architecture

### Major Project Categories

1. **AlgebraicJulia Ecosystem** - Applied category theory libraries:
   - `Catlab.jl/` - Core framework for computational category theory
   - `AlgebraicDynamics.jl/` - Dynamical systems using category theory
   - `AlgebraicPetri.jl/` - Petri net modeling with algebraic approach
   - `StockFlow.jl/` - Stock and flow modeling framework

2. **Scientific Computing**:
   - `DifferentialEquations.jl/` - Comprehensive differential equation solving
   - `SciMLTutorials.jl/` - Scientific machine learning tutorials

3. **Web Applications**:
   - `openid-federation-browser/` - React/TypeScript OpenID federation tool
   - `toolt.jl/` - Toolips.jl web application (EmmysApp)
   - `julPg.jl/` - Julia web project

4. **Educational Resources**:
   - `tutorials.jl/` - Extensive Julia tutorial series (Series 01-10)
   - `MEsnbs.jl/` - Multi-language notebook collection (Julia, Python, R, C++, Scala)

5. **Specialized Tools**:
   - `mcp.jl/` - Model Context Protocol implementation for Julia
   - `heIam/` - Identity management with category theory
   - `i2Gpt-01/` - Python web scraper for Grouper wiki

### Key Patterns

1. **Julia Package Structure**: Most Julia projects follow standard structure:
   - `src/` - Source code
   - `test/` - Test files
   - `docs/` - Documentation
   - `Project.toml` - Package manifest

2. **Testing**: Julia projects typically use the built-in test framework. Run with `Pkg.test()`.

3. **Documentation**: Major libraries (Catlab, DifferentialEquations) have comprehensive documentation built with Documenter.jl.

4. **Notebooks**: Extensive use of Jupyter notebooks for experimentation and learning, especially in MEsnbs.jl and pyNBooks.pyt directories.

## Important Notes

1. **Git Structure**: Many subdirectories are independent git repositories. Check git status within each project directory.

2. **Julia Environment**: Always activate the project environment before working to ensure correct dependencies.

3. **Category Theory Focus**: Many projects apply category theory concepts. Familiarity with Catlab.jl is helpful when working across the AlgebraicJulia ecosystem.

4. **Mixed Maturity**: Projects range from mature libraries to experimental code. Some projects (like i2Gpt-01) may have syntax errors that need fixing.

5. **Language Versions**: Check Julia version compatibility in Project.toml files. Most projects target Julia 1.6+.