#!/usr/bin/env python3
"""
Functional module for removing duplicate names between text files.
"""

from functools import reduce, partial
from typing import Set, List, Callable, Tuple
# from compose-operator import compose as op_compose  # Python 3.9+

def op_compose(*funcs):
    def inner(arg):
        return reduce(lambda x, f: f(x), funcs, arg)
    return inner

# Core functional utilities
def compose(*funcs):
    """Compose functions right to left."""
    return reduce(lambda f, g: lambda x: f(g(x)), funcs, lambda x: x)


def pipe(*funcs):
    """Pipe functions left to right (more readable for some)."""
    return reduce(lambda f, g: lambda x: g(f(x)), funcs, lambda x: x)


# File I/O functions
def read_lines(filepath: str) -> List[str]:
    """Read lines from a file, stripping whitespace."""
    with open(filepath, 'r') as f:
        return [line.strip() for line in f if line.strip()]


def write_lines(filepath: str, lines: List[str]) -> None:
    """Write lines to a file (curried for functional composition)."""
    with open(filepath, 'w') as f:
        f.write('\n'.join(lines))
        if lines:  # Add newline at end if there are lines
            f.write('\n')


# Set operations
def to_set(items: List[str]) -> Set[str]:
    """Convert list to set."""
    return set(items)


def not_in_set(exclusion_set: Set[str]) -> Callable[[str], bool]:
    """Create a predicate that tests if item is NOT in the set."""
    return lambda item: item not in exclusion_set


def in_set(inclusion_set: Set[str]) -> Callable[[str], bool]:
    """Create a predicate that tests if item IS in the set."""
    return lambda item: item in inclusion_set


# Main operations
def get_unique_lines(file1: str, file2: str) -> List[str]:
    """Get lines from file2 that don't appear in file1."""
    names_to_exclude = compose(to_set, read_lines)(file1)
    
    return list(filter(
        not_in_set(names_to_exclude),
        read_lines(file2)
    ))


def get_common_lines(file1: str, file2: str) -> List[str]:
    """Get lines that appear in both files."""
    names_from_file1 = compose(to_set, read_lines)(file1)
    
    return list(filter(
        in_set(names_from_file1),
        read_lines(file2)
    ))


def deduplicate_files(file1: str, file2: str, output_file: str = None) -> Tuple[int, int, int]:
    """
    Remove lines from file2 that appear in file1.
    
    Args:
        file1: Path to file containing names to exclude
        file2: Path to file to filter
        output_file: Optional output file path (defaults to overwriting file2)
    
    Returns:
        Tuple of (original_count, filtered_count, removed_count)
    """
    output_file = output_file or file2
    
    # Get counts
    original_lines = read_lines(file2)
    unique_lines = get_unique_lines(file1, file2)
    
    # Write filtered lines
    write_lines(output_file, unique_lines)
    
    return (
        len(original_lines),
        len(unique_lines),
        len(original_lines) - len(unique_lines)
    )


# Higher-order function for creating custom filters
def create_filter(predicate: Callable[[str], bool]) -> Callable[[str, str], List[str]]:
    """
    Create a custom filter function for processing two files.
    
    Args:
        predicate: Function that takes a line and returns True to keep it
    
    Returns:
        Function that takes two file paths and returns filtered lines from file2
    """
    return lambda file1, file2: list(filter(
        predicate,
        read_lines(file2)
    ))


# Example usage functions
def case_insensitive_deduplicate(file1: str, file2: str, output_file: str = None) -> Tuple[int, int, int]:
    """Remove lines from file2 that appear in file1 (case-insensitive)."""
    output_file = output_file or file2
    
    # Convert file1 names to lowercase for comparison
    names_to_exclude = compose(
        lambda names: {name.lower() for name in names},
        read_lines
    )(file1)
    
    # Filter file2 keeping only lines not in file1 (case-insensitive)
    original_lines = read_lines(file2)
    unique_lines = [
        line for line in original_lines 
        if line.lower() not in names_to_exclude
    ]
    
    write_lines(output_file, unique_lines)
    
    return (
        len(original_lines),
        len(unique_lines),
        len(original_lines) - len(unique_lines)
    )


if __name__ == "__main__":
    # Example usage
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python deduplicate_names.py <file1> <file2> [output_file]")
        print("\nRemoves lines from file2 that appear in file1")
        print("If output_file is not specified, file2 will be overwritten")
        sys.exit(1)
    
    file1 = sys.argv[1]
    file2 = sys.argv[2]
    output = sys.argv[3] if len(sys.argv) > 3 else file2
    
    try:
        original, filtered, removed = deduplicate_files(file1, file2, output)
        
        print(f"Deduplication complete:")
        print(f"  Original lines in file2: {original}")
        print(f"  Filtered lines: {filtered}")
        print(f"  Lines removed: {removed}")
        
        if output != file2:
            print(f"  Output written to: {output}")
        else:
            print(f"  File2 updated in place")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)