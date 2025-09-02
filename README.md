<<<<<<< HEAD
# 🤖 Robot Framework Plágium Ellenőrző Rendszer

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-6.1.1-green.svg)](https://robotframework.org/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![SQLite](https://img.shields.io/badge/SQLite-3.x-lightgrey.svg)](https://sqlite.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> 🔍 **Automatizált DOCX dokumentum plágium ellenőrzés** hash-alapú algoritmussal, Excel jelentéskészítéssel és automatikus email értesítéssel.

## ✨ Főbb funkciók

- 🔍 **Automatikus plágium detektálás** SHA-256 hash algoritmussal
- 📊 **Excel jelentések** színkódolt státusz kategóriákkal  
- 📧 **Automatikus email küldés** Outlook COM integrációval
- 🗄️ **SQLite adatbázis** teljes előzmény nyilvántartással
- 🎯 **Háromszintű kategorizálás**: Rendben / Gyanús / Másolt
- 🔄 **Batch feldolgozás** több dokumentum egyidejű kezelésére

## 🚀 Gyors indítás

### 1️⃣ Telepítés
```powershell
# Virtuális környezet aktiválása
rf_env\Scripts\activate

# Vagy egyszerűen
.\telepito.bat
```

### 2️⃣ Konfiguráció
```ini
# Plagium.config szerkesztése
email=your-email@company.com
input_folder=C:\Documents\ToCheck
output_folder=C:\Reports
```

### 3️⃣ Futtatás
```powershell
# Robot Framework teszt futtatása
rf_env\Scripts\robot.exe PLG-00-main.robot

# Vagy batch fájlon keresztül
start.bat
```

## 📊 Eredmény példa

### 📈 Konsol kimenet
```
=== DOCX FÁJLOK KERESÉSE ===
Talált DOCX fájlok száma: 6

🏆 VÉGSŐ ÖSSZESÍTÉS:
📊 Összes dokumentum: 45
🟢 Rendben: 41 dokumentum (91.1%)
🟡 Gyanús: 2 dokumentum (4.4%)  
🔴 Másolt: 2 dokumentum (4.4%)

✅ Excel fájl: plagium_eredmenyek_20250825_040223.xlsx
🎯 PLAGIUM ELLENORZÉS TELJES FOLYAMATA BEFEJEZVE! ✅
```

### 📧 Automatikus email
- **HTML formátumú jelentés** színkódolt státuszokkal
- **Excel melléklet** részletes adatokkal
- **Összesítő statisztikák** százalékos megoszlással

## 🏗️ Rendszer architektúra

```
📁 PlagiumEllenorzes/
├── 🤖 PLG-00-main.robot          # Fő Robot Framework teszt
├── ⚙️ Plagium.config             # Konfigurációs fájl
├── 📚 libraries/                 # Python modulok
│   ├── 🐍 DocxReader.py          # DOCX olvasó library
│   ├── 📧 send_email.py          # Email küldő rendszer
│   ├── 📊 excel_export_simple.py # Excel export engine
│   └── ⚙️ get_config.py          # Konfiguráció betöltő
├── 📂 resources/                 # Robot Framework erőforrások
│   ├── 🔑 keywords.robot         # Kulcsszó definíciók
│   └── 🔢 variables.robot        # Változó definíciók
├── 🗃️ test_database.db           # SQLite adatbázis
└── 🐍 rf_env/                    # Python virtuális környezet
```

## 🔍 Plágium algoritmus

### Hash-alapú összehasonlítás
1. **📄 DOCX beolvasás**: Szöveges tartalom kinyerése
2. **🔐 SHA-256 hash**: Minden sorhoz egyedi hash generálás
3. **🔍 Összehasonlítás**: Hash értékek összevetése adatbázisban
4. **📊 Kategorizálás**: Redundancia hossz alapján értékelés

### Kategorizálási szabályok
- 🟢 **Rendben**: < 300 karakter redundancia
- 🟡 **Gyanús**: 300-1200 karakter redundancia
- 🔴 **Másolt**: > 1200 karakter redundancia

## 📧 Email automatizálás

### Háromszintű küldési stratégia
1. **🎯 Outlook COM**: Automatikus `mail.Send()` hívás
2. **💾 Piszkozat**: Fallback mentés Drafts mappába  
3. **📝 Hibanapló**: Részletes hibajelentés

```python
# Outlook COM automatikus küldés
outlook = win32com.client.Dispatch("Outlook.Application")
mail = outlook.CreateItem(0)
mail.Send()  # 🚀 AUTOMATIKUS KÜLDÉS
```

## 🗄️ Adatbázis struktúra

### 📊 Redundancia tábla
- `status`: Kategorizálás (Rendben/Gyanús/Másolt)
- `file_name`: Dokumentum neve
- `max_ismetelt_karakterszam`: Legnagyobb redundancia
- `record_date`: Feldolgozás dátuma

### 🔑 HashCodes tábla  
- `hash_value`: SHA-256 hash (PRIMARY KEY)
- `file_name`, `file_path`: Fájl információk
- `line_content`: Eredeti szöveg tartalom

### 🔄 Repeat tábla
- `repeated_line`: Ismétlődő szövegrészek
- `block_id`: Ismétlési blokk azonosító
- `sum_line_length`: Összesített redundancia hossz

## ⚙️ Konfiguráció

### Plagium.config beállítások
| Paraméter | Leírás | Példa |
|-----------|--------|-------|
| `email` | Címzett email | `manager@company.hu` |
| `input_folder` | DOCX forrás könyvtár | `C:\Documents\Check` |
| `output_folder` | Excel cél könyvtár | `C:\Reports\Output` |
| `email_subject` | Email tárgy sablon | `Plágium Jelentés` |
| `excel_prefix` | Excel fájl prefix | `plagium_report` |

## 🛠️ Rendszerkövetelmények

- **OS**: Windows 10/11
- **Python**: 3.8+ (python.org)
- **Outlook**: Microsoft Outlook telepítve
- **Memória**: Min. 4GB RAM
- **Tárhely**: Min. 1GB szabad hely

## 📦 Függőségek

```txt
robotframework==6.1.1
robotframework-databaselibrary==1.2.4
python-docx==0.8.11
openpyxl==3.1.2
pywin32==306
```

## 🔧 Telepítés részletesen

### 1️⃣ Python telepítés
```powershell
# Python letöltés: https://python.org
python --version  # Ellenőrzés
```

### 2️⃣ Projekt klónozás
```powershell
git clone https://github.com/your-repo/plagium-checker.git
cd plagium-checker
```

### 3️⃣ Virtuális környezet
```powershell
python -m venv rf_env
rf_env\Scripts\activate
pip install -r requirements.txt
```

### 4️⃣ Konfiguráció
```powershell
notepad Plagium.config  # Email és könyvtárak beállítása
```

## 🧪 Tesztelés

### Unit tesztek
```powershell
# Hash generálás teszt
rf_env\Scripts\python.exe -c "from libraries.DocxReader import *; print('Hash test OK')"

# Email teszt
rf_env\Scripts\python.exe libraries\send_email.py

# Excel export teszt  
rf_env\Scripts\python.exe libraries\excel_export_simple.py test.xlsx
```

### Integrációs teszt
```powershell
# Teljes folyamat dry-run
rf_env\Scripts\robot.exe --dryrun PLG-00-main.robot
```

## 📊 Teljesítmény

### Feldolgozási sebesség
- **Kis fájl** (<1MB): ~10-15 másodperc
- **Közepes fájl** (1-5MB): ~30-60 másodperc
- **Nagy fájl** (>5MB): ~2-5 perc

### Skálázhatóság
- **Batch méret**: 50+ fájl egyidejűleg
- **Adatbázis**: 10,000+ dokumentum
- **Hash tábla**: 1M+ bejegyzés

## 🐛 Hibaelhárítás

### Gyakori problémák

#### 📧 Email küldési hiba
```powershell
# Outlook újraindítás
taskkill /F /IM outlook.exe
start outlook.exe
```

#### 📄 DOCX olvasási hiba  
```powershell
# Fájl integritás ellenőrzés
Get-FileHash dokumentum.docx
```

#### 🗄️ Adatbázis lock
```powershell
# Folyamatok leállítása
taskkill /F /IM python.exe
```

### Debug mód
```ini
# Plagium.config
debug_mode=true
```

## 📖 Dokumentáció

- 📋 **[Teljes dokumentáció](DOKUMENTACIO.md)**: Részletes technikai leírás
- ⚡ **[Gyors referencia](GYORS_REFERENCIA.md)**: 5 perces útmutató  
- 🔧 **[Technikai áttekintés](TECHNIKAI_ATTEKINTES.md)**: Fejlesztői információk
- 📞 **[Telepítési útmutató](TELEPITO_UTMUTATO.txt)**: Lépésről lépésre

## 🤝 Közreműködés

### Pull Request folyamat
1. Fork-old a repository-t
2. Hozz létre feature branch-et (`git checkout -b feature/amazing-feature`)
3. Commitold a változásokat (`git commit -m 'Add amazing feature'`)
4. Push-old a branch-et (`git push origin feature/amazing-feature`)
5. Nyiss Pull Request-et

### Fejlesztői irányelvek
- **Python**: PEP 8 kódstílus
- **Robot Framework**: Hivatalos style guide
- **Commit üzenetek**: Conventional Commits formátum
- **Tesztelés**: Minden új funkcióhoz unit teszt

## 🏷️ Changelog

### v2.1.0 (2025-08-25)
- ✅ **ÚJ**: Háromszintű email küldési rendszer
- ✅ **JAVÍTÁS**: Windows path escape karakterek  
- ✅ **OPTIMALIZÁLÁS**: Libraries könyvtár refaktoring
- ✅ **FEJLESZTÉS**: Tisztított logging rendszer

### v2.0.0 (2025-08-20)
- ✅ **ÚJ**: Outlook COM automatikus email
- ✅ **ÚJ**: Excel export funkció
- ✅ **JAVÍTÁS**: SQLite optimalizálás

## 📄 Licenc

Ez a projekt [MIT](LICENSE) licenc alatt áll. Lásd a `LICENSE` fájlt a részletekért.

## 📞 Támogatás

- 📧 **Email**: support@plagium-checker.com
- 💬 **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- 📖 **Wiki**: [Projekt Wiki](https://github.com/your-repo/wiki)

## 🙏 Köszönetnyilvánítás

- **Robot Framework** csapat a fantasztikus automatizálási keretrendszerért
- **Python-docx** fejlesztők a DOCX támogatásért  
- **OpenPyXL** közösség az Excel integrációért
- **Microsoft** a Outlook COM API-ért

---

**⭐ Ha hasznos volt a projekt, adj egy csillagot a GitHub-on!**

*🤖 Robot Framework Plágium Ellenőrző v2.1.0*  
*📅 Utolsó frissítés: 2025. augusztus 25.*
=======
# DuplikacioEllenorzesRobot
>>>>>>> 9f61c4cc3353cf12378925c1e049202b997d4f71
