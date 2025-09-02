*** Variables ***
${DOCX_FILE}        Test.docx
#${DOCX_FILE}       EM-2.1.7_RRF221_tema_kezirata.docx
${DOCUMENT_PATH}    ./test  # Ezt a konfiguracios fajlbol toltjuk be
${szoveg}           NONE
${kisbetus}         NONE
@{hashValues}    
@{sorok}

# Python executable változó (Robot Framework környezetben)
${PYTHON_EXEC}      python.exe

# Konfiguracios fajl beallitasai - ezeket a duplikacio_config.py tölti be
${CONFIG_EMAIL}         lovasz.otto@clarity.hu
${CONFIG_INPUT_FOLDER}  d:\\tmp
${CONFIG_OUTPUT_FOLDER}    d:\\tmp
${CONFIG_EMAIL_SUBJECT}    Duplikacio Ellenorzes - Eredmenyek
${CONFIG_EXCEL_PREFIX}  duplikacio_eredmenyek

# SQLite Database Connection Variables
${DB_MODULE}        sqlite3
${DB_HOST}          test_database.db
${DB_NAME}          ${EMPTY}
${DB_USERNAME}      
${DB_PASSWORD}      
${DB_PORT}  

${SQLITE_DB_FILE}    ${EMPTY}

# Dinamikus adatbázis elérési út betöltése a Python configból
${DB_PATH_FROM_CONFIG}=    Evaluate    __import__('libraries.duplikacio_config').DuplikacioConfig().get_database_file()    modules=libraries.duplikacio_config
