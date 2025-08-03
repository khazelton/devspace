#!/usr/bin/env python3
"""
Extract person names from PDF using functional programming approach.
"""

import re
from functools import reduce, partial
from itertools import chain
from typing import List, Set, Callable, Iterable
import PyPDF2
import spacy

# Load spaCy model for NER
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    print("Installing spaCy English model...")
    import subprocess
    subprocess.run(["python", "-m", "spacy", "download", "en_core_web_sm"])
    nlp = spacy.load("en_core_web_sm")


def read_pdf(filepath: str) -> List[str]:
    """Read PDF and return list of text from all pages."""
    with open(filepath, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        return [page.extract_text() for page in reader.pages]


def extract_entities(text: str) -> List[str]:
    """Extract named entities from text using spaCy."""
    doc = nlp(text)
    return [ent.text for ent in doc.ents if ent.label_ == "PERSON"]


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
    """Check if extracted entity is likely a person name."""
    # Must have at least 2 characters
    if len(name) < 2:
        return False
    # Should contain at least one space (first and last name)
    if ' ' not in name:
        return False
    # Should not be all uppercase or all lowercase
    if name.isupper() or name.islower():
        return False
    # Should not contain numbers or special characters (except . and -)
    if re.search(r'[0-9@#$%^&*()_+=\[\]{};:"<>?/\\|]', name):
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
        partial(map, extract_entities),  # Extract entities from each page
        read_pdf  # Read PDF pages
    )
    
    return pipeline(filepath)


def write_adoc(names: List[str], output_file: str) -> None:
    """Write names to AsciiDoc file, one per line."""
    content = '\n'.join(names)
    with open(output_file, 'w') as f:
        f.write(content)


if __name__ == "__main__":
    pdf_path = "/Users/kh/mzDrive/pdf/YarvinPlotAmerica.pdf"
    output_path = "/Users/kh/dev/yardat/yarPlot.adoc"
    
    print("Extracting names from PDF...")
    names = extract_names_from_pdf(pdf_path)
    
    print(f"Found {len(names)} unique names")
    write_adoc(names, output_path)
    print(f"Names written to {output_path}")