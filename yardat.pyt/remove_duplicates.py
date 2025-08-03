#!/usr/bin/env python3
"""
Functional Python script to remove lines from file2 that match lines in file1.
"""

from functools import reduce, partial
from typing import Set, List, Callable
import sys


def read_lines(filepath: str) -> List[str]:
    """Read lines from a file, stripping whitespace."""
    with open(filepath, 'r') as f:
        return [line.strip() for line in f if line.strip()]


def write_lines(lines: List[str], filepath: str) -> None:
    """Write lines to a file."""
    with open(filepath, 'w') as f:
        f.write('\n'.join(lines))
        if lines:  # Add newline at end if there are lines
            f.write('\n')


def lines_to_set(lines: List[str]) -> Set[str]:
    """Convert list of lines to a set for efficient lookup."""
    return set(lines)


def filter_not_in_set(name_set: Set[str]) -> Callable[[str], bool]:
    """Return a predicate function that checks if a line is NOT in the given set."""
    return lambda line: line not in name_set


def remove_duplicates(file1_path: str, file2_path: str) -> None:
    """
    Remove lines from file2 that appear in file1.
    Uses functional programming approach.
    """
    # Functional pipeline
    compose = lambda *funcs: reduce(lambda f, g: lambda x: f(g(x)), funcs, lambda x: x)
    
    # Read file1 and create a set of names to exclude
    file1_names = compose(
        lines_to_set,
        read_lines
    )(file1_path)
    
    # Read file2, filter out names that appear in file1, and write back
    pipeline = compose(
        partial(write_lines, filepath=file2_path),
        list,  # Convert filter object to list
        partial(filter, filter_not_in_set(file1_names)),
        read_lines
    )
    
    pipeline(file2_path)
    
    # Return statistics for reporting
    original_lines = read_lines(file2_path)
    return len(file1_names), len(original_lines)


def main():
    """Main function to handle command line arguments."""
    if len(sys.argv) != 3:
        print("Usage: python remove_duplicates.py <file1> <file2>")
        print("Removes lines from file2 that appear in file1")
        sys.exit(1)
    
    file1_path = sys.argv[1]
    file2_path = sys.argv[2]
    
    try:
        # Get initial count for reporting
        initial_count = len(read_lines(file2_path))
        
        # Perform the removal
        remove_duplicates(file1_path, file2_path)
        
        # Get final count
        final_count = len(read_lines(file2_path))
        
        # Report results
        print(f"File 1: {file1_path}")
        print(f"File 2: {file2_path}")
        print(f"Lines in file2 before: {initial_count}")
        print(f"Lines in file2 after: {final_count}")
        print(f"Lines removed: {initial_count - final_count}")
        
    except FileNotFoundError as e:
        print(f"Error: File not found - {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()