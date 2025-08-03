#!/usr/bin/env python3

import sys
from typing import List, Set

def read_cypher_file(filename: str) -> List[str]:
    """
    Pure function: filename → List[str]
    Reads all lines from cypher file
    """
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            return [line.strip() for line in f.readlines()]
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        sys.exit(1)
    except IOError as e:
        print(f"Error reading file '{filename}': {e}")
        sys.exit(1)

def remove_duplicates_and_sort(lines: List[str]) -> List[str]:
    """
    Pure function: List[str] → List[str]
    Removes duplicates and sorts lines alphabetically
    """
    unique_lines: Set[str] = set()
    for line in lines:
        if line.strip():  # Skip empty lines
            unique_lines.add(line.strip())
    
    return sorted(list(unique_lines))

def write_sorted_cypher(lines: List[str], filename: str) -> None:
    """
    Function with side effects: writes sorted lines to file
    """
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            for line in lines:
                f.write(line + '\n')
    except IOError as e:
        print(f"Error writing to file '{filename}': {e}")
        sys.exit(1)

def main():
    """
    Main function implementing the composition:
    cr.cypher → List[str] → List[str] → crun.cypher
    """
    input_filename = "cr.cypher"
    output_filename = "crun.cypher"
    
    # Function composition: file → lines → sorted_unique_lines → file
    lines = read_cypher_file(input_filename)
    sorted_unique_lines = remove_duplicates_and_sort(lines)
    write_sorted_cypher(sorted_unique_lines, output_filename)
    
    original_count = len([line for line in lines if line.strip()])
    final_count = len(sorted_unique_lines)
    duplicates_removed = original_count - final_count
    
    print(f"Processed {original_count} lines, removed {duplicates_removed} duplicates")
    print(f"Wrote {final_count} unique sorted lines to {output_filename}")

if __name__ == "__main__":
    main()