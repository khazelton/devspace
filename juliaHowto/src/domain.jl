# ============================================================================
# CATEGORY THEORY FOUNDATION
# Our domain forms a category where:
# - Objects: Domain types (Person, User, Account, LDAPEntry, Session)
# - Morphisms: Domain operations (register_person, add_user_account, etc.)
# - Composition: Function chaining with error handling
# ============================================================================

# Abstract type hierarchy represents the categorical structure
abstract type DomainEntity end  # Objects in our category
abstract type DomainError end   # Error objects (in the Kleisli category for error monad)

# ============================================================================
# OBJECTS IN THE CATEGORY
# Each struct represents an object in our domain category
# The fields represent the internal structure (in CT: elements of the object)
# ============================================================================

# Wrapper types act as identity morphisms (id: PersonId → PersonId)
struct PersonId
    value::UUID
end

# Person is an object in our category
struct Person <: DomainEntity
    id::PersonId
    email::String
    full_name::String
end

struct UserId
    value::UUID
end

# User is another object, with an arrow from Person
struct User <: DomainEntity
    id::UserId
    person_ref::PersonId  # Maintains reference - shows Person → User is not monic
    created_at::DateTime
end

struct AccountId
    value::UUID
end

# Enum represents a coproduct (sum type) in category theory
# AccountType ≅ Standard + Premium + Admin
@enum AccountType Standard Premium Admin

struct Account <: DomainEntity
    id::AccountId
    owner_id::UserId  # Reference shows this comes after User in the composition chain
    account_type::AccountType
end

struct LDAPEntry <: DomainEntity
    distinguished_name::String
    uid::String
    account_ref::AccountId  # Preserves the morphism chain
end

struct SessionToken
    value::String
end

struct Session <: DomainEntity
    token::SessionToken
    ldap_dn::String  # References LDAP, showing the morphism dependency
    expires_at::DateTime
end

# ============================================================================
# ERROR HANDLING: KLEISLI CATEGORY
# We're working in the Kleisli category for the error monad
# Union{T, Error} forms our monad M where:
# - return: T → M[T] (wrapping in Union)
# - bind: M[T] → (T → M[S]) → M[S]
# ============================================================================

struct RegistrationError <: DomainError
    message::String
end

struct AccountError <: DomainError
    message::String
end

struct LDAPError <: DomainError
    message::String
end

struct AuthError <: DomainError
    message::String
end

# OAuth extension
struct OAuthEntry <: DomainEntity
    provider::String
    account_ref::AccountId
end