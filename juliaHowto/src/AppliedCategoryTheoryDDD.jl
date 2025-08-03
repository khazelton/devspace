module AppliedCategoryTheoryDDD

using UUIDs
using Dates

# Export domain entities
export DomainEntity, DomainError
export PersonId, Person, UserId, User, AccountId, Account, AccountType
export LDAPEntry, SessionToken, Session, OAuthEntry
export Standard, Premium, Admin

# Export errors
export RegistrationError, AccountError, LDAPError, AuthError

# Export morphisms (domain operations)
export register_person, add_user_account, provision_to_ldap, authenticate
export provision_to_oauth

# Export composition functions
export provision_new_user, pipeline, bind

# Export the composition operator
export ∘

# Include the implementation
include("domain.jl")
include("morphisms.jl")
include("composition.jl")

end # module