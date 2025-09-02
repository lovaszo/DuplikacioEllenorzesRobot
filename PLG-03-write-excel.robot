*** Settings ***
Resource    resources/keywords.robot
Resource    resources/variables.robot
Library     DatabaseLibrary
Library     Collections
Library     DateTime
Library     OperatingSystem
Library     Process

*** Variables ***
${python_script}    ${CURDIR}/libraries/excel_export.py

*** Test Cases ***
Excel Export Teszt
    [Documentation]    Redundancia tábla exportálása Excel formátumban
    Excel Export Redundancia Tábla

*** Keywords ***
Excel Export Redundancia Tábla
    [Documentation]    Excel export a meglévő Python script használatával
    
    Log To Console    \n═════════════════════════════════
    Log To Console    📊 EXCEL EXPORT KEZDÉSE
    Log To Console    ═══════════════════════════════
    
    ${python_path}=    Set Variable    ${EXECDIR}/rf_env/Scripts/python.exe
    ${result}=    Run Process    ${python_path}    libraries/excel_export_simple.py    shell=True    cwd=${EXECDIR}
    
    IF    ${result.rc} == 0
        Log To Console    ✅ Excel export sikeres!
        Log To Console    ${result.stdout}
    ELSE
        Log To Console    ❌ Excel export hiba!
        Log To Console    ${result.stderr}
        Fail    Excel export sikertelen: ${result.stderr}
    END

