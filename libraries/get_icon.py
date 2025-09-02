#!/usr/bin/env python3
"""
Ikon kezelő script Robot Framework számára
"""
import sys
import os

# Csendes mód beállítása
os.environ['DUPLIKACIO_SILENT'] = '1'

from duplikacio_config import DuplikacioConfig

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("ERROR: Icon name required", file=sys.stderr)  # [DEBUG] commented out for production
        sys.exit(1)
    
    icon_name = sys.argv[1]
    config = DuplikacioConfig()
    print(config.get_icon(icon_name), end='')  # [DEBUG] commented out for production
