from dataclasses import dataclass
from typing import List, Literal
from enum import Enum

class StudentLevel(Enum):
    UNDERGRADUATE = "undergraduate"
    GRADUATE = "graduate"
    DOCTORAL = "doctoral"

class StudentStatus(Enum):
    FULL_TIME = "full_time"
    PART_TIME = "part_time"
    INACTIVE = "inactive"

@dataclass(frozen=True)
class Student:
    student_id: str
    level: StudentLevel
    status: StudentStatus
    gpa: float
    credit_hours: int
    is_international: bool
    has_disabilities: bool
    is_athlete: bool

CampusService = Literal[
    "library_access",
    "student_portal",
    "email_account",
    "wifi_access",
    "gym_membership",
    "health_services",
    "counseling_services",
    "career_services",
    "tutoring_center",
    "research_databases",
    "graduate_resources",
    "dissertation_support",
    "international_student_services",
    "disability_services",
    "athletic_facilities",
    "honors_program",
    "academic_support"
]

def authorize_campus_services(student: Student) -> List[CampusService]:
    """
    Pure function that maps Student → List[CampusService]
    Following functional composition principles: f: Student → List[CampusService]
    """
    services: List[CampusService] = []
    
    # Base services for all active students
    if student.status != StudentStatus.INACTIVE:
        services.extend([
            "library_access",
            "student_portal", 
            "email_account",
            "wifi_access",
            "health_services",
            "counseling_services",
            "career_services"
        ])
    
    # Full-time student services
    if student.status == StudentStatus.FULL_TIME:
        services.extend([
            "gym_membership",
            "tutoring_center"
        ])
    
    # Academic level-based services
    if student.level == StudentLevel.UNDERGRADUATE:
        services.append("academic_support")
        if student.gpa >= 3.5:
            services.append("honors_program")
    
    elif student.level in [StudentLevel.GRADUATE, StudentLevel.DOCTORAL]:
        services.extend([
            "research_databases",
            "graduate_resources"
        ])
        
        if student.level == StudentLevel.DOCTORAL:
            services.append("dissertation_support")
    
    # Conditional services based on student attributes
    if student.is_international:
        services.append("international_student_services")
    
    if student.has_disabilities:
        services.append("disability_services")
    
    if student.is_athlete:
        services.append("athletic_facilities")
    
    return sorted(list(set(services)))