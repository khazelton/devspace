# AppliedCategoryTheoryDDD.jl

A Julia package demonstrating Domain-Driven Design (DDD) principles through the lens of Category Theory.

## Overview

This package implements an identity management system using categorical concepts:

- **Objects**: Domain entities (Person, User, Account, LDAPEntry, Session)
- **Morphisms**: Domain operations that transform between entities
- **Composition**: Function composition with proper error handling via the Kleisli category
- **Functors**: Pipeline operations that preserve categorical structure
- **Natural Transformations**: Alternative implementations (e.g., LDAP vs OAuth)

## Installation

```julia
using Pkg
Pkg.add(path="/path/to/AppliedCategoryTheoryDDD")
```

## Quick Example

```julia
using AppliedCategoryTheoryDDD

# Create a person
person = Person(PersonId(uuid4()), "alice@example.com", "Alice Smith")

# Use the categorical pipeline to provision a new user
credentials = Dict("username" => "alice", "password" => "secure123")
result = pipeline(person, Standard, credentials)

if result isa Session
    println("Successfully created session!")
else
    println("Error: ", result.message)
end
```

## Key Concepts

### Domain Entities (Objects)

The package defines domain entities as objects in a category:

- `Person`: Initial object representing a person in the system
- `User`: Registered user with system identity
- `Account`: User account with type (Standard, Premium, Admin)
- `LDAPEntry`: Directory service entry
- `Session`: Authenticated session

### Morphisms (Transformations)

Functions that transform between domain entities:

- `register_person`: Person → User
- `add_user_account`: User × AccountType → Account
- `provision_to_ldap`: Account → LDAPEntry
- `authenticate`: LDAPEntry × Credentials → Session

### Error Handling (Kleisli Category)

All morphisms work in the Kleisli category for the error monad, returning `Union{T, DomainError}`:

- `RegistrationError`: Registration failures
- `AccountError`: Account creation failures
- `LDAPError`: LDAP provisioning failures
- `AuthError`: Authentication failures

### Composition

The package provides multiple ways to compose morphisms:

```julia
# Sequential composition with explicit error handling
result = provision_new_user(person, account_type, credentials)

# Pipeline composition using bind
result = pipeline(person, account_type, credentials)

# Custom composition using the ∘ operator
my_flow = authenticate ∘ provision_to_ldap ∘ add_user_account ∘ register_person
```

## Mathematical Foundation

This implementation satisfies key categorical laws:

1. **Identity**: Each type has an identity morphism
2. **Associativity**: Morphism composition is associative
3. **Functor Laws**: Error handling preserves composition
4. **Monad Laws**: The `Union{T, Error}` type with bind operation forms a monad

## Testing

Run the comprehensive test suite:

```julia
using Pkg
Pkg.test("AppliedCategoryTheoryDDD")
```

The tests verify:
- Individual morphism behavior
- Composition properties
- Error propagation
- Monad laws
- Functorial properties

## License

MIT License