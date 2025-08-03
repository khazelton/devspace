#!/usr/bin/env python3

import sys
from typing import List

def read_lines(filename: str) -> List[str]:
    """
    Pure function: (filename, int) → List[str]
    Reads lines from a file
    """
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            lines = []
            for i, line in enumerate(f):
                lines.append(line.strip())
            return lines
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        sys.exit(1)
    except IOError as e:
        print(f"Error reading file '{filename}': {e}")
        sys.exit(1)

def generate_connection_statements(lines: List[str]) -> List[str]:
    """
    Pure function: List[str] → List[str]
    Generates connection statements with incrementing integers starting at 1
    """
    template = "MATCH (r:Person {Id: '48'}) OPTIONAL MATCH (s:Person {Id: '{m}'}) WITH r, s  WHERE s IS NOT NULL MERGE (r)-[:CONNECTED_WITH]->(s);" 

    connection_statements = []
    m = 1  # Initialize counter
    
    for line in lines:
        if line.strip():  # Skip empty lines
            connection_statement = template.replace('{m}', str(m))
            connection_statements.append(connection_statement)
            m += 1  # Increment counter
         
    return connection_statements

def write_to_adoc_file(lines: List[str], filename: str) -> None:
    """
    Function with side effects: writes lines to adoc file
    """
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            for line in lines:
                f.write(line + '\n')
    except IOError as e:
        print(f"Error writing to file '{filename}': {e}")
        sys.exit(1)

# This main function reads the lines from a file named "yarPlot.adoc", generates connection statements from those lines, and writes the statements to a file named "conn.adoc". It then prints the number of lines read and the number of connection statements generated.

def main():
    """
    Main function implementing the composition:
    yarvinPeeps.adoc → List[str] → List[str] → conn.adoc
    """
    input_filename = "set4.adoc"
    output_filename = "conn.adoc"

    
    # Function composition: file → lines[] → connection_statements → file
    fi_lines = read_lines(input_filename)
    connection_statements = generate_connection_statements(fi_lines)
    write_to_adoc_file(connection_statements, output_filename)
    
    print(f"Read {len(fi_lines)} lines from {input_filename}")
    print(f"Generated {len(connection_statements)} connection statements in {output_filename}")

if __name__ == "__main__":
    main()