from student_services import Student, StudentLevel, StudentStatus, authorize_campus_services

# Example usage demonstrating the functional composition
def main():
    # Create sample students
    undergrad_student = Student(
        student_id="12345",
        level=StudentLevel.UNDERGRADUATE,
        status=StudentStatus.FULL_TIME,
        gpa=3.7,
        credit_hours=15,
        is_international=False,
        has_disabilities=False,
        is_athlete=True
    )
    
    grad_student = Student(
        student_id="67890", 
        level=StudentLevel.GRADUATE,
        status=StudentStatus.PART_TIME,
        gpa=3.9,
        credit_hours=9,
        is_international=True,
        has_disabilities=True,
        is_athlete=False
    )
    
    # Apply the function: Student → List[CampusService]
    undergrad_services = authorize_campus_services(undergrad_student)
    grad_services = authorize_campus_services(grad_student)
    
    print("Undergraduate student services:")
    for service in undergrad_services:
        print(f"  - {service}")
    
    print("\nGraduate student services:")
    for service in grad_services:
        print(f"  - {service}")

if __name__ == "__main__":
    main()