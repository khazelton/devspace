# ============================================================================
# COMPOSITION OF MORPHISMS
# The key insight: composition must respect the types
# If f: A → B and g: B → C, then g∘f: A → C
# In Kleisli category: proper error handling is built into composition
# ============================================================================

# Sequential composition with explicit error handling
# This demonstrates the associativity of morphism composition
function provision_new_user(person::Person, account_type::AccountType, credentials::Dict{String,String})
    # This is the composition of morphisms:
    # Person → User → Account → LDAPEntry → Session
    
    # Each step is a Kleisli composition: we must handle the error case
    user_result = register_person(person)
    user_result isa DomainError && return user_result  # Kleisli composition handles errors
    
    account_result = add_user_account(user_result, account_type)
    account_result isa DomainError && return account_result
    
    ldap_result = provision_to_ldap(account_result)
    ldap_result isa DomainError && return ldap_result
    
    authenticate(ldap_result, credentials)
end

# ============================================================================
# HIGHER-ORDER CATEGORICAL CONSTRUCTS
# ============================================================================

# Function composition operator - represents the composition morphism in Cat
# In category theory: ∘: Hom(B,C) × Hom(A,B) → Hom(A,C)
const ∘ = (f, g) -> x -> f(g(x))

# Kleisli composition (bind operation for our error monad)
# This is the composition law in the Kleisli category
# bind: M[A] × (A → M[B]) → M[B]
function bind(result::Union{T, DomainError}, f::Function) where T <: DomainEntity
    # This implements the monad laws:
    # - Left identity: bind(return(a), f) ≡ f(a)
    # - Right identity: bind(m, return) ≡ m
    # - Associativity: bind(bind(m, f), g) ≡ bind(m, x -> bind(f(x), g))
    result isa DomainError ? result : f(result)
end

# ============================================================================
# FUNCTORIAL PIPELINE
# The pipeline function acts as a functor from the category of domain operations
# to the category of computations with effects
# ============================================================================

# This demonstrates the functorial nature of the pipeline
# Each |> is applying a morphism, with bind handling the Kleisli composition
pipeline(person::Person, acc_type::AccountType, creds::Dict) = 
    person |>                                          # Start with object Person
    register_person |>                                 # Apply morphism Person → M[User]
    (u -> bind(u, user -> add_user_account(user, acc_type))) |>  # Kleisli composition
    (a -> bind(a, provision_to_ldap)) |>              # Continue the composition chain
    (l -> bind(l, ldap -> authenticate(ldap, creds))) # Final morphism to M[Session]

# ============================================================================
# CATEGORICAL LAWS SATISFIED:
# 
# 1. IDENTITY: Each type has an identity morphism (Julia's identity function)
#    id(person::Person) = person
#
# 2. ASSOCIATIVITY: Morphism composition is associative
#    (h ∘ g) ∘ f = h ∘ (g ∘ f)
#
# 3. FUNCTOR LAWS: The error handling preserves composition
#    F(g ∘ f) = F(g) ∘ F(f) where F lifts functions to Kleisli category
#
# 4. MONAD LAWS: The Union{T, Error} type with bind satisfies:
#    - return is the unit
#    - bind provides the multiplication
#    - Appropriate coherence conditions hold
# ============================================================================

# ============================================================================
# STRING DIAGRAM INTERPRETATION:
# 
# Person ─────register_person────> User
#                                    │
#                                    ├─AccountType─> add_user_account
#                                    ↓
#                                 Account ────provision_to_ldap───> LDAPEntry
#                                                                      │
#                                                                      ├─Credentials─> authenticate
#                                                                      ↓
#                                                                   Session
#
# Each wire represents a type (object in the category)
# Each box represents a morphism (function)
# Composition happens when output type matches input type
# ============================================================================