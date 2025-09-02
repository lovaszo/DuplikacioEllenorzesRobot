#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Duplikacio Configuration Reader
===============================
Konfiguracios fajl olvasasa es beallitasok betoltese
"""

import os
import sys

# Globális flag a többszörös kiírás elkerülésére
_config_loaded_msg_shown = False

class DuplikacioConfig:
    def __init__(self, config_file="Duplikacio.config"):
        """Konfiguracios fajl inicializalasa"""
        self.config_file = config_file
        self.config = {}
        self.load_config()
    
    def load_config(self):
        """Konfiguracios fajl betoltese"""
        global _config_loaded_msg_shown
        
        # Ellenőrizzük a környezeti változót is
        silent_mode = os.environ.get('DUPLIKACIO_SILENT', '0') == '1'
        
        if not os.path.exists(self.config_file):
            if not _config_loaded_msg_shown and not silent_mode:
                print(f"{self.get_icon('warning')}  Konfiguracios fajl nem talalhato: {self.config_file}")
                print(f"{self.get_icon('config')} Alapertelmezett beallitasok hasznalata...")
                _config_loaded_msg_shown = True
            self.set_defaults()
            return

        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            for line_num, line in enumerate(lines, 1):
                line = line.strip()
                
                # Uregek es kommentek kihagyasa
                if not line or line.startswith('#'):
                    continue
                
                # Kulcs=ertek parok feldolgozasa
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    self.config[key] = value
                else:
                    print(f"{self.get_icon('warning')}  Hibas sor a konfiguracios fajlban ({line_num}): {line}")
            
            if not _config_loaded_msg_shown and not silent_mode:
                print(f"Konfiguracio sikeresen betoltve: {self.config_file}")
                _config_loaded_msg_shown = True
            
        except Exception as e:
            print(f"Hiba a konfiguracio betoltesekor: {e}")
            print("Alapertelmezett beallitasok hasznalata...")
            self.set_defaults()

    def set_defaults(self):
        """Alapertelmezett beallitasok"""
        self.config = {
            'email': 'lovasz.otto@clarity.hu',
            'input_folder': './test',
            'output_folder': './test',
            'database_file': 'test_database.db',
            'email_subject': 'Duplikacio Ellenorzes - Eredmenyek',
            'excel_prefix': 'duplikacio_export',
            'debug_mode': 'false',
            'status_threshold_gyanus': '300',
            'status_threshold_masolt': '1200'
        }
    
    def get(self, key, default=None):
        """Konfiguracios ertek lekerese"""
        return self.config.get(key, default)
    
    def get_email(self):
        """Email cim lekerese"""
        return self.get('email', 'lovasz.otto@clarity.hu')
    
    def get_input_folder(self):
        """Bementi konyvtar lekerese"""
        folder = self.get('input_folder', './test')
        # Backslash-ek normalizalasa
        return os.path.normpath(folder)
    
    def get_output_folder(self):
        """Kimeneti konyvtar lekerese"""
        folder = self.get('output_folder', './test')
        return os.path.normpath(folder)
    
    def get_database_file(self):
        """Adatbazis fajl nev lekerese"""
    def get_database_file(self):
        """Adatbazis fajl nev lekerese"""
        db_file = self.get('database_file', 'test_database.db')
    # print(f"[DEBUG] Betöltött adatbázisfájl: {db_file}")
        return db_file
    
    def get_email_subject(self):
        """Email targy lekerese"""
        return self.get('email_subject', 'Duplikacio Ellenorzes - Eredmenyek')
    
    def get_excel_prefix(self):
        """Excel fajl prefix lekerese"""
        return self.get('excel_prefix', 'duplikacio_export')
    
    def is_debug_mode(self):
        """Debug mod ellenorzese"""
        return self.get('debug_mode', 'false').lower() == 'true'
    
    def get_status_threshold_gyanus(self):
        """Gyanus statusz kuszoberteke"""
        return int(self.get('status_threshold_gyanus', '300'))

    def get_status_threshold_masolt(self):
        """Masolt statusz kuszoberteke"""
        return int(self.get('status_threshold_masolt', '1200'))
    
    def get_console_mode(self):
        """Konzol megjelenítés mód (unicode/ascii)"""
        return self.get('console_mode', 'unicode').lower()
    
    def is_unicode_mode(self):
        """Unicode karakterek használhatók-e"""
        return self.get_console_mode() == 'unicode'
    
    def get_icon(self, icon_name):
        """Ikon visszaadása a konzol mód szerint"""
        unicode_icons = {
            'config': '📋',
            'email': '📧', 
            'folder_in': '📂',
            'folder_out': '📁',
            'subject': '📬',
            'excel': '📊',
            'target': '🎯',
            'search': '🔍',
            'chart': '📈',
            'green': '🟢',
            'yellow': '🟡', 
            'red': '🔴',
            'trophy': '🏆',
            'check': '✅',
            'cross': '❌',
            'warning': '⚠️',
            'database': '🗄️',
            'debug': '🐛',
            'error': '🚨',
            'computer': '💻'
        }
        
        ascii_icons = {
            'config': '[CONFIG]',
            'email': '[EMAIL]',
            'folder_in': '[INPUT]',
            'folder_out': '[OUTPUT]',
            'subject': '[SUBJECT]',
            'excel': '[EXCEL]',
            'target': '[TARGET]',
            'search': '[SEARCH]',
            'chart': '[CHART]',
            'green': '[OK]',
            'yellow': '[WARN]',
            'red': '[ERROR]',
            'trophy': '[RESULT]',
            'check': '[OK]',
            'cross': '[FAIL]',
            'warning': '[WARN]',
            'database': '[DB]',
            'debug': '[DEBUG]',
            'error': '[ERROR]',
            'computer': '[PC]'
        }
        
        if self.is_unicode_mode():
            return unicode_icons.get(icon_name, icon_name)
        else:
            return ascii_icons.get(icon_name, icon_name)
    
    def print_config(self):
        """Aktualis konfiguracio kiirasa"""
        print(f"\n{self.get_icon('config')} AKTUALIS KONFIGURACIO:")
        print("=" * 40)
        print(f"{self.get_icon('email')} Email cim: {self.get_email()}")
        print(f"{self.get_icon('folder_in')} Bementi konyvtar: {self.get_input_folder()}")
        print(f"{self.get_icon('folder_out')} Kimeneti konyvtar: {self.get_output_folder()}")
        print(f"{self.get_icon('database')}  Adatbazis fajl: {self.get_database_file()}")
        print(f"{self.get_icon('subject')} Email targy: {self.get_email_subject()}")
        print(f"{self.get_icon('excel')} Excel prefix: {self.get_excel_prefix()}")
        print(f"{self.get_icon('debug')} Debug mod: {self.is_debug_mode()}")
        print(f"{self.get_icon('warning')}  Gyanus kuszob: {self.get_status_threshold_gyanus()}")
        print(f"{self.get_icon('error')} Masolt kuszob: {self.get_status_threshold_masolt()}")
        print(f"{self.get_icon('computer')} Konzol mod: {self.get_console_mode()}")
        print("=" * 40)

# Teszt funkció
if __name__ == "__main__":
    config = DuplikacioConfig()
    config.print_config()
