#!/usr/bin/env python3
"""
JSON Schema Consolidation Script
Consolidates all Serverless Workflow JSON schemas starting from workflow.json
by resolving $ref references and merging definitions into a single schema.
"""

import json
import os
import re
from typing import Dict, Any, Set
from pathlib import Path


class SchemaConsolidator:
    def __init__(self, schema_dir: str):
        self.schema_dir = Path(schema_dir)
        self.schemas: Dict[str, Dict[str, Any]] = {}
        self.processed_refs: Set[str] = set()
        self.consolidated_definitions: Dict[str, Any] = {}

    def load_schema(self, filename: str) -> Dict[str, Any]:
        """Load a JSON schema file and cache it."""
        if filename not in self.schemas:
            file_path = self.schema_dir / filename
            try:
                with open(file_path, 'r') as f:
                    self.schemas[filename] = json.load(f)
                print(f"Loaded schema: {filename}")
            except FileNotFoundError:
                print(f"Warning: Schema file not found: {filename}")
                return {}
        return self.schemas[filename]

    def extract_ref_filename(self, ref: str) -> str:
        """Extract filename from $ref string."""
        # Handle refs like "secrets.json#/secrets" or "common.json#/definitions/metadata"
        if '#' in ref:
            return ref.split('#')[0]
        return ref

    def extract_ref_path(self, ref: str) -> str:
        """Extract JSON path from $ref string."""
        # Handle refs like "secrets.json#/secrets" or "common.json#/definitions/metadata"
        if '#' in ref:
            return ref.split('#')[1]
        return ""

    def resolve_external_refs(self, schema: Dict[str, Any], current_file: str = "") -> Dict[str, Any]:
        """Recursively resolve external $ref references."""
        if isinstance(schema, dict):
            if '$ref' in schema:
                ref = schema['$ref']

                # Skip internal references (starting with #)
                if ref.startswith('#'):
                    return schema

                # Extract filename and path
                ref_file = self.extract_ref_filename(ref)
                ref_path = self.extract_ref_path(ref)

                if ref_file and ref_file != current_file:
                    # Load the referenced schema
                    ref_schema = self.load_schema(ref_file)

                    if ref_schema:
                        # Navigate to the specific path in the referenced schema
                        target = ref_schema
                        if ref_path:
                            path_parts = ref_path.strip('/').split('/')
                            for part in path_parts:
                                if part in target:
                                    target = target[part]
                                else:
                                    print(f"Warning: Path {ref_path} not found in {ref_file}")
                                    return schema

                        # Recursively resolve refs in the target
                        resolved_target = self.resolve_external_refs(target, ref_file)

                        # Also process the entire referenced schema for definitions
                        self.process_schema_definitions(ref_schema, ref_file)

                        return resolved_target

                return schema
            else:
                # Recursively process all dictionary values
                resolved = {}
                for key, value in schema.items():
                    resolved[key] = self.resolve_external_refs(value, current_file)
                return resolved

        elif isinstance(schema, list):
            # Recursively process all list items
            return [self.resolve_external_refs(item, current_file) for item in schema]

        return schema

    def process_schema_definitions(self, schema: Dict[str, Any], filename: str):
        """Extract and merge definitions from a schema into consolidated definitions."""
        if 'definitions' in schema:
            for def_name, def_value in schema['definitions'].items():
                # Create unique key to avoid conflicts
                unique_key = f"{filename.replace('.json', '')}_{def_name}"
                self.consolidated_definitions[unique_key] = self.resolve_external_refs(def_value, filename)
                print(f"Added definition: {unique_key}")

    def update_internal_refs(self, schema: Dict[str, Any], filename: str) -> Dict[str, Any]:
        """Update internal references to point to consolidated definitions."""
        if isinstance(schema, dict):
            if '$ref' in schema:
                ref = schema['$ref']

                # Handle internal references
                if ref.startswith('#/definitions/'):
                    def_name = ref.replace('#/definitions/', '')
                    # Update to use the prefixed definition name
                    new_ref = f"#/definitions/{filename.replace('.json', '')}_{def_name}"
                    return {'$ref': new_ref}

                return schema
            else:
                # Recursively process all dictionary values
                resolved = {}
                for key, value in schema.items():
                    resolved[key] = self.update_internal_refs(value, filename)
                return resolved

        elif isinstance(schema, list):
            # Recursively process all list items
            return [self.update_internal_refs(item, filename) for item in schema]

        return schema

    def consolidate(self, main_schema_file: str = "workflow.json") -> Dict[str, Any]:
        """Main consolidation method."""
        print(f"Starting consolidation from {main_schema_file}")

        # Load the main schema
        main_schema = self.load_schema(main_schema_file)
        if not main_schema:
            raise ValueError(f"Could not load main schema: {main_schema_file}")

        # First pass: collect all definitions from all referenced schemas
        print("\n--- Collecting definitions from all schemas ---")
        for filename in os.listdir(self.schema_dir):
            if filename.endswith('.json'):
                schema = self.load_schema(filename)
                self.process_schema_definitions(schema, filename)

        # Second pass: resolve external references
        print("\n--- Resolving external references ---")
        resolved_main = self.resolve_external_refs(main_schema, main_schema_file)

        # Third pass: update internal references to use consolidated definitions
        print("\n--- Updating internal references ---")
        final_schema = self.update_internal_refs(resolved_main, main_schema_file)

        # Add all consolidated definitions
        if 'definitions' not in final_schema:
            final_schema['definitions'] = {}

        final_schema['definitions'].update(self.consolidated_definitions)

        print(f"\n--- Consolidation complete ---")
        print(f"Total definitions consolidated: {len(self.consolidated_definitions)}")

        return final_schema

    def save_consolidated_schema(self, consolidated_schema: Dict[str, Any], output_file: str):
        """Save the consolidated schema to a file."""
        output_path = output_file
        with open(output_path, 'w') as f:
            json.dump(consolidated_schema, f, indent=2)
        print(f"Consolidated schema saved to: {output_path}")


def main():
    """Main function to run the consolidation."""
    schema_dir = "schema"

    print("JSON Schema Consolidation Tool")
    print("=" * 50)

    consolidator = SchemaConsolidator(schema_dir)

    try:
        # Consolidate starting from workflow.json
        consolidated = consolidator.consolidate("workflow.json")

        # Save the result
        consolidator.save_consolidated_schema(consolidated, "consolidated_workflow_schema.json")
        print("\nConsolidation completed successfully!")
    except Exception as e:
        print(f"Error during consolidation: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
