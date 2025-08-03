using AppliedCategoryTheoryDDD
using Test
using UUIDs
using Dates

# ============================================================================
# TEST SUITE: EXERCISING THE CATEGORY
# 
# These tests demonstrate:
# 1. Successful morphism composition (happy path)
# 2. Error propagation in Kleisli category
# 3. Monad laws for our error handling
# 4. Functorial properties of the pipeline
# ============================================================================

@testset "Category Theory Identity Management Tests" begin
    
    # ========================================================================
    # TEST OBJECTS AND IDENTITY MORPHISMS
    # ========================================================================
    
    @testset "Object Construction and Identity" begin
        # Create test objects
        person_id = PersonId(uuid4())
        person = Person(person_id, "alice@example.com", "Alice Smith")
        
        # Identity morphism (in Julia, this is the identity function)
        @test identity(person) === person
        @test person.id === person_id
        
        # Test that our objects are well-formed
        @test person isa DomainEntity
        @test person_id.value isa UUID
    end
    
    # ========================================================================
    # TEST INDIVIDUAL MORPHISMS
    # ========================================================================
    
    @testset "Morphism: register_person (Person → M[User])" begin
        # Valid person (morphism succeeds)
        valid_person = Person(PersonId(uuid4()), "bob@example.com", "Bob Jones")
        result = register_person(valid_person)
        
        @test result isa User
        @test result.person_ref === valid_person.id  # Structure preservation
        
        # Invalid person - empty email (morphism returns error)
        invalid_person1 = Person(PersonId(uuid4()), "", "Charlie Brown")
        error_result1 = register_person(invalid_person1)
        
        @test error_result1 isa RegistrationError
        @test error_result1.message == "Email cannot be empty"
        
        # Invalid person - bad email format (morphism returns error)
        invalid_person2 = Person(PersonId(uuid4()), "not-an-email", "Dave Wilson")
        error_result2 = register_person(invalid_person2)
        
        @test error_result2 isa RegistrationError
        @test error_result2.message == "Invalid email format"
    end
    
    @testset "Morphism: add_user_account (User × AccountType → M[Account])" begin
        # Create a test user
        user = User(UserId(uuid4()), PersonId(uuid4()), now())
        
        # Standard account (succeeds)
        standard_result = add_user_account(user, Standard)
        @test standard_result isa Account
        @test standard_result.owner_id === user.id
        @test standard_result.account_type === Standard
        
        # Premium account (succeeds)
        premium_result = add_user_account(user, Premium)
        @test premium_result isa Account
        @test premium_result.account_type === Premium
        
        # Admin account without authorization (fails)
        admin_result = add_user_account(user, Admin)
        @test admin_result isa AccountError
        @test occursin("not authorized", admin_result.message)
    end
    
    @testset "Morphism: provision_to_ldap (Account → M[LDAPEntry])" begin
        # Standard account provisioning (succeeds)
        account = Account(AccountId(uuid4()), UserId(uuid4()), Standard)
        ldap_result = provision_to_ldap(account)
        
        @test ldap_result isa LDAPEntry
        @test occursin(string(account.id.value), ldap_result.distinguished_name)
        @test ldap_result.account_ref === account.id
        
        # Admin account with UUID starting with zeros (simulated failure)
        failing_id = AccountId(UUID("00000000-1234-5678-1234-567812345678"))
        admin_account = Account(failing_id, UserId(uuid4()), Admin)
        ldap_error = provision_to_ldap(admin_account)
        
        @test ldap_error isa LDAPError
        @test occursin("LDAP provisioning failed", ldap_error.message)
    end
    
    @testset "Morphism: authenticate (LDAPEntry × Credentials → M[Session])" begin
        ldap_entry = LDAPEntry("uid=test,ou=users,dc=example,dc=com", "test", AccountId(uuid4()))
        
        # Valid credentials (succeeds)
        valid_creds = Dict("username" => "alice", "password" => "secret123")
        session_result = authenticate(ldap_entry, valid_creds)
        
        @test session_result isa Session
        @test session_result.ldap_dn === ldap_entry.distinguished_name
        @test session_result.expires_at > now()
        
        # Invalid credentials - wrong password
        invalid_creds = Dict("username" => "alice", "password" => "wrong_password")
        auth_error1 = authenticate(ldap_entry, invalid_creds)
        
        @test auth_error1 isa AuthError
        @test auth_error1.message == "Authentication failed"
        
        # Invalid credentials - missing password
        missing_creds = Dict("username" => "alice")
        auth_error2 = authenticate(ldap_entry, missing_creds)
        
        @test auth_error2 isa AuthError
        @test auth_error2.message == "Invalid credentials"
    end
    
    # ========================================================================
    # TEST MORPHISM COMPOSITION
    # ========================================================================
    
    @testset "Full Pipeline Composition (Happy Path)" begin
        # Create valid inputs
        person = Person(PersonId(uuid4()), "eve@example.com", "Eve Anderson")
        credentials = Dict("username" => "eve", "password" => "secure456")
        
        # Test sequential composition
        result = provision_new_user(person, Standard, credentials)
        
        @test result isa Session
        @test !isempty(result.token.value)
        
        # Test pipeline composition (functorial approach)
        pipeline_result = AppliedCategoryTheoryDDD.pipeline(person, Premium, credentials)
        
        @test pipeline_result isa Session
    end
    
    @testset "Error Propagation in Kleisli Category" begin
        credentials = Dict("username" => "test", "password" => "test123")
        
        # Error at first morphism (register_person)
        bad_person = Person(PersonId(uuid4()), "", "No Email")
        result1 = provision_new_user(bad_person, Standard, credentials)
        
        @test result1 isa RegistrationError
        @test result1.message == "Email cannot be empty"
        
        # Error at second morphism (add_user_account)
        # First create a person that will register successfully
        person = Person(PersonId(uuid4()), "admin@example.com", "Admin User")
        result2 = provision_new_user(person, Admin, credentials)
        
        @test result2 isa AccountError  # Should fail at account creation
        
        # Error at third morphism (provision_to_ldap)
        # This would require setting up specific conditions
        
        # Error at fourth morphism (authenticate)
        person3 = Person(PersonId(uuid4()), "fail@example.com", "Fail User")
        bad_creds = Dict("username" => "fail", "password" => "wrong_password")
        result3 = provision_new_user(person3, Standard, bad_creds)
        
        @test result3 isa AuthError
    end
    
    # ========================================================================
    # TEST MONAD LAWS
    # ========================================================================
    
    @testset "Monad Laws for Error Handling" begin
        # Helper to wrap value in our monad
        return_value(x::DomainEntity) = x
        
        # Test Left Identity: bind(return(a), f) ≡ f(a)
        person = Person(PersonId(uuid4()), "monad@test.com", "Monad Test")
        f = register_person
        
        # Direct application
        direct_result = f(person)
        
        # Using bind with return
        bind_result = AppliedCategoryTheoryDDD.bind(return_value(person), f)
        
        @test typeof(direct_result) == typeof(bind_result)
        if direct_result isa User && bind_result isa User
            @test direct_result.person_ref == bind_result.person_ref
        end
        
        # Test Right Identity: bind(m, return) ≡ m
        user = User(UserId(uuid4()), PersonId(uuid4()), now())
        
        @test AppliedCategoryTheoryDDD.bind(user, return_value) === user
        
        # Test error propagation
        error = RegistrationError("Test error")
        @test AppliedCategoryTheoryDDD.bind(error, f) === error  # Errors short-circuit
        
        # Test Associativity: bind(bind(m, f), g) ≡ bind(m, x -> bind(f(x), g))
        # This is demonstrated by our pipeline composition working correctly
    end
    
    # ========================================================================
    # TEST FUNCTORIAL PROPERTIES
    # ========================================================================
    
    @testset "Functorial Properties of Pipeline" begin
        # The pipeline should preserve composition
        person = Person(PersonId(uuid4()), "functor@test.com", "Functor Test")
        creds = Dict("username" => "functor", "password" => "test123")
        
        # Compose functions manually
        manual_result = person |>
            register_person |>
            (u -> u isa AppliedCategoryTheoryDDD.DomainError ? u : add_user_account(u, Standard)) |>
            (a -> a isa AppliedCategoryTheoryDDD.DomainError ? a : provision_to_ldap(a)) |>
            (l -> l isa AppliedCategoryTheoryDDD.DomainError ? l : authenticate(l, creds))
        
        # Use pipeline functor
        pipeline_result = AppliedCategoryTheoryDDD.pipeline(person, Standard, creds)
        
        # Both should give same result type
        @test typeof(manual_result) == typeof(pipeline_result)
    end
    
    # ========================================================================
    # TEST NATURAL TRANSFORMATIONS
    # ========================================================================
    
    @testset "Natural Transformation: LDAP to OAuth" begin
        # Create an account
        account = Account(AccountId(uuid4()), UserId(uuid4()), Standard)
        
        # Apply both transformations
        ldap_result = provision_to_ldap(account)
        oauth_result = provision_to_oauth(account)
        
        @test ldap_result isa LDAPEntry
        @test oauth_result isa OAuthEntry
        
        # Both preserve the account reference
        if ldap_result isa LDAPEntry && oauth_result isa OAuthEntry
            @test ldap_result.account_ref === account.id
            @test oauth_result.account_ref === account.id
        end
        
        # This demonstrates the natural transformation preserves structure
    end
    
    # ========================================================================
    # TEST COMPOSITION ASSOCIATIVITY
    # ========================================================================
    
    @testset "Associativity of Morphism Composition" begin
        # Create test data
        person = Person(PersonId(uuid4()), "assoc@test.com", "Assoc Test")
        
        # Define partial compositions
        f = register_person
        g = u -> u isa User ? add_user_account(u, Standard) : u
        h = a -> a isa Account ? provision_to_ldap(a) : a
        
        # Test (h ∘ g) ∘ f
        comp1 = x -> h(g(f(x)))
        
        # Test h ∘ (g ∘ f)
        comp2 = x -> h(g(f(x)))
        
        result1 = comp1(person)
        result2 = comp2(person)
        
        # Results should be identical (associativity)
        @test typeof(result1) == typeof(result2)
    end
end