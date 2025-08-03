#!/usr/bin/env python3
"""
Extract person names from PDF using functional programming approach.
Uses pattern matching instead of NLP for simpler deployment.
"""

import re
from functools import reduce, partial
from itertools import chain
from typing import List, Set, Callable, Iterable
import PyPDF2


def read_pdf(filepath: str) -> List[str]:
    """Read PDF and return list of text from all pages."""
    with open(filepath, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        return [page.extract_text() for page in reader.pages]


def extract_potential_names(text: str) -> List[str]:
    """Extract potential names using regex patterns."""
    # Pattern for names: Capitalized words, possibly with middle initials
    # Matches: John Smith, John Q. Smith, Mary Jane Smith, etc.
    name_pattern = r'\b([A-Z][a-z]+(?:\s+[A-Z]\.?)?(?:\s+[A-Z][a-z]+)+)\b'
    
    # Find all matches
    matches = re.findall(name_pattern, text)
    
    # Also look for specific patterns with titles
    title_pattern = r'\b(?:Mr\.|Mrs\.|Ms\.|Dr\.|Prof\.|Sir|Dame|Lord|Lady)\s+([A-Z][a-z]+(?:\s+[A-Z]\.?)?(?:\s+[A-Z][a-z]+)+)\b'
    title_matches = re.findall(title_pattern, text)
    
    return matches + title_matches


def clean_name(name: str) -> str:
    """Clean and normalize a name."""
    # Remove extra whitespace and newlines
    name = re.sub(r'\s+', ' ', name.strip())
    # Remove common titles and suffixes
    titles = r'^(Mr\.|Mrs\.|Ms\.|Dr\.|Prof\.|Sir|Dame|Lord|Lady)\s+'
    suffixes = r'\s+(Jr\.|Sr\.|III|II|IV|PhD|MD|Esq\.)$'
    name = re.sub(titles, '', name, flags=re.IGNORECASE)
    name = re.sub(suffixes, '', name, flags=re.IGNORECASE)
    return name


def is_valid_name(name: str) -> bool:
    """Check if extracted string is likely a person name."""
    # Must have at least 3 characters
    if len(name) < 3:
        return False
    
    # Should contain at least one space (first and last name)
    if ' ' not in name:
        return False
    
    # Split into parts
    parts = name.split()
    
    # Should have 2-4 parts (first, middle, last, suffix)
    if len(parts) < 2 or len(parts) > 4:
        return False
    
    # Each part should start with capital letter
    if not all(part[0].isupper() for part in parts if part and part[0].isalpha()):
        return False
    
    # Filter out common false positives
    false_positives = {
        'United States', 'New York', 'Los Angeles', 'San Francisco',
        'White House', 'Supreme Court', 'Wall Street', 'Main Street',
        'World War', 'Cold War', 'Civil War', 'Great Depression',
        'Federal Reserve', 'State Department', 'Defense Department',
        'Harvard University', 'Yale University', 'Stanford University',
        'Oxford University', 'Cambridge University',
        'The New', 'New York Times', 'Washington Post', 'Associated Press',
        'Republican Party', 'Democratic Party', 'Green Party',
        'Middle East', 'Far East', 'Western Europe', 'Eastern Europe',
        'North America', 'South America', 'Central America',
        'Chapter One', 'Chapter Two', 'Part One', 'Part Two',
        'First World', 'Second World', 'Third World',
        'Old Testament', 'New Testament'
    }
    
    if name in false_positives:
        return False
    
    # Filter out names that are all common words
    common_words = {'The', 'And', 'But', 'For', 'With', 'From', 'Into', 'About'}
    if all(part in common_words for part in parts):
        return False
    
    return True


# Functional pipeline components
compose = lambda *funcs: reduce(lambda f, g: lambda x: f(g(x)), funcs, lambda x: x)
flatten = lambda lst: list(chain.from_iterable(lst))
unique = lambda lst: list(dict.fromkeys(lst))  # Preserves order


def extract_names_from_pdf(filepath: str) -> List[str]:
    """Main functional pipeline to extract names from PDF."""
    # Define the pipeline
    pipeline = compose(
        sorted,  # Sort alphabetically
        unique,  # Remove duplicates
        partial(filter, is_valid_name),  # Filter valid names
        partial(map, clean_name),  # Clean names
        flatten,  # Flatten list of lists
        partial(map, extract_potential_names),  # Extract names from each page
        read_pdf  # Read PDF pages
    )
    
    return pipeline(filepath)


def write_adoc(names: List[str], output_file: str) -> None:
    """Write names to AsciiDoc file, one per line."""
    content = '\n'.join(names)
    with open(output_file, 'w') as f:
        f.write(content)


if __name__ == "__main__":
    pdf_path = "/Users/kh/mzDrive/pdf/TechnoDystopiaibertarianhell_TLS.pdf"
    output_path = "/Users/kh/dev/yardat/techDys.adoc"
    
    print("Extracting names from PDF...")
    names = extract_names_from_pdf(pdf_path)
    
    print(f"Found {len(names)} unique names")
    write_adoc(names, output_path)
    print(f"Names written to {output_path}")