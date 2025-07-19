#!/usr/bin/env python3
"""
csv_to_json.py: Convert a CSV file to a JSON array.

Usage:
    python csv_to_json.py input.csv output.json
"""

import csv
import json
import argparse


def csv_to_json(input_path: str, output_path: str) -> None:
    """Read a CSV file and write its contents as a JSON array."""
    with open(input_path, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        data = list(reader)
    
    fixed_data = []
    for entry in data:
        fixed_entry = {}
        for k, v in entry.items():
            fixed_entry[k.lower()] = v
        fixed_data.append(fixed_entry)

    with open(output_path, 'w', encoding='utf-8') as jsonfile:
        json.dump(fixed_data, jsonfile, indent=4)

    print(f'Successfully wrote {len(fixed_data)} records to {output_path}')


def main() -> None:
    parser = argparse.ArgumentParser(description='Convert a CSV file to a JSON array')
    parser.add_argument('input', help='Path to the input CSV file')
    parser.add_argument('output', help='Path to the output JSON file')
    args = parser.parse_args()
    
    csv_to_json(args.input, args.output)


if __name__ == '__main__':
    main()
