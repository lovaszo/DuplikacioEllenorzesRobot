#!/usr/bin/env python3
"""
Email küldő script a duplikáció ellenőrzés eredményeihez
Használja a Duplikacio.config konfigurációs fájlt
"""
import os
import sys
import glob
import sqlite3
from datetime import datetime

# A libraries könyvtár hozzáadása a path-hoz
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from duplikacio_config import DuplikacioConfig

def get_status_icon(status, max_ismetelt_karakterszam):
    """Státusz ikon meghatározása"""
    config = DuplikacioConfig()
    threshold_gyanus = config.get_status_threshold_gyanus()
    threshold_masolt = config.get_status_threshold_masolt()
    
    if status == "Rendben" or max_ismetelt_karakterszam < threshold_gyanus:
        return "🟢 Rendben"
    elif status == "Gyanús" or (threshold_gyanus <= max_ismetelt_karakterszam < threshold_masolt):
        return "🟡 Gyanús"
    elif status == "Másolt" or max_ismetelt_karakterszam >= threshold_masolt:
        return "🔴 Másolt"
    else:
        return "⚪ Ismeretlen"

def get_redundancia_statistics():
    """Statisztikák lekérése az adatbázisból"""
    config = DuplikacioConfig()
    threshold_gyanus = config.get_status_threshold_gyanus()
    threshold_masolt = config.get_status_threshold_masolt()
    conn = sqlite3.connect(config.get_database_file())
    cursor = conn.cursor()
        # Redundancia tábla automatikus létrehozása, ha nem létezik
        create_sql = '''
            CREATE TABLE IF NOT EXISTS redundancia (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                status TEXT DEFAULT 'Rendben',
                file_path TEXT NOT NULL,
                file_name TEXT NOT NULL,
                file_size INTEGER NOT NULL,
                record_date TEXT NOT NULL,
                record_time TEXT NOT NULL,
                max_ismetlesek_szama INTEGER DEFAULT 0,
                max_ismetelt_karakterszam INTEGER DEFAULT 0,
                overview TEXT DEFAULT ''
            )
        '''
        print('CREATE TABLE redundancia végrehajtva:')
        print(create_sql)
        cursor.execute(create_sql)
        # hashCodes tábla létrehozása
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS hashCodes (
                hash_value TEXT(100) PRIMARY KEY,
                file_name TEXT NOT NULL,
                file_path TEXT NOT NULL,
                created_date TEXT NOT NULL,
                created_time TEXT NOT NULL,
                line_content TEXT,
                redundancia_id INTEGER,
                FOREIGN KEY (redundancia_id) REFERENCES redundancia(id)
            )
        ''')
        # repeat tábla létrehozása
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS repeat (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                file_name TEXT NOT NULL,
                source_file_path TEXT,
                source_file_name TEXT NOT NULL,
                redundancia_id INTEGER,
                block_id INTEGER NOT NULL,
                line_length INTEGER NOT NULL,
                sum_line_length INTEGER DEFAULT 0,
                repeated_line TEXT NOT NULL,
                created_date TEXT NOT NULL,
                created_time TEXT NOT NULL,
                FOREIGN KEY (redundancia_id) REFERENCES redundancia(id)
            )
        ''')
        
        # Összesített statisztikák lekérése
    # Összesített statisztikák lekérése
            cursor.execute(f"""
                SELECT 
                    COUNT(*) as total_documents,
                    SUM(CASE WHEN max_ismetelt_karakterszam < {threshold_gyanus} THEN 1 ELSE 0 END) as rendben,
                    SUM(CASE WHEN max_ismetelt_karakterszam >= {threshold_gyanus} AND max_ismetelt_karakterszam < {threshold_masolt} THEN 1 ELSE 0 END) as gyanus,
                    SUM(CASE WHEN max_ismetelt_karakterszam >= {threshold_masolt} THEN 1 ELSE 0 END) as masolt
                FROM redundancia
            """)
            stats = cursor.fetchone()
            # A mai nap feldolgozott fájlok lekérése státusszal
            cursor.execute("""
                SELECT file_name, record_date, record_time, status, max_ismetelt_karakterszam, overview
                FROM redundancia 
                WHERE record_date = date('now')
                ORDER BY record_time DESC
            """)
            today_files = cursor.fetchall()
            conn.close()
            if stats:
                total, rendben, gyanus, masolt = stats
                if total > 0:
                    rendben_percent = round((rendben / total) * 100, 1)
                    gyanus_percent = round((gyanus / total) * 100, 1)
                    masolt_percent = round((masolt / total) * 100, 1)
                    return {
                        'total': total,
                        'rendben': rendben,
                        'gyanus': gyanus,
                        'masolt': masolt,
                        'rendben_percent': rendben_percent,
                        'gyanus_percent': gyanus_percent,
                        'masolt_percent': masolt_percent,
                        'today_files': today_files
                    }
            return None
        except Exception as e:
            # print(f"HIBA: Statisztikák lekérése sikertelen - {str(e)}")  # [DEBUG] commented out for production
            return None
    # (A belső except blokk eltávolítva, csak a külső try-except marad)
    output_folder = config.get_output_folder()
    email_subject = config.get_email_subject()
    excel_prefix = config.get_excel_prefix()
    from_email = "duplikacio.ellenorzo@system.local"  # Módosítható
    subject = f"{email_subject} - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
    # Legújabb Excel fájl keresése a konfigurált output mappában
    search_pattern = os.path.join(output_folder, f"{excel_prefix}_*.xlsx")
    excel_files = glob.glob(search_pattern)
    
    if not excel_files:
    # print(f"HIBA: Nincs Excel fájl a(z) {output_folder} könyvtárban!")  # [DEBUG] commented out for production
    # print(f"Keresett minta: {search_pattern}")  # [DEBUG] commented out for production
        return False
    
    # Legújabb fájl kiválasztása
    latest_excel = max(excel_files, key=os.path.getctime)
    excel_filename = os.path.basename(latest_excel)
    
    # print(f"Excel fájl csatolása: {excel_filename}")  # [DEBUG] commented out for production
    
    # Statisztikák lekérése az adatbázisból
    stats = get_redundancia_statistics()
    
    # Email tartalom összeállítása
    if stats:
        # Mai feldolgozott fájlok listája státusz ikonokkal
        today_files_text = ""
        if stats.get('today_files'):
            today_files_text = f"""
📁 MA FELDOLGOZOTT FÁJLOK ({len(stats['today_files'])} db):
═════════════════════════════════════════════
"""
            for i, (file_name, record_date, record_time, status, max_karakter, overview) in enumerate(stats['today_files'], 1):
                status_icon = get_status_icon(status, max_karakter if max_karakter else 0)
                overview_display = overview if overview else "Nincs adat"
                today_files_text += f"{i:2d}. {status_icon} - {file_name} ({record_time})\n"
                today_files_text += f"     📋 Overview: {overview_display}\n"
        else:
            today_files_text = "\n📁 MA FELDOLGOZOTT FÁJLOK: Nincs új fájl\n"
        
        stats_text = f"""{today_files_text}
🏆 VÉGSŐ ÖSSZESÍTÉS:
═══════════════════════
📊 Összes dokumentum: {stats['total']}
🟢 Rendben: {stats['rendben']} dokumentum ({stats['rendben_percent']}%)
🟡 Gyanús: {stats['gyanus']} dokumentum ({stats['gyanus_percent']}%)
🔴 Másolt: {stats['masolt']} dokumentum ({stats['masolt_percent']}%)

⚙️ KONFIGURÁCIÓ:
═════════════════
📧 Email címzett: {to_email}
📂 Bemeneti könyvtár: {config.get_input_folder()}
📁 Kimeneti könyvtár: {output_folder}
🗄️ Adatbázis fájl: {config.get_database_file()}
📊 Excel prefix: {excel_prefix}

🎯 STÁTUSZ KATEGÓRIÁK SZABÁLYAI:
🟢 Rendben: max_ismételt_karakterszám < {config.get_status_threshold_gyanus()}
🟡 Gyanús: {config.get_status_threshold_gyanus()} ≤ max_ismételt_karakterszám < {config.get_status_threshold_masolt()}  
🔴 Másolt: max_ismételt_karakterszám ≥ {config.get_status_threshold_masolt()}
"""
    else:
        stats_text = f"""
📊 Statisztikák nem elérhetőek.

⚙️ KONFIGURÁCIÓ:
═════════════════
📧 Email címzett: {to_email}
📂 Bemeneti könyvtár: {config.get_input_folder()}
📁 Kimeneti könyvtár: {output_folder}
🗄️ Adatbázis fájl: {config.get_database_file()}
📊 Excel prefix: {excel_prefix}
"""
    
    # Email tartalom összeállítása HTML formátumban
    excel_full_path = os.path.abspath(latest_excel)
    excel_hyperlink = f'file:///{excel_full_path.replace(os.sep, "/")}'
    
    # HTML email tartalom
    html_body = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: Segoe UI, Tahoma, Geneva, Verdana, sans-serif; margin: 20px; line-height: 1.6; }}
        h2 {{ color: #2c3e50; }}
        .info-section {{ background-color: #f8f9fa; padding: 12px; border-left: 4px solid #007bff; margin: 10px 0; }}
        .excel-link {{ background-color: #fff3cd; padding: 10px; border: 1px solid #ffeaa7; border-radius: 5px; margin: 10px 0; }}
        .excel-link a {{ color: #0066cc; text-decoration: none; font-weight: bold; }}
        .excel-link a:hover {{ text-decoration: underline; }}
        ul {{ padding-left: 20px; }}
        li {{ margin: 5px 0; }}
        .timestamp {{ color: #6c757d; font-size: 0.9em; }}
    </style>
</head>
<body>
    <h2>📊 Duplikáció Ellenőrzés Eredményei</h2>
    <p>Kedves Otto!</p>
    <p>A duplikáció ellenőrzés sikeresen befejeződött.</p>
    
    <div class="info-section">
        <h3>📋 Eredmények</h3>
        <ul>
            <li>🕒 <strong>Futtatás időpontja:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</li>
            <li>📁 <strong>Excel export:</strong> {excel_filename}</li>
        </ul>
    </div>
    
    <div class="excel-link">
        <h3>📎 Excel Fájl Elérése</h3>
        <p><strong>Teljes útvonal:</strong></p>
        <p><a href="{excel_hyperlink}" title="Kattintson a fájl megnyitásához">{excel_full_path}</a></p>
        <p><em>Kattintson a fenti linkre az Excel fájl megnyitásához, vagy használja a csatolt fájlt.</em></p>
    </div>
    
{stats_text}
    
    <p>📎 A részletes eredmények a csatolt Excel fájlban is találhatók.</p>
    
    <hr>
    <p class="timestamp">
        🤖 <strong>Automatikus riport</strong><br>
        Duplikáció Ellenőrző Rendszer
    </p>
</body>
</html>"""

    # Sima szöveges verzió is (fallback)
    text_body = f"""Kedves Otto!

A duplikáció ellenőrzés sikeresen befejeződött.

📋 Eredmények:
- 🕒 Futtatás időpontja: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- 📁 Excel export: {excel_filename}
- 📂 Teljes útvonal: {excel_full_path}

{stats_text}
📎 A részletes eredmények a csatolt Excel fájlban találhatók.

🤖 Automatikus riport
Duplikáció Ellenőrző Rendszer
"""

    try:
        # Outlook COM használata (megbízható módszer)
        try:
            import win32com.client
            import time
            
            # print("Outlook COM objektum létrehozása...")  # [DEBUG] commented out for production
            outlook = win32com.client.Dispatch("Outlook.Application")
            
            # Kis várakozás a COM objektum inicializálásához
            time.sleep(1)
            
            mail = outlook.CreateItem(0)  # 0 = olMailItem
            
            # print(f"Email címzett beállítása: {to_email}")  # [DEBUG] commented out for production
            mail.To = to_email
            mail.Subject = subject
            mail.HTMLBody = html_body
            mail.Body = text_body
            
            # print(f"Excel fájl csatolása: {os.path.abspath(latest_excel)}")  # [DEBUG] commented out for production
            mail.Attachments.Add(os.path.abspath(latest_excel))
            
            # Kis várakozás az email összeállítás után
            time.sleep(2)
            
            # print("[INFO] Automatikus küldés Outlook-kal...")  # [DEBUG] commented out for production
            
            # Többszörös próbálkozás a küldéssel
            send_attempts = 3
            for attempt in range(send_attempts):
                try:
                    mail.Send()  # Közvetlen küldés
                    # print("[OK] Email automatikusan elküldve Outlook-kal!")  # [DEBUG] commented out for production
                    # print("[INFO] Email sikeresen továbbítva a címzettnek.")  # [DEBUG] commented out for production
                    # print("[INFO] Az email minden csatolmánnyal elküldve.")  # [DEBUG] commented out for production
                    # print("[OK] DUPLIKACIO ELLENORZÉS TELJES FOLYAMATA SIKERESEN BEFEJEZVE!")  # [DEBUG] commented out for production
                    return True
                except Exception as send_error:
                    # print(f"[WARN] Küldési kísérlet {attempt + 1}/{send_attempts} sikertelen: {send_error}")  # [DEBUG] commented out for production
                    if attempt < send_attempts - 1:
                        # print("[INFO] Újrapróbálkozás 3 másodperc múlva...")  # [DEBUG] commented out for production
                        time.sleep(3)
                    continue
            
            # Ha a közvetlen küldés nem sikerült, mentés piszkozatba
            # print("[INFO] Közvetlen küldés sikertelen, piszkozat mentés...")  # [DEBUG] commented out for production
            try:
                mail.Save()
                # print("[INFO] Email elmentve a Piszkozatok mappába.")  # [DEBUG] commented out for production
                # print("[WARN] FIGYELEM: Email a Piszkozatok mappában található!")  # [DEBUG] commented out for production
                # print("[INFO] Kérem ellenőrizze a Piszkozatok mappát és küldje el manuálisan!")  # [DEBUG] commented out for production
                # print("[OK] DUPLIKACIO ELLENORZÉS BEFEJEZVE - EMAIL PISZKOZATBAN!")  # [DEBUG] commented out for production
                return True
            except Exception as save_error:
                # print(f"[ERROR] Piszkozat mentés is sikertelen: {save_error}")  # [DEBUG] commented out for production
                return False
            
        except ImportError:
            # print("HIBA: pywin32 nincs telepítve!")  # [DEBUG] commented out for production
            print("Telepítés: pip install pywin32")
            return False
        except Exception as outlook_error:
            print(f"[WARN] Outlook COM hiba: {outlook_error}")
            print("[INFO] Lehetséges okok:")
            print("1. Outlook nincs elindítva")
            print("2. Outlook profil nincs beállítva")
            print("3. COM objektum hozzáférési problémák")
            return False
            
    except Exception as e:
        print(f"HIBA: Email kuldes sikertelen - {str(e)}")
        return False

if __name__ == "__main__":
    try:
    # success = send_email_with_excel()
        
        if success:
            print("Email kuldes sikeres!")
        else:
            print("Email kuldes sikertelen!")
            print("Manualis kuldes szukseges:")
            print("   Cimzett: lovasz.otto@clarity.hu")
            print("   Csatolmany: test/ konyvtarban talalhato legujabb .xlsx fajl")
            exit(1)
    except Exception as e:
        print(f"Email kuldes hiba: {e}")
        exit(1)
