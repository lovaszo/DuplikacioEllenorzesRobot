*** Settings ***
Library    ../libraries/DocxReader.py
Library    ../libraries/find_docx.py
Library    DatabaseLibrary
Library    DateTime
Library    Process
Resource   variables.robot
Resource   ../PLG-02-read_docx.robot
Resource   get_file_size.resource


*** Keywords ***

Get Config Icon
    [Documentation]    Ikonok tiltva: mindig üres string
    [Arguments]    ${icon_name}
    RETURN    ${EMPTY}

Konfiguráció Betöltése
    [Documentation]    Plagium.config fajl betoltese es beallitasok alkalmazasa
    
    ${config_icon}=    Get Config Icon    config
    Log To Console    ${config_icon} KONFIGURACIO BETOLTESE...
    Log To Console    ═══════════════════════════════
    
    # Konfiguracios fajl olvasasa Python scripttel
    ${config_result}=    Run Process    python    libraries/get_config.py    shell=True
    
    IF    ${config_result.rc} == 0
    ${config_line}=    Set Variable    ${config_result.stdout.strip()}
    # Log To Console    [DEBUG] config_line: ${config_line}
    @{config_parts}=    Split String    ${config_line}    |
    # Index safety: Only extract parts if enough elements exist
    ${parts_len}=    Get Length    ${config_parts}
        IF    ${parts_len} < 7
            Fail    Konfigurációs sor hibás vagy hiányos: ${config_line}
        END
    ${email_part}=    Get From List    ${config_parts}    0
    ${input_part}=    Get From List    ${config_parts}    1
    ${output_part}=    Get From List    ${config_parts}    2
    ${subject_part}=    Get From List    ${config_parts}    3
    ${prefix_part}=    Get From List    ${config_parts}    4
    ${threshold_gyanus_part}=    Get From List    ${config_parts}    5
    ${threshold_masolt_part}=    Get From List    ${config_parts}    6
        
        ${config_email}=    Remove String    ${email_part}    EMAIL:
        ${config_input}=    Remove String    ${input_part}    INPUT:
        ${config_output}=    Remove String    ${output_part}    OUTPUT:
        ${config_subject}=    Remove String    ${subject_part}    SUBJECT:
        ${config_prefix}=    Remove String    ${prefix_part}    PREFIX:
        ${config_threshold_gyanus}=    Remove String    ${threshold_gyanus_part}    THRESHOLD_GYANUS:
        ${config_threshold_masolt}=    Remove String    ${threshold_masolt_part}    THRESHOLD_MASOLT:
        
        # Globalis valtozok beallitasa
        Set Global Variable    ${CONFIG_EMAIL}         ${config_email}
        Set Global Variable    ${CONFIG_INPUT_FOLDER}  ${config_input}
        Set Global Variable    ${CONFIG_OUTPUT_FOLDER}    ${config_output}
        Set Global Variable    ${CONFIG_EMAIL_SUBJECT}    ${config_subject}
        Set Global Variable    ${CONFIG_EXCEL_PREFIX}     ${config_prefix}
        Set Global Variable    ${CONFIG_THRESHOLD_GYANUS}    ${config_threshold_gyanus}
        Set Global Variable    ${CONFIG_THRESHOLD_MASOLT}    ${config_threshold_masolt}
        Set Global Variable    ${DOCUMENT_PATH}           ${config_input}
    # Az adatbázis elérési útját ténylegesen kiértékeljük Pythonból
    ${abs_lib_path}=    Evaluate    __import__('os').path.abspath('libraries')    modules=os
    ${py_cmd}=    Set Variable    import sys; sys.path.insert(0, r'${abs_lib_path}'); from duplikacio_config import DuplikacioConfig; print(DuplikacioConfig().get_database_file())
    ${db_path_result}=    Run Process    python    -c    ${py_cmd}    shell=True
    #Log To Console    [DEBUG] db_path_result.stdout: ${db_path_result.stdout}
    @{db_path_lines}=    Split To Lines    ${db_path_result.stdout}
    ${db_path}=    Get From List    ${db_path_lines}    -1
    Set Global Variable    ${SQLITE_DB_FILE}    ${db_path.strip()}
        
        # Sikeres konfiguráció betöltése - ikonokkal
        ${check_icon}=    Get Config Icon    check
        ${email_icon}=    Get Config Icon    email
        ${folder_in_icon}=    Get Config Icon    folder_in
        ${folder_out_icon}=    Get Config Icon    folder_out
        ${subject_icon}=    Get Config Icon    subject
        # ${script_path} assignment removed; handled in Excel Export Redundancia Tábla
        
        Log To Console    ${check_icon} Konfiguracio sikeresen betoltve!
        Log To Console    ${email_icon} Email: ${config_email}
        Log To Console    ${folder_in_icon} Bementi konyvtar: ${config_input}
        Log To Console    ${folder_out_icon} Kimeneti konyvtar: ${config_output}
        Log To Console    ${subject_icon} Email targy: ${config_subject}
        Log To Console    Excel prefix: ${config_prefix}
    ELSE
        ${warning_icon}=    Get Config Icon    warning
        Log To Console    ${warning_icon}  Hiba a konfiguracio betoltesekor, alapertelmezettek hasznalata
        Log To Console    Hibauenet: ${config_result.stderr}
    END
    
    Log To Console    ═══════════════════════════════


Beolvasom A DOCX Fájlt
    ${szoveg}=    Read Docx    ${DOCX_FILE}
    ${is_error}=    Run Keyword And Return Status    Should Start With    ${szoveg}    [HIBA]
    RETURN    ${szoveg}

Kapcsolodas Az Adatbazishoz
    [Documentation]    SQLite adatbázishoz kapcsolódás
    # Mindig bontsunk előző kapcsolatot, hogy ne legyen "Overwriting not closed connection" warning
    Run Keyword And Ignore Error    Disconnect From Database
    IF    '${DB_MODULE}' == 'sqlite3'
        Connect To Database    sqlite3    ${DB_NAME}
        Log To Console    Sikeres kapcsolódás az SQLite adatbázishoz: ${DB_NAME}
    ELSE IF    '${DB_MODULE}' == 'pyodbc'
        ${connection_string}=    Set Variable    DRIVER={SQL Server};SERVER=${DB_HOST};DATABASE=${DB_NAME};UID=${DB_USERNAME};PWD=${DB_PASSWORD};
        Log To Console    ODBC Connection string: ${connection_string}
        Connect To Database    pyodbc    ${connection_string}
        Log To Console    Sikeres kapcsolódás az MSSQL adatbázishoz
    ELSE
        Connect To Database    ${DB_MODULE}    ${DB_NAME}    ${DB_USERNAME}    ${DB_PASSWORD}    ${DB_HOST}    ${DB_PORT}
        Log To Console    Sikeres kapcsolódás az adatbázishoz
    END

Adatbazis Kapcsolat Bezarasa
    [Documentation]    Adatbázis kapcsolat bezárása
    Run Keyword And Ignore Error    Disconnect From Database
    Log To Console    Adatbázis kapcsolat bezárva

Hash táblák ellenőrzése

    [Documentation]    Egyszerű SQLite adatbázis teszt amely ténylegesen működik
    [Tags]    database    sqlite    working
    
    # Régi adatbázis törlése ha létezik
    #${file_exists}=    Run Keyword And Return Status    File Should Exist    ${SQLITE_DB_FILE}
    #Run Keyword If    ${file_exists}    Remove File    ${SQLITE_DB_FILE}
    
    # redundancia tábla létrehozása ha nem létezik (elsőként, mivel ez lesz a fő tábla)
    Execute Sql String    CREATE TABLE IF NOT EXISTS redundancia (id INTEGER PRIMARY KEY AUTOINCREMENT, status TEXT DEFAULT 'Rendben', file_path TEXT, file_name TEXT NOT NULL, file_size INTEGER NOT NULL, line_number INTEGER DEFAULT 0, repeat_block_nbr INTEGER DEFAULT 0, max_ismetlesek_szama INTEGER DEFAULT 0, max_ismetelt_karakterszam INTEGER DEFAULT 0, overview TEXT DEFAULT '', record_date TEXT NOT NULL, record_time TEXT NOT NULL)
    Execute Sql String    CREATE INDEX IF NOT EXISTS idx_redundancia_id ON redundancia(id)
        Execute Sql String    CREATE INDEX IF NOT EXISTS idx_redundancia_file ON redundancia(file_name, file_path)
    
    # hashCodes tábla létrehozása ha nem létezik foreign key kapcsolattal és külön file_name, file_path oszlopokkal (document_name nélkül)
    Execute Sql String    CREATE TABLE IF NOT EXISTS hashCodes (hash_value TEXT(100) PRIMARY KEY, file_path TEXT NOT NULL, file_name TEXT NOT NULL, created_date TEXT NOT NULL, created_time TEXT NOT NULL, line_content TEXT, redundancia_id INTEGER, FOREIGN KEY (redundancia_id) REFERENCES redundancia(id))
        Execute Sql String    CREATE INDEX IF NOT EXISTS idx_hashCodes_file ON hashCodes(file_name, file_path)
    
    # repeat tábla létrehozása ha nem létezik - az ismételt sorok tárolására
    Execute Sql String    CREATE TABLE IF NOT EXISTS repeat (id INTEGER PRIMARY KEY AUTOINCREMENT, file_name TEXT NOT NULL, file_path TEXT NOT NULL, source_file_path TEXT, source_file_name TEXT NOT NULL, redundancia_id INTEGER, repeat_block_nbr INTEGER DEFAULT 0, block_id INTEGER NOT NULL, line_length INTEGER NOT NULL, sum_line_length INTEGER DEFAULT 0, repeated_line TEXT NOT NULL, token TEXT, created_date TEXT NOT NULL, created_time TEXT NOT NULL, FOREIGN KEY (redundancia_id) REFERENCES redundancia(id))
        Execute Sql String    CREATE INDEX IF NOT EXISTS idx_repeat_file ON repeat(file_name, file_path)
    Execute Sql String    CREATE INDEX IF NOT EXISTS idx_repeat_redundancia_id ON repeat(redundancia_id)
    Execute Sql String    CREATE INDEX IF NOT EXISTS idx_repeat_block_id ON repeat(block_id)
    Execute Sql String    CREATE INDEX IF NOT EXISTS idx_repeat_id ON repeat(id)
    
    # A táblák és oszlopok meglétét nem ellenőrizzük, ha hiányzik valamelyik, a folyamat hibára fut.
    
    # Új felhasználó hozzáadása
    #Execute Sql String    INSERT INTO users (username, email) VALUES ('newuser', 'newuser@example.com')
    
    # Ellenőrzés az új felhasználó után
    #${all_users}=    Query    SELECT * FROM users
    #${final_count}=    Get Length    ${all_users}
    #Should Be Equal As Integers    ${final_count}    4
    #Log To Console    \nVégső felhasználók száma: ${final_count}
    
   



Lekerem A Felhasznalokat
    [Documentation]    Összes felhasználó lekérése a users táblából
    ${result}=    Query    SELECT id, username, email, created_date FROM users ORDER BY id
    Log To Console    Lekért felhasználók száma: ${result.__len__()}
    FOR    ${row}    IN    @{result}
        Log To Console    ID: ${row[0]}, Felhasználónév: ${row[1]}, Email: ${row[2]}, Létrehozva: ${row[3]}
    END
    RETURN    ${result}

Lekerem A Felhasznalot ID Alapjan
    [Documentation]    Egy felhasználó lekérése ID alapján
    [Arguments]    ${user_id}
    ${result}=    Query    SELECT id, username, email, created_date FROM users WHERE id = ${user_id}
    Log To Console    Lekért felhasználó adatai:
    FOR    ${row}    IN    @{result}
        Log To Console    ID: ${row[0]}, Felhasználónév: ${row[1]}, Email: ${row[2]}, Létrehozva: ${row[3]}
    END
    RETURN    ${result}

Ellenorzom Az Adatbazist
    [Documentation]    Adatbázis állapot ellenőrzése
    ${row_count}=    Row Count    SELECT COUNT(*) FROM users
    Log To Console    Felhasználók száma az adatbázisban: ${row_count}
    Should Be True    ${row_count} >= 0
    RETURN    ${row_count}

Adatbazis Inicializalasa
    [Documentation]    SQLite adatbázis inicializálása táblákkal és teszt adatokkal
    # Users tábla létrehozása ha nem létezik
    Execute Sql String     IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, email TEXT NOT NULL, created_date TEXT DEFAULT CURRENT_TIMESTAMP)
    
    # Ellenőrizzük, hogy vannak-e már adatok
    ${count}=    Row Count    SELECT COUNT(*) FROM users
    IF    ${count} == 0
        # Teszt adatok beszúrása
        Execute Sql String    INSERT INTO users (username, email) VALUES ('admin', 'admin@example.com')
        Execute Sql String    INSERT INTO users (username, email) VALUES ('testuser1', 'testuser1@example.com')
        Execute Sql String    INSERT INTO users (username, email) VALUES ('developer', 'developer@example.com')
        Execute Sql String    INSERT INTO users (username, email) VALUES ('analyst', 'analyst@example.com')
        Execute Sql String    INSERT INTO users (username, email) VALUES ('manager', 'manager@example.com')
        Log To Console    SQLite adatbázis inicializálva 5 teszt felhasználóval
    ELSE
        Log To Console    SQLite adatbázisban már vannak adatok (${count} felhasználó)
    END

Fájladatok Feldolgozása Redundancia Táblába
    [Documentation]    Aktuális DOCX fájl adatainak feldolgozása a redundancia táblába
    [Arguments]    ${file_path}    ${is_error}    ${hibaszoveg}
    
    # Fájl méret lekérése
    ${file_size}=    Get File Size    ${file_path}
    
    # Előző rekord törlése a redundancia táblából az aktuális fájlhoz
    ${file_name}=    Evaluate    os.path.basename(r"${file_path}")    modules=os
    ${file_path_only}=    Evaluate    os.path.dirname(r"${file_path}")    modules=os
    Execute Sql String    DELETE FROM redundancia WHERE file_name = '${file_name}' AND file_path = '${file_path_only}'
    # Fájl név kivonása a teljes útvonalból (Windows útvonal escape karakterek kezelése)
    
    # Aktuális dátum és idő lekérése
    ${current_date}=    Get Current Date    result_format=%Y-%m-%d
    ${current_time}=    Get Current Date    result_format=%H:%M:%S
    
    # Ha hibás a DOCX, akkor a status legyen 'Hibás', különben 'Rendben'
    ${status}=    Set Variable If    ${is_error}    Hibás    Rendben
    ${status_str}=    Convert To String    ${status}
    # Az overview kiszámítása
    # Ha hibás, overview a hibaszöveg, különben a progress string (overview_string)
    ${overview_string}=    Get Variable Value    ${overview_string}    ''
    ${overview}=    Set Variable    ''

    # SQL beszúrás redundancia táblába
    Execute Sql String    INSERT INTO redundancia (status, file_path, file_name, file_size, record_date, record_time, overview) VALUES ('${status_str}', '${file_path_only}', '${file_name}', ${file_size}, '${current_date}', '${current_time}', '${overview}')
    ${redundancia_id_result}=    Query    SELECT last_insert_rowid()
    ${redundancia_id}=    Set Variable    ${redundancia_id_result[0][0]}
    Set Global Variable    ${REDUNDANCIA_ID}    ${redundancia_id}
    
    Log To Console    Redundancia ID: ${redundancia_id}
    Log To Console    Fájl neve: ${file_name}
    Log To Console    Fájl méret: ${file_size} byte
    Log To Console    Feldolgozás ideje: ${current_time}
    # Sorok számának kiírása
    ${szoveg}=    Beolvasom A DOCX Fájlt
    @{sorok}=    Split String    ${szoveg}    \n
    ${ossz_sor}=    Get Length    ${sorok}
    Log To Console    Sorok száma: ${ossz_sor}
    
    RETURN    ${redundancia_id}




Batch DOCX ellenőrzés
    [Documentation]    Batch feldolgozás összes DOCX fájlra a DOCUMENT_PATH útvonalon
    
    # DOCX fájlok keresése a megadott útvonalon
    @{docx_files}=    Find Docx Files Recursively    ${DOCUMENT_PATH}
    
    # Ellenőrzés, hogy van-e DOCX fájl
    ${file_count}=    Get Length    ${docx_files}
    Set Global Variable    ${file_count}
    Log To Console    \n=== DOCX FÁJLOK KERESÉSE ===
    Log To Console    Keresési útvonal: ${DOCUMENT_PATH}
    Log To Console    Talált DOCX fájlok száma: ${file_count}

    
    IF    ${file_count} == 0
        Log To Console    FIGYELMEZTETÉS: Nem találhatók DOCX fájlok a megadott útvonalon!
        RETURN
    END
    
    # Hibalista inicializálása
    ${HIBA_LISTA}=    Create List
    Set Global Variable    ${HIBA_LISTA}

    # Végigmegy az összes talált DOCX fájlon
    ${current_index}=    Set Variable    1
    FOR    ${docx_file}    IN    @{docx_files}
    Log To Console    \n>>> FELDOLGOZÁS: (${current_index}/${file_count}) ${docx_file}
        ${current_index}=    Evaluate    ${current_index} + 1
        # Beállítja az aktuális DOCX fájlt változóban
        Set Global Variable    ${DOCX_FILE}    ${docx_file}
        # DOCX beolvasás és hibastátusz lekérdezése
    ${szoveg}=    Beolvasom A DOCX Fájlt
    ${is_error}=    Run Keyword And Return Status    Should Start With    ${szoveg}    [HIBA]
    # Ha üres vagy None a szöveg, az is hiba
    ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${szoveg}
    ${is_none}=    Run Keyword And Return Status    Should Be Equal    ${szoveg}    None
    ${is_error}=    Evaluate    ${is_error} or ${is_empty} or ${is_none}
    Run Keyword If    ${is_error}    Log To Console    [DEBUG] szoveg: ${szoveg}
    Run Keyword If    ${is_error}    Log To Console    [DEBUG] is_error: ${is_error}
    # Hibalistába fájlnév+hibaszöveg, de a feldolgozó kulcsszónak csak a file_path
    ${hiba_entry}=    Set Variable    ${docx_file}: ${szoveg}
    Run Keyword If    ${is_error}    Append To List    ${HIBA_LISTA}    ${hiba_entry}
    # Először redundancia rekordot beszúrjuk, majd átadjuk az ID-t a DOCX feldolgozásnak
    ${redundancia_id}=    Fájladatok Feldolgozása Redundancia Táblába    ${docx_file}    ${is_error}    ${szoveg}
    ${tul_rovid_szamlalo}=    Run Keyword If    '${redundancia_id}' != ''    DOCX Beolvasás Teszt    ${docx_file}    ${redundancia_id}
    ${overview_string}=    Get Variable Value    ${overview_string}    ''
    Log To Console    \n<<< BEFEJEZVE: ${docx_file}
    Log To Console    Túl rövid mondatok: ${tul_rovid_szamlalo}
    END

    # Hibalista kiírása a végén
    Run Keyword If    ${HIBA_LISTA}    Log To Console    \n=== HIBÁS DOCX FÁJLOK ===
    FOR    ${hiba}    IN    @{HIBA_LISTA}
        Log To Console    ${hiba}
    END

    Log To Console    === ÖSSZESÍTÉS ===
    Log To Console    \nFeldolgozott dokumentumok száma: ${file_count}

Redundancia Eredmények Ellenőrzése
    [Documentation]    Redundancia tábla status oszlopának részletes ellenőrzése
    
    # Minden futás előtt a redundancia tábla biztosítása
    Hash táblák ellenőrzése
    ${search_icon}=    Get Config Icon    search
    Log To Console    REDUNDANCIA EREDMÉNYEK ELEMZÉSE
    Log To Console    \n═══════════════════════════════════════
    Log To Console    Használt adatbázisfájl: ${SQLITE_DB_FILE}
    
    # Kapcsolódás előtt mindig bontsuk az előző kapcsolatot, hogy ne legyen warning
    Run Keyword And Ignore Error    Disconnect From Database
    Run Keyword And Ignore Error    Connect To Database    sqlite3    ${SQLITE_DB_FILE}
    
    # Redundancia tábla struktúrájának ellenőrzése
    #@{schema}=    Query    PRAGMA table_info(redundancia)
    #Log To Console    \n📊 REDUNDANCIA TÁBLA STRUKTÚRÁJA:
    #FOR    ${column}    IN    @{schema}
    #    ${col_name}=    Get From List    ${column}    1
    #    ${col_type}=    Get From List    ${column}    2
    #    ${default_val}=    Get From List    ${column}    4
    #    Log To Console    • ${col_name} - ${col_type} (alapértelmezett: ${default_val})
    #END
    
    # Jelenlegi redundancia adatok megjelenítése
    #@{redundancia_data}=    Query    SELECT id, file_name, file_size, max_ismetlesek_szama, max_ismetelt_karakterszam, status FROM redundancia ORDER BY max_ismetelt_karakterszam DESC
    
    #Log To Console    \n📋 REDUNDANCIA REKORDOK STATUSSZAL:
    #FOR    ${record}    IN    @{redundancia_data}
    #    ${id}=    Get From List    ${record}    0
    #    ${file_name}=    Get From List    ${record}    1
    #    ${file_size}=    Get From List    ${record}    2
    #    ${max_ismetlesek}=    Get From List    ${record}    3
    #    ${max_karakterszam}=    Get From List    ${record}    4
    #    ${status}=    Get From List    ${record}    5
        
    #    Log To Console    ID: ${id} | Fájl: ${file_name} | Méret: ${file_size} bytes
    #    Log To Console    Max ismétlések: ${max_ismetlesek} | Max karakterszám: ${max_karakterszam}
    #    Log To Console    ➤ STATUS: ${status}
    #    Log To Console    ---
    #END
    
    # Status kategóriák statisztikája részletesen
    @{status_stats}=    Query    SELECT status, COUNT(*) as count, MIN(max_ismetelt_karakterszam) as min_chars, MAX(max_ismetelt_karakterszam) as max_chars FROM redundancia GROUP BY status ORDER BY min_chars
    
    ${chart_icon}=    Get Config Icon    chart
    Log To Console    \n${chart_icon} STATUS KATEGÓRIÁK RÉSZLETES STATISZTIKÁJA:
    FOR    ${stat}    IN    @{status_stats}
        ${status}=    Get From List    ${stat}    0
        ${count}=    Get From List    ${stat}    1
        ${min_chars}=    Get From List    ${stat}    2
        ${max_chars}=    Get From List    ${stat}    3
        Log To Console    ${status}: ${count} dokumentum (${min_chars}-${max_chars} karakter)
    END
    
    # Status kategóriák szabályainak ellenőrzése
    ${target_icon}=    Get Config Icon    target
    ${green_icon}=    Get Config Icon    green
    ${yellow_icon}=    Get Config Icon    yellow
    ${red_icon}=    Get Config Icon    red
    
    Log To Console    \n${target_icon} STATUS KATEGÓRIÁK SZABÁLYAI:
    Log To Console    ${green_icon} Rendben: max_ismetelt_karakterszam < 300
    Log To Console    ${yellow_icon} Gyanús: ${CONFIG_THRESHOLD_GYANUS} ≤ max_ismetelt_karakterszam < ${CONFIG_THRESHOLD_MASOLT}  
    Log To Console    ${red_icon} Másolt: max_ismetelt_karakterszam ≥ ${CONFIG_THRESHOLD_MASOLT}
    
    # Összesítő statisztikák
    @{total_stats}=    Query    SELECT COUNT(*) as total_docs, SUM(CASE WHEN status = 'Rendben' THEN 1 ELSE 0 END) as clean_docs, SUM(CASE WHEN status = 'Gyanús' THEN 1 ELSE 0 END) as suspicious_docs, SUM(CASE WHEN status = 'Másolt' THEN 1 ELSE 0 END) as copied_docs FROM redundancia
    ${total}=    Get From List    ${total_stats[0]}    0
    ${clean}=    Get From List    ${total_stats[0]}    1
    ${suspicious}=    Get From List    ${total_stats[0]}    2
    ${copied}=    Get From List    ${total_stats[0]}    3
    
    ${trophy_icon}=    Get Config Icon    trophy
    
    Log To Console    \n${trophy_icon} VÉGSŐ ÖSSZESÍTÉS:
    Log To Console    ═══════════════════════
    Log To Console    Összes dokumentum: ${total}
    Log To Console    ${green_icon} Rendben: ${clean} dokumentum
    Log To Console    ${yellow_icon} Gyanús: ${suspicious} dokumentum
    Log To Console    ${red_icon} Másolt: ${copied} dokumentum
    
    # Százalékos arányok
    IF    ${total} > 0
        ${clean_percent}=    Evaluate    round((${clean} / ${total}) * 100, 1)
        ${suspicious_percent}=    Evaluate    round((${suspicious} / ${total}) * 100, 1)
        ${copied_percent}=    Evaluate    round((${copied} / ${total}) * 100, 1)
        
        Log To Console    \nSZÁZALÉKOS MEGOSZLÁS:
        Log To Console    ${green_icon} Rendben: ${clean_percent}%
        Log To Console    ${yellow_icon} Gyanús: ${suspicious_percent}%
        Log To Console    ${red_icon} Másolt: ${copied_percent}%
    END
    
    
    ${check_icon}=    Get Config Icon    check
    Log To Console    \n${check_icon} EREDMÉNYEK ELLENŐRZÉSE BEFEJEZVE!
    Log To Console    \n═══════════════════════════════════════

Excel Export Redundancia Tábla
    [Documentation]    Redundancia tábla tartalmának exportálása Excel fájlba a PLG-03-write-excel.robot használatával
    
    # Export előtt minden nyitott kapcsolatot lezárunk
    # Export előtt minden nyitott kapcsolatot lezárunk
    Disconnect From Database
    # Export előtt újra kapcsolódunk az adatbázishoz, hogy legyen aktív kapcsolat
    Connect To Database    sqlite3    ${SQLITE_DB_FILE}
    ${excel_icon}=    Get Config Icon    excel
    Log To Console    \n${excel_icon} EXCEL EXPORT KEZDÉSE
    Log To Console    ═══════════════════════════════
    # Adatbázis táblák inicializálása, ha hiányoznak
    Hash táblák ellenőrzése
    
    # Excel export Python script futtatása a virtuális környezetből
    ${python_path}=    Set Variable    ${PYTHON_EXEC}
    ${result}=    Run Process    ${python_path}    libraries/excel_export_simple.py    shell=False    cwd=${EXECDIR}    stdout=STDOUT    stderr=STDERR
    IF    ${result.rc} == 0
        ${check_icon}=    Get Config Icon    check
        Log To Console    ${check_icon} Excel export sikeres!
        Log To Console    ${result.stdout}
    ELSE
        ${cross_icon}=    Get Config Icon    cross
        ${warning_icon}=    Get Config Icon    warning
        Log To Console    ${cross_icon} Excel export hiba!
        Log To Console    ${result.stderr}
        Log To Console    ${warning_icon} Excel export sikertelen, de a folyamat folytatódik...
    END

Email Küldés Eredményekkel
    [Documentation]    Email küldése a plágium ellenőrzés eredményeivel (több próbálkozással)
    
    # Első próbálkozás
    # ${result1}=    Run Process    ${PYTHON_EXEC}    libraries/send_email.py    shell=True    cwd=${CURDIR}/..    timeout=60s
    
    IF    $result1.stderr != ""
        Log To Console    Email hibák (1): ${result1.stderr}
    END
    
    IF    ${result1.rc} == 0
        Log To Console    🎯 PLAGIUM ELLENORZÉS TELJES FOLYAMATA BEFEJEZVE! ✅
    ELSE
        Log To Console    ⚠️ Első próbálkozás sikertelen, várakozás 5 másodperc...
        Sleep    5s
        
        # Második próbálkozás
    # ${result2}=    Run Process    ${PYTHON_EXEC}    libraries/send_email.py    shell=True    cwd=${CURDIR}/..    timeout=60s
        
        IF    $result2.stderr != ""
            Log To Console    Email hibák (2): ${result2.stderr}
        END
        
        IF    ${result2.rc} == 0
            Log To Console    🎯 PLAGIUM ELLENORZÉS TELJES FOLYAMATA BEFEJEZVE! ✅
        ELSE
            Log To Console    ⚠️ Második próbálkozás sikertelen, várakozás 10 másodperc...
            Sleep    10s
            
            # Harmadik (utolsó) próbálkozás
            # ${result3}=    Run Process    ${PYTHON_EXEC}    libraries/send_email.py    shell=True    cwd=${CURDIR}/..    timeout=90s
            
            IF    $result3.stderr != ""
                Log To Console    Email hibák (3): ${result3.stderr}
            END
            
            IF    ${result3.rc} == 0
                Log To Console    🎯 PLAGIUM ELLENORZÉS TELJES FOLYAMATA BEFEJEZVE! ✅
            ELSE
                Log To Console    ❌ Minden email küldési próbálkozás sikertelen!
                Log To Console    Hibakód: ${result3.rc}
                Log To Console    ⚠️ PLAGIUM ELLENORZÉS BEFEJEZVE - EMAIL PROBLÉMÁVAL!
            END
        END
    END

