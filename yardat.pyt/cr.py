#!/usr/bin/env python3

import sys
import re
from typing import List, Dict

def read_lines_from_file(filename: str) -> List[str]:
    """
    Pure function: filename → List[str]
    Reads all lines from a file and returns them as a list
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

def create_replacement_map(lines: List[str]) -> Dict[str, str]:
    """
    Pure function: List[str] → Dict[str, str]
    Creates a mapping from {n} patterns to corresponding line text
    """
    replacement_map = {}
    for i, line in enumerate(lines):
        if line:  # Skip empty lines
            replacement_map[f"{{{i}}}"] = line
            replacement_map[f"{{{i+1}}}"] = line  # Support both 0-based and 1-based indexing
    return replacement_map

def replace_expressions(text: str, replacement_map: Dict[str, str]) -> str:
    """
    Pure function: (str, Dict[str, str]) → str
    Replaces {n} expressions in text with corresponding values from replacement_map
    """
    def replace_func(match):
        pattern = match.group(0)
        return replacement_map.get(pattern, pattern)  # Return original if not found
    
    # Match {n} where n is any number
    pattern = r'\{\d+\}'
    return re.sub(pattern, replace_func, text)

def generate_cypher_statements(lines: List[str]) -> List[str]:
    """
    Pure function: List[str] → List[str]
    Generates Cypher CREATE/MERGE statements for each line with incremental IDs
    """
    template = 'MERGE (p{m}:Person { Id: "{m}", Name: "{n}" });'
    cypher_statements = []
    m = 1   # Initialize counter to 1 for the appended lines
    
    for line in lines:
        if line.strip():  # Skip empty lines
            cypher_statement = template.replace('{m}', str(m)).replace('{n}', line.strip())
            cypher_statements.append(cypher_statement)
            m += 1  # Increment counter
    
    return cypher_statements

# This function writes a list of Cypher statements to a file, appending to the file if it already exists. If an I/O error occurs, it prints the error message and exits the program.
def write_cypher_to_file(statements: List[str], filename: str) -> None:
    """
    Function with side effects: appends Cypher statements to file
    """
    try:
        with open(filename, 'a', encoding='utf-8') as f:
            for statement in statements:
                f.write(statement + '\n')
    except IOError as e:
        print(f"Error writing to file '{filename}': {e}")
        sys.exit(1)


# This main function reads a file (yarPlot.adoc), generates Cypher statements from its contents, and writes those statements to another file (cr.cypher). It then prints the number of generated Cypher statements and the output filename.
def main():
    """
    Main function implementing the composition:
    filename → List[str] → List[str] → file output
    """
    input_filename = "set4.adoc"
    output_filename = "all.cypher"
    
    # Function composition: filename → lines → cypher_statements → file
    lines = read_lines_from_file(input_filename)
    cypher_statements = generate_cypher_statements(lines)
    write_cypher_to_file(cypher_statements, output_filename)
    
    print(f"Generated {len(cypher_statements)} Cypher statements in {output_filename}")

if __name__ == "__main__":
    main()