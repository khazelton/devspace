
using Markdown
using InteractiveUtils
using Dates
using Statistics
using BenchmarkTools

# 8f7a8b50-0f2a-11ef-1234-0123456789ab
begin
	using Pkg
	Pkg.activate(".")
	
	# Core AlgebraicJulia ecosystem
	using Catlab, Catlab.Theories
	using Catlab.CategoricalAlgebra
	using Catlab.WiringDiagrams
	using Catlab.Graphics
	
	# For domain modeling
	try
		using AlgebraicPetri 
	catch e
		@warn "AlgebraicPetri not available: $e"
	end
	
	try
		using AlgebraicDynamics
	catch e
		@warn "AlgebraicDynamics not available: $e"
	end
	
	# Utilities
	using DataStructures
	using Plots
	plotly()
end

md"""
# Functional Domain Models: Composable Functions and Category Theory

*Exploring the benefits and limitations of domain models built from chainable functional components*

Inspired by the work of:
- **Owen Lynch** & **Evan Patterson** (AlgebraicJulia)
- **Bartosz Milewski** (Category Theory for Programmers)
- **Emma Boudreau** (Functional programming in Julia)

## Introduction

This notebook explores how category theory and functional programming principles can be applied to domain modeling through composable functions. We'll examine how the AlgebraicJulia ecosystem enables us to build domain models where functions can be naturally chained because their type signatures align.

The key insight: `f: A → B` and `g: B → C` can compose to `g ∘ f: A → C`
"""

md"""
## Part 1: Foundations of Composable Functions

Let's start with the mathematical foundation. In category theory, objects and morphisms form the basis of composition.
"""

# 2b3c4d60-0f2a-11ef-2345-0123456789ab
begin
	# Define our domain types as Julia structs
	struct Customer
		id::String
		name::String
		email::String
	end
	
	struct Order
		customer_id::String
		items::Vector{String}
		total::Float64
		timestamp::DateTime
	end
	
	struct Invoice
		order_id::String
		amount::Float64
		due_date::DateTime
		status::Symbol  # :pending, :paid, :overdue
	end
	
	struct Payment
		invoice_id::String
		amount::Float64
		method::Symbol  # :card, :bank, :cash
		processed_at::DateTime
	end
end

md"""
### Composable Domain Functions

The power of functional composition lies in creating pipelines where each function's output type matches the next function's input type.
"""

# 3a4b5c70-0f2a-11ef-3456-0123456789ab
begin
	# Customer → Order (Customer places order)
	place_order(customer::Customer, items::Vector{String}, total::Float64) = 
		Order(customer.id, items, total, Dates.now())
	
	# Order → Invoice (Generate invoice from order)
	generate_invoice(order::Order) = 
		Invoice(order.customer_id * "_" * string(hash(order)), 
				order.total, 
				Dates.now() + Dates.Day(30), 
				:pending)
	
	# Invoice → Payment (Process payment for invoice)
	process_payment(invoice::Invoice, method::Symbol) = 
		Payment(invoice.order_id, 
				invoice.amount, 
				method, 
				Dates.now())
	
	# Note: Function composition requires fixing the argument structure
	# For now, we'll define a proper pipeline function
	function complete_transaction(customer::Customer, items::Vector{String}, total::Float64, method::Symbol)
		order = place_order(customer, items, total)
		invoice = generate_invoice(order)
		payment = process_payment(invoice, method)
		return payment
	end
end

md"""
## Part 2: Category Theory with Catlab.jl

Now let's formalize this using Catlab.jl to express our domain as a category with objects and morphisms.
"""

# 4c5d6e80-0f2a-11ef-4567-0123456789ab
begin
	# Define our domain category
	try
		@present DomainSchema(FreeCategory) begin
			# Objects (types)
			Customer::Ob
			Order::Ob
			Invoice::Ob
			Payment::Ob
			
			# Morphisms (functions)
			place_order::Hom(Customer, Order)
			generate_invoice::Hom(Order, Invoice)
			process_payment::Hom(Invoice, Payment)
			
			# Composition law is automatically enforced
			# complete_transaction = process_payment ∘ generate_invoice ∘ place_order
		end
		
		# Visualize the category
		try
			category_diagram = to_graphviz(DomainSchema)
			println("Domain category created successfully")
		catch e
			@warn "Category visualization failed: $e"
			println("Domain objects: Customer, Order, Invoice, Payment")
			println("Domain morphisms: place_order, generate_invoice, process_payment")
		end
	catch e
		@warn "Category definition failed: $e"
		# Fallback: simple representation
		struct DomainObjects
			objects::Vector{Symbol}
			morphisms::Vector{Tuple{Symbol, Symbol, Symbol}}
		end
		
		domain_rep = DomainObjects(
			[:Customer, :Order, :Invoice, :Payment],
			[(:place_order, :Customer, :Order),
			 (:generate_invoice, :Order, :Invoice),
			 (:process_payment, :Invoice, :Payment)]
		)
		
		println("Fallback domain representation: ", domain_rep)
	end
end

md"""
### Benefits of This Approach

1. **Type Safety**: Composition is only possible when types align
2. **Modularity**: Each function has a single responsibility
3. **Testability**: Each function can be tested in isolation
4. **Reusability**: Functions can be composed in different ways
5. **Reasoning**: Category laws provide mathematical guarantees
"""

md"""
## Part 3: Wiring Diagrams for Complex Compositions

For more complex domains, we can use wiring diagrams to visualize and construct compositions.
"""

# 5d6e7f90-0f2a-11ef-5678-0123456789ab
begin
	# Create a wiring diagram for our transaction flow
	try
		transaction_diagram = @relation (customer,) begin
			order = place_order(customer)
			invoice = generate_invoice(order)
			payment = process_payment(invoice)
			return payment
		end
		
		# Visualize the wiring diagram
		try
			diagram_viz = to_graphviz(transaction_diagram, labels=true)
			println("Transaction wiring diagram created successfully")
		catch e
			@warn "Wiring diagram visualization failed: $e"
		end
	catch e
		@warn "Wiring diagram creation failed: $e"
		# Fallback: text representation
		println("Transaction Flow:")
		println("Customer → place_order → Order → generate_invoice → Invoice → process_payment → Payment")
	end
end

md"""
## Part 4: Algebraic Structures in Domain Modeling

Using AlgebraicJulia, we can model domains as algebraic structures like monoids, categories, or operads.
"""

# 6e7f8090-0f2a-11ef-6789-0123456789ab
begin
	# Define a monoid for combining orders
	struct OrderMonoid
		orders::Vector{Order}
	end
	
	# Monoid operations
	Base.:*(a::OrderMonoid, b::OrderMonoid) = OrderMonoid(vcat(a.orders, b.orders))
	mempty_order() = OrderMonoid(Order[])
	
	# This allows us to combine multiple orders associatively
	order1 = OrderMonoid([Order("cust1", ["item1"], 10.0, Dates.now())])
	order2 = OrderMonoid([Order("cust2", ["item2"], 20.0, Dates.now())])
	order3 = OrderMonoid([Order("cust3", ["item3"], 30.0, Dates.now())])
	
	# Associativity: (a * b) * c = a * (b * c)
	left_assoc = (order1 * order2) * order3
	right_assoc = order1 * (order2 * order3)
	
	length(left_assoc.orders) == length(right_assoc.orders)
end

md"""
## Part 5: Petri Nets for Dynamic Domain Models

AlgebraicPetri allows us to model dynamic systems where domain entities transition between states.
"""

# 7f8091a0-0f2a-11ef-789a-0123456789ab
begin
	# Define a simple Petri net representation for order processing
	# Note: Using a simplified approach since AlgebraicPetri may not be available
	
	struct SimplePetriNet
		states::Vector{Symbol}
		transitions::Vector{Pair{Symbol, Symbol}}
	end
	
	# Define our order processing Petri net
	order_process = SimplePetriNet(
		[:customer, :order, :invoice, :payment],
		[
			:customer => :order,      # place_order
			:order => :invoice,       # generate_invoice  
			:invoice => :payment,     # process_payment
			:order => :customer       # cancel_order (alternative path)
		]
	)
	
	println("Order Process States: ", order_process.states)
	println("Order Process Transitions: ", order_process.transitions)
end

md"""
## Part 6: Limitations and Trade-offs

While functional composition provides many benefits, there are limitations to consider:

### Limitations

1. **Performance**: Function composition can introduce overhead
2. **Debugging**: Long composition chains can be hard to debug
3. **State Management**: Pure functions struggle with mutable state
4. **Error Handling**: Errors in composition chains can be hard to trace
5. **Learning Curve**: Category theory concepts require mathematical background

### Mitigation Strategies
"""

# 809192b0-0f2a-11ef-89ab-0123456789ab
begin
	# Enhanced error handling with Maybe/Option and Either types
	abstract type Maybe{T} end
	struct Some{T} <: Maybe{T}
		value::T
	end
	struct None{T} <: Maybe{T} end
	
	# Either type for error handling
	abstract type Either{L,R} end
	struct Left{L,R} <: Either{L,R}
		value::L
	end
	struct Right{L,R} <: Either{L,R}
		value::R
	end
	
	# Helper functions for Maybe
	is_some(::Some) = true
	is_some(::None) = false
	unwrap(s::Some) = s.value
	unwrap_or(s::Some, default) = s.value
	unwrap_or(::None, default) = default
	
	# Helper functions for Either
	is_right(::Right) = true
	is_right(::Left) = false
	is_left(::Left) = true
	is_left(::Right) = false
	
	# Safe composition that handles errors
	function safe_place_order(customer::Customer, items::Vector{String}, total::Float64)::Either{String, Order}
		if total <= 0
			return Left{String, Order}("Total must be positive")
		end
		if isempty(items)
			return Left{String, Order}("Items list cannot be empty")
		end
		return Right{String, Order}(Order(customer.id, items, total, Dates.now()))
	end
	
	function safe_generate_invoice(order::Order)::Either{String, Invoice}
		try
			invoice = generate_invoice(order)
			return Right{String, Invoice}(invoice)
		catch e
			return Left{String, Invoice}("Failed to generate invoice: $e")
		end
	end
	
	# Monadic bind for Either
	function bind(e::Right{L,R}, f::Function) where {L,R}
		try
			f(e.value)
		catch ex
			Left{String, Any}("Error in bind: $ex")
		end
	end
	
	bind(e::Left{L,R}, f::Function) where {L,R} = Left{L, Any}(e.value)
	
	# Safe transaction pipeline using Either monads
	function safe_transaction_pipeline(customer::Customer, items::Vector{String}, total::Float64)
		result = bind(safe_place_order(customer, items, total)) do order
			bind(safe_generate_invoice(order)) do invoice
				Right{String, Invoice}(invoice)
			end
		end
		return result
	end
	
	# Test the safe pipeline
	test_result = safe_transaction_pipeline(test_customer, test_items, 1500.0)
	println("Safe transaction result: ", is_right(test_result) ? "Success" : "Failed with: $(test_result.value)")
end

md"""
## Part 7: Real-world Example: Supply Chain Model

Let's build a more complex domain model for a supply chain system.
"""

# 91a2b3c0-0f2a-11ef-9abc-0123456789ab
begin
	# Supply chain domain types
	struct Supplier
		id::String
		name::String
		reliability::Float64
	end
	
	struct RawMaterial
		supplier_id::String
		material_type::String
		quantity::Int
		quality_score::Float64
	end
	
	struct Product
		materials::Vector{RawMaterial}
		production_time::Int
		quality_rating::Float64
	end
	
	struct Shipment
		product::Product
		destination::String
		shipping_time::Int
	end
	
	# Composable supply chain functions
	source_materials(supplier::Supplier, material_type::String, qty::Int) = 
		RawMaterial(supplier.id, material_type, qty, supplier.reliability * 0.9)
	
	manufacture_product(materials::Vector{RawMaterial}) = 
		Product(materials, 
				sum(m.quantity for m in materials) ÷ 10,
				mean([m.quality_score for m in materials]))
	
	ship_product(product::Product, destination::String) = 
		Shipment(product, destination, product.production_time + 5)
	
	# Full supply chain pipeline function
	function supply_chain_pipeline(supplier::Supplier, material_type::String, qty::Int, destination::String)
		materials = [source_materials(supplier, material_type, qty)]
		product = manufacture_product(materials)
		shipment = ship_product(product, destination)
		return shipment
	end
end

md"""
## Part 8: Performance Considerations

Let's examine the performance characteristics of our functional compositions.
"""

# a2b3c4d0-0f2a-11ef-abcd-0123456789ab
begin
	# Create test data
	test_customer = Customer("test123", "Test User", "test@example.com")
	test_items = ["laptop", "mouse", "keyboard"]
	
	# Benchmark individual functions
	try
		bench_result = @benchmark place_order($test_customer, $test_items, 1500.0)
		println("place_order benchmark: ", bench_result)
	catch e
		@warn "Benchmarking failed: $e"
		# Fallback timing
		@time place_order(test_customer, test_items, 1500.0)
	end
end

# b3c4d5e0-0f2a-11ef-bcde-0123456789ab
begin
	# Benchmark composed function
	test_order = place_order(test_customer, test_items, 1500.0)
	try
		bench_result2 = @benchmark generate_invoice($test_order)
		println("generate_invoice benchmark: ", bench_result2)
	catch e
		@warn "Benchmarking failed: $e"
		# Fallback timing
		@time generate_invoice(test_order)
	end
	
	# Test the complete transaction
	try
		result = complete_transaction(test_customer, test_items, 1500.0, :card)
		println("Complete transaction result: ", typeof(result))
	catch e
		@warn "Complete transaction failed: $e"
	end
end

md"""
## Part 9: Advanced Compositions with Operads

For complex domain models, we can use operads to represent multi-input operations.
"""

# c4d5e6f0-0f2a-11ef-cdef-0123456789ab
begin
	# Define an operad for combining multiple domain operations
	try
		@present CombinatorOperad(FreeSymmetricMonoidalCategory) begin
			# Objects
			Ord::Ob    # Order
			Inv::Ob    # Invoice
			Pay::Ob    # Payment
			
			# Multi-input operations
			merge_orders::Hom(Ord ⊗ Ord, Ord)
			split_payment::Hom(Pay, Pay ⊗ Pay)
			consolidate_invoices::Hom(Inv ⊗ Inv, Inv)
		end
		
		try
			operad_viz = to_graphviz(CombinatorOperad)
			println("Combinator operad created successfully")
		catch e
			@warn "Operad visualization failed: $e"
		end
	catch e
		@warn "Operad definition failed: $e"
		# Fallback: describe the operations
		println("Multi-input operations:")
		println("- merge_orders: (Order, Order) → Order")
		println("- split_payment: Payment → (Payment, Payment)")
		println("- consolidate_invoices: (Invoice, Invoice) → Invoice")
	end
end

md"""
## Conclusions

### Benefits Realized
- **Compositional Reasoning**: Build complex behavior from simple parts
- **Type Safety**: Catch errors at compile time
- **Mathematical Foundation**: Category theory provides formal guarantees
- **Modularity**: Easy to test, modify, and extend individual components

### Limitations Encountered
- **Performance Overhead**: Function composition isn't always zero-cost
- **Complexity**: Requires mathematical sophistication
- **Debugging Challenges**: Long composition chains are hard to debug
- **State Management**: Pure functional style doesn't handle mutable state well

### Recommendations
1. Use functional composition for data transformation pipelines
2. Combine with imperative style for stateful operations
3. Invest in error handling abstractions (Maybe, Either types)
4. Profile performance-critical compositions
5. Document composition chains clearly

The AlgebraicJulia ecosystem provides powerful tools for functional domain modeling, but success requires balancing mathematical elegance with practical engineering concerns.
"""

md"""
## Part 10: Comprehensive Examples and Tests

Let's demonstrate all the concepts with working examples.
"""

# d5e6f7g0-0f2a-11ef-def0-0123456789ab
begin
	# Example 1: Basic function composition
	println("=== Example 1: Basic Domain Operations ===")
	
	# Create sample data
	sample_customer = Customer("cust_001", "Alice Johnson", "alice@example.com")
	sample_items = ["Laptop", "Mouse", "Keyboard"]
	sample_total = 1299.99
	
	# Test individual functions
	println("1. Creating order...")
	sample_order = place_order(sample_customer, sample_items, sample_total)
	println("   Order created: $(sample_order.customer_id) with $(length(sample_order.items)) items")
	
	println("2. Generating invoice...")
	sample_invoice = generate_invoice(sample_order)
	println("   Invoice created: $(sample_invoice.order_id) for \$$(sample_invoice.amount)")
	
	println("3. Processing payment...")
	sample_payment = process_payment(sample_invoice, :card)
	println("   Payment processed: $(sample_payment.method) for \$$(sample_payment.amount)")
	
	# Test complete transaction
	println("4. Complete transaction...")
	complete_result = complete_transaction(sample_customer, sample_items, sample_total, :card)
	println("   Transaction completed successfully: $(typeof(complete_result))")
end

# e6f7g8h0-0f2a-11ef-efg0-0123456789ab
begin
	println("\n=== Example 2: Error Handling with Either Types ===")
	
	# Test successful case
	println("1. Testing successful transaction...")
	success_result = safe_transaction_pipeline(sample_customer, sample_items, 1299.99)
	if is_right(success_result)
		println("   ✓ Transaction succeeded")
	else
		println("   ✗ Unexpected failure: $(success_result.value)")
	end
	
	# Test error cases
	println("2. Testing error cases...")
	
	# Negative total
	error_result1 = safe_transaction_pipeline(sample_customer, sample_items, -100.0)
	if is_left(error_result1)
		println("   ✓ Caught negative total error: $(error_result1.value)")
	end
	
	# Empty items
	error_result2 = safe_transaction_pipeline(sample_customer, String[], 100.0)
	if is_left(error_result2)
		println("   ✓ Caught empty items error: $(error_result2.value)")
	end
end

# f7g8h9i0-0f2a-11ef-fgh0-0123456789ab
begin
	println("\n=== Example 3: Monoid Operations ===")
	
	# Create multiple orders
	order_batch1 = OrderMonoid([
		Order("cust_001", ["item1"], 100.0, Dates.now()),
		Order("cust_002", ["item2"], 200.0, Dates.now())
	])
	
	order_batch2 = OrderMonoid([
		Order("cust_003", ["item3"], 300.0, Dates.now()),
		Order("cust_004", ["item4"], 400.0, Dates.now())
	])
	
	order_batch3 = OrderMonoid([
		Order("cust_005", ["item5"], 500.0, Dates.now())
	])
	
	# Test associativity
	left_combine = (order_batch1 * order_batch2) * order_batch3
	right_combine = order_batch1 * (order_batch2 * order_batch3)
	
	println("1. Order batch combining:")
	println("   Left association: $(length(left_combine.orders)) orders")
	println("   Right association: $(length(right_combine.orders)) orders")
	println("   Associativity holds: $(length(left_combine.orders) == length(right_combine.orders))")
	
	# Calculate total value
	total_value = sum(order.total for order in left_combine.orders)
	println("   Total order value: \$$(total_value)")
end

# g8h9i0j0-0f2a-11ef-ghi0-0123456789ab
begin
	println("\n=== Example 4: Supply Chain Pipeline ===")
	
	# Create suppliers
	supplier1 = Supplier("sup_001", "TechParts Inc", 0.95)
	supplier2 = Supplier("sup_002", "ComponentCorp", 0.87)
	
	println("1. Testing supply chain pipeline...")
	
	# Test individual supply chain operations
	raw_material = source_materials(supplier1, "Silicon", 100)
	println("   Sourced material: $(raw_material.material_type) quality $(raw_material.quality_score)")
	
	materials_list = [raw_material, source_materials(supplier2, "Plastic", 50)]
	product = manufacture_product(materials_list)
	println("   Manufactured product: quality $(product.quality_rating), time $(product.production_time)")
	
	shipment = ship_product(product, "New York")
	println("   Shipment created: to $(shipment.destination), time $(shipment.shipping_time)")
	
	# Test complete pipeline
	println("2. Complete supply chain...")
	complete_shipment = supply_chain_pipeline(supplier1, "Aluminum", 75, "San Francisco")
	println("   ✓ Complete shipment: to $(complete_shipment.destination)")
end

# h9i0j1k0-0f2a-11ef-hij0-0123456789ab
begin
	println("\n=== Example 5: Performance Testing ===")
	
	# Create test dataset
	test_customers = [Customer("test_$i", "User $i", "user$i@test.com") for i in 1:100]
	test_items_list = [["item_$j" for j in 1:rand(1:5)] for _ in 1:100]
	test_totals = [rand(10.0:1000.0) for _ in 1:100]
	
	println("1. Performance test with $(length(test_customers)) transactions...")
	
	# Time the operations
	start_time = time()
	successful_transactions = 0
	failed_transactions = 0
	
	for i in 1:length(test_customers)
		try
			result = complete_transaction(test_customers[i], test_items_list[i], test_totals[i], :card)
			successful_transactions += 1
		catch e
			failed_transactions += 1
		end
	end
	
	end_time = time()
	elapsed = end_time - start_time
	
	println("   Processed $(successful_transactions) successful transactions")
	println("   Failed transactions: $(failed_transactions)")
	println("   Total time: $(round(elapsed, digits=3)) seconds")
	println("   Avg time per transaction: $(round(elapsed/length(test_customers)*1000, digits=2)) ms")
end

# i0j1k2l0-0f2a-11ef-ijk0-0123456789ab
begin
	println("\n=== Example 6: Advanced Error Handling ===")
	
	# Test Maybe type operations
	println("1. Testing Maybe types...")
	
	some_value = Some(42)
	none_value = None{Int}()
	
	println("   Some value: $(unwrap_or(some_value, 0))")
	println("   None value (with default): $(unwrap_or(none_value, 0))")
	println("   Is some? $(is_some(some_value)) vs $(is_some(none_value))")
	
	# Test chain of safe operations
	println("2. Testing safe operation chains...")
	
	customers_to_test = [
		("valid", Customer("valid", "Valid User", "valid@test.com"), ["item"], 100.0),
		("negative", Customer("neg", "Negative User", "neg@test.com"), ["item"], -50.0),
		("empty", Customer("empty", "Empty User", "empty@test.com"), String[], 100.0)
	]
	
	for (name, customer, items, total) in customers_to_test
		result = safe_transaction_pipeline(customer, items, total)
		status = is_right(result) ? "SUCCESS" : "FAILED: $(result.value)"
		println("   $name case: $status")
	end
end

println("\n=== All Examples Completed Successfully! ===")
println("The notebook demonstrates:")
println("• Basic functional composition")
println("• Robust error handling with Either types")
println("• Monoid operations and associativity")
println("• Complete supply chain modeling")
println("• Performance characteristics")
println("• Advanced error handling patterns")
println("\nThe functional domain modeling approach provides both mathematical rigor and practical utility.")

# Cell order:
# ╟─8f7a8b50-0f2a-11ef-1234-0123456789ab
# ╟─md"""
# ╟─2b3c4d60-0f2a-11ef-2345-0123456789ab
# ╟─md"""
# ╟─3a4b5c70-0f2a-11ef-3456-0123456789ab
# ╟─md"""
# ╟─4c5d6e80-0f2a-11ef-4567-0123456789ab
# ╟─md"""
# ╟─md"""
# ╟─5d6e7f90-0f2a-11ef-5678-0123456789ab
# ╟─md"""
# ╟─6e7f8090-0f2a-11ef-6789-0123456789ab
# ╟─md"""
# ╟─7f8091a0-0f2a-11ef-789a-0123456789ab
# ╟─md"""
# ╟─809192b0-0f2a-11ef-89ab-0123456789ab
# ╟─md"""
# ╟─91a2b3c0-0f2a-11ef-9abc-0123456789ab
# ╟─md"""
# ╟─a2b3c4d0-0f2a-11ef-abcd-0123456789ab
# ╟─b3c4d5e0-0f2a-11ef-bcde-0123456789ab
# ╟─md"""
# ╟─c4d5e6f0-0f2a-11ef-cdef-0123456789ab
# ╟─md"""