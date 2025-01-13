# Used claude.ai to generate this code to split my evernote enx backup into
# smaller chunks because I couldn't import big chunks.  Even evernote's ability
# to break it up into 300MB chunks was too large.
#
# Works great.

import xml.etree.ElementTree as ET
import datetime
import os

def split_enex_file(input_file, notes_per_file=50):
    """
    Split an Evernote .enex export file into multiple files with specified number of notes per file.
    
    Args:
        input_file (str): Path to input .enex file
        notes_per_file (int): Number of notes per output file (default: 100)
    """
    # Parse the input XML file
    tree = ET.parse(input_file)
    root = tree.getroot()
    
    # Get all notes
    notes = root.findall('note')
    total_notes = len(notes)
    
    # Calculate number of output files needed
    num_files = (total_notes + notes_per_file - 1) // notes_per_file
    
    # Get the base filename without extension
    base_filename = os.path.splitext(input_file)[0]
    
    # Process notes in chunks
    for file_num in range(num_files):
        # Create a new root element for this file
        new_root = ET.Element('en-export')
        
        # Copy export date and application attributes from original
        for attr, value in root.attrib.items():
            new_root.set(attr, value)
        
        # Calculate start and end indices for this chunk
        start_idx = file_num * notes_per_file
        end_idx = min((file_num + 1) * notes_per_file, total_notes)
        
        # Add notes to this file
        for note in notes[start_idx:end_idx]:
            new_root.append(note)
        
        # Create new tree and write to file
        new_tree = ET.ElementTree(new_root)
        output_filename = f"{base_filename}_part{file_num + 1}.enex"
        
        # Use UTF-8 encoding and include XML declaration
        with open(output_filename, 'wb') as f:
            f.write(b'<?xml version="1.0" encoding="UTF-8"?>\n')
            new_tree.write(f, encoding='utf-8', xml_declaration=False)
        
        print(f"Created {output_filename} with {end_idx - start_idx} notes")

def main():
    # Example usage
    input_file = "ahinmaine01.enex"
    if os.path.exists(input_file):
        split_enex_file(input_file)
        print("Processing complete!")
    else:
        print(f"Error: Could not find input file '{input_file}'")

if __name__ == "__main__":
    main()