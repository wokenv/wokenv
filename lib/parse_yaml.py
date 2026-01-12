#!/usr/bin/env python3
"""
YAML Parser Helper for Wokenv
Fallback parser when yq is not available
"""

import sys
import yaml
from pathlib import Path

def parse_yaml_value(yaml_file, key_path, default=None):
    """
    Parse YAML file and extract value at key path.
    
    Args:
        yaml_file: Path to YAML file
        key_path: Dot-notation path (e.g., 'image.node')
        default: Default value if key not found
    
    Returns:
        Value at key path or default
    """
    try:
        with open(yaml_file, 'r') as f:
            data = yaml.safe_load(f)
        
        # Navigate through key path
        keys = key_path.split('.')
        value = data
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        
        return value if value is not None else default
    
    except Exception as e:
        # Silently return default on any error
        return default

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: parse_yaml.py <yaml_file> <key_path> [default]", file=sys.stderr)
        sys.exit(1)
    
    yaml_file = sys.argv[1]
    key_path = sys.argv[2]
    default = sys.argv[3] if len(sys.argv) > 3 else None
    
    result = parse_yaml_value(yaml_file, key_path, default)
    print(result if result is not None else '')
