# ============================================================================
# MORPHISMS (ARROWS) IN THE CATEGORY
# Each function is a morphism between objects
# register_person: Person → User (in Kleisli category)
# Actually: Person → M[User] where M is the error monad
# ============================================================================

# Morphism: Person → User (lifted to Kleisli category)
function register_person(person::Person)::Union{User, RegistrationError}
    # This is a morphism in Kleisli(Error), not just Set
    # In CT notation: register_person: Person → T_Error(User)
    if isempty(person.email)
        return RegistrationError("Email cannot be empty")
    end
    
    if !occursin("@", person.email)
        return RegistrationError("Invalid email format")
    end
    
    user_id = UserId(uuid4())
    # The morphism preserves structure: person.id is maintained as person_ref
    User(user_id, person.id, now())
end

# Morphism: User × AccountType → Account
# This is a morphism from the product object (User × AccountType) to Account
function add_user_account(user::User, account_type::AccountType)::Union{Account, AccountError}
    # In CT: this is actually curry(f): User → (AccountType → M[Account])
    # Showing that multi-parameter functions are morphisms from product objects
    
    # Business rule: Admin accounts need special validation
    if account_type == Admin && !occursin("admin", string(user.id.value))
        return AccountError("User not authorized for admin account")
    end
    
    account_id = AccountId(uuid4())
    Account(account_id, user.id, account_type)
end

# Morphism: Account → LDAPEntry
function provision_to_ldap(account::Account)::Union{LDAPEntry, LDAPError}
    # This morphism transforms the account representation
    # It's not injective (multiple accounts could map to same LDAP structure)
    
    # Simulate LDAP provisioning failure for admin accounts (for testing)
    # For testing: fail if it's an admin account and the UUID starts with "00000000"
    if account.account_type == Admin && startswith(string(account.id.value), "00000000")
        return LDAPError("LDAP provisioning failed for admin account")
    end
    
    dn = "uid=$(account.id.value),ou=users,dc=example,dc=com"
    uid = string(account.id.value)
    LDAPEntry(dn, uid, account.id)
end

# Morphism: LDAPEntry × Credentials → Session
function authenticate(ldap_entry::LDAPEntry, credentials::Dict{String,String})::Union{Session, AuthError}
    # Another morphism from a product object
    # In string diagrams, this would have two input wires
    
    # Validate credentials
    if !haskey(credentials, "password") || isempty(credentials["password"])
        return AuthError("Invalid credentials")
    end
    
    if credentials["password"] == "wrong_password"
        return AuthError("Authentication failed")
    end
    
    token = SessionToken(string(uuid4()))
    expires = now() + Hour(8)
    Session(token, ldap_entry.distinguished_name, expires)
end

# ============================================================================
# NATURAL TRANSFORMATIONS
# We could define natural transformations between different authentication strategies
# ============================================================================

# Example: Natural transformation from LDAP authentication to OAuth
# η: LDAPAuth ⟹ OAuthAuth (natural transformation between functors)

# Component of natural transformation at Account object
# This would need to satisfy naturality square:
# provision_to_ldap(f(account)) = g(provision_to_oauth(account))
function provision_to_oauth(account::Account)::Union{OAuthEntry, DomainError}
    OAuthEntry("example.com", account.id)
end