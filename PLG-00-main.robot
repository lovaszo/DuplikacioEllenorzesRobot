*** Settings ***
Resource    resources/keywords.robot
Resource    resources/variables.robot
Resource    PLG-02-read_docx.robot   
Library     DatabaseLibrary
Library     String
Library     BuiltIn
Library     Collections
Library     OperatingSystem
Library     Process

*** Variables ***

*** Test Cases ***

Redundancia ellenőrzése
    [Documentation]    Dokumentumokban ismétlődések keresése
    ${start_time}=    Get Time    epoch

    # Konfiguracio betöltése minden futás elején
    Konfiguráció Betöltése

    # Kapcsolódás SQLite adatbázishoz (létrehozza ha nem létezik)
    Connect To Database    sqlite3    ${SQLITE_DB_FILE}

    # Táblák meglétének ellenőrzése, ha nincs, akkor létrehozás
    Hash táblák ellenőrzése

    #Docx beolvasása és feldolgozása
    Batch DOCX ellenőrzés

    # Eredmények automatikus ellenőrzése
    Log To Console    DUPLUM ELLENŐRZÉS BEFEJEZVE - EREDMÉNYEK ELEMZÉSE INDUL...
    Log To Console    \n════════════════════════════════════════════════════════════════
    Run Keyword And Continue On Failure    Redundancia Eredmények Ellenőrzése

    # Excel export automatikus futtatása
    #Log To Console    EXCEL EXPORT INDÍTÁSA...
    #Log To Console    \n════════════════════════════════
    # Feldolgozott dokumentumok számának és futásidőnek kiírása
    ${file_count}=    Get Variable Value    ${file_count}    0
    ${end_time}=    Get Time    epoch
    ${elapsed}=    Evaluate    int(${end_time} - ${start_time})
    ${hours}=    Evaluate    ${elapsed} // 3600
    ${minutes}=    Evaluate    (${elapsed} % 3600) // 60
    ${seconds}=    Evaluate    ${elapsed} % 60

    # Excel export a legvégén, minden adatbázis-művelet után
    Sleep    2s
    Run Keyword And Continue On Failure    Excel Export Redundancia Tábla

    # Kapcsolat bezárása a legvégén
    Disconnect From Database

        # Run Keyword And Continue On Failure    Email Küldés Eredményekkel
    ${file_count}=    Get Variable Value    ${file_count}    0
    ${end_time}=    Get Time    epoch
    ${elapsed}=    Evaluate    int(${end_time} - ${start_time})
    ${hours}=    Evaluate    ${elapsed} // 3600
    ${minutes}=    Evaluate    (${elapsed} % 3600) // 60
    ${seconds}=    Evaluate    ${elapsed} % 60
    
    Log To Console    \nTELJES FELDOLGOZÁS KÉSZ!
    Log To Console    \n════════════════════════════════
    Log To Console    \nFeldolgozott dokumentumok száma: ${file_count}
    Log To Console    \nFutás teljes ideje: ${hours} óra ${minutes} perc ${seconds} másodperc
