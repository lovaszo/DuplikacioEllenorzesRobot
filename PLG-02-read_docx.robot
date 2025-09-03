*** Settings ***
Resource    resources/keywords.robot
Resource    resources/variables.robot
Library     String
Library     BuiltIn
Library     Collections

*** Keywords ***
DOCX Beolvasás Teszt
    [Arguments]    ${file_path}    ${redundancia_id}
    # Redundancia ID beállítása globális változóként
    Set Global Variable    ${REDUNDANCIA_ID}    ${redundancia_id}
    Set Global Variable    ${DOCX_FILE}    ${file_path}
    [Documentation]    DOCX fájl feldolgozása hash-eléssel és plagiarízmus ellenőrzéssel.
    ...                10 karakternél rövidebb sorokat kihagyja a feldolgozásból.
    ${szoveg}=    Beolvasom A DOCX Fájlt
    # Ha üres a szöveg vagy tartalmazza a [HIBA] szöveget, azonnal visszatérés
    #otto was here
    #Log To Console     ${szoveg}

    IF    "[HIBA]" in $szoveg
        Execute Sql String    UPDATE redundancia SET status = 'Hibás', overview = '${szoveg}' WHERE id = ${REDUNDANCIA_ID}
        # Max értékek, status és overview mező update-je egyetlen SQL-ben, a végleges értékekkel
        Set Global Variable    ${max_duplikacio_szamlaló}
        Set Global Variable    ${max_ismetelt_karakterszam}
        Set Global Variable    ${overview_string}
        Set Global Variable    ${aktualis_block_id}
        ${overview_string_trimmed}=    Strip String    ${overview_string}
        ${overview_string_esc}=    Replace String    ${overview_string_trimmed}    '    ''
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    "    ""
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    \n    ${EMPTY}
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    \r    ${EMPTY}
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    \t    ${EMPTY}
        Execute Sql String    UPDATE redundancia SET max_ismetlesek_szama = ${max_duplikacio_szamlaló}, max_ismetelt_karakterszam = ${max_ismetelt_karakterszam}, status = CASE WHEN ${max_ismetelt_karakterszam} < ${CONFIG_THRESHOLD_GYANUS} THEN 'Rendben' WHEN ${max_ismetelt_karakterszam} >= ${CONFIG_THRESHOLD_GYANUS} AND ${max_ismetelt_karakterszam} < ${CONFIG_THRESHOLD_MASOLT} THEN 'Gyanús' ELSE 'Másolt' END, overview = '${overview_string_esc}' WHERE id = ${REDUNDANCIA_ID}
        Execute Sql String    UPDATE redundancia SET repeat_block_nbr = ${aktualis_block_id} WHERE id = ${REDUNDANCIA_ID}
        Return From Keyword
    END

    ${kisbetus}=    Convert To Lowercase    ${szoveg}
    @{sorok}=    Split String    ${kisbetus}    \n
    @{hashValues}=    Create List
    ${ossz_sor}=    Get Length    ${sorok}
    ${ossz_str}=    Convert To String    ${ossz_sor}
    # Log To Console    Feldolgozandó sorok száma: ${ossz_str}
    # line_number mező frissítése a redundancia táblában
    Execute Sql String    UPDATE redundancia SET line_number = ${ossz_sor} WHERE id = ${REDUNDANCIA_ID}
    ${aktualis_duplikacio_szamlaló}=    Set Variable    0
    ${max_duplikacio_szamlaló}=    Set Variable    0
    ${ismetelt_karakterszam}=    Set Variable    0
    ${max_ismetelt_karakterszam}=    Set Variable    0
    ${aktualis_block_id}=    Set Variable    0
    ${blokkon_beluli_sor_szam}=    Set Variable    0  # Blokkon belüli sor számláló
    ${elozo_duplikalt}=    Set Variable    False
    ${overview_string}=    Set Variable    ${EMPTY}    # Progress karakterek gyűjtése
    # Fájl név kivonása (közös használatra)
    ${file_name}=    Evaluate    os.path.basename(r"${DOCX_FILE}")    modules=os
    # Korábbi rekordok törlése az aktuális fájlhoz a megismételhetőség érdekében
    @{existing_hashcodes}=    Query    SELECT COUNT(*) FROM hashCodes WHERE file_name = '${file_name}'
    ${hashcodes_count}=    Set Variable    0
    Run Keyword If    len(${existing_hashcodes}) > 0    Set Variable    ${hashcodes_count}    ${existing_hashcodes[0][0]}
    @{existing_repeats}=    Query    SELECT COUNT(*) FROM repeat WHERE file_name = '${file_name}'
    ${repeats_count}=    Set Variable    0
    Run Keyword If    len(${existing_repeats}) > 0    Set Variable    ${repeats_count}    ${existing_repeats[0][0]}
    IF    ${hashcodes_count} > 0
        Execute Sql String    DELETE FROM hashCodes WHERE file_name = '${file_name}'
    # Log To Console    Törölve ${hashcodes_count} hashCodes rekord
    END
    IF    ${repeats_count} > 0
        Execute Sql String    DELETE FROM repeat WHERE file_name = '${file_name}'
    # Log To Console    Törölve ${repeats_count} repeat rekord
    END
    ${sor_index}=    Set Variable    0
    # REDUNDANCIA_ID globálissá tétele, ha más kulcsszóból is kellene
    Set Global Variable    ${REDUNDANCIA_ID}
    ${TOKEN_MIN}=    Evaluate    __import__('sys').path.append('libraries') or int(__import__('duplikacio_config').DuplikacioConfig().get('token_min', 10))
    # ${tul_rovid_szamlalo}=    Set Variable    0
    ${progress_counter}=    Set Variable    0
    FOR    ${sor}    IN    @{sorok}
        # Sor hosszának ellenőrzése - token_min karakternél rövidebb sorokat kihagyjuk
        ${sor_hossz}=    Get Length    ${sor}
        IF    ${sor_hossz} < ${TOKEN_MIN}
            ${sor_index}=    Evaluate    ${sor_index} + 1
            CONTINUE    # Túl rövid sor, kihagyjuk
        END
        ${tomoritett}=    Replace String Using Regexp    ${sor}    [^a-zA-ZáéíóöőúüűÁÉÍÓÖŐÚÜŰ]    ${EMPTY}
        ${sor_hossz}=    Get Length    ${tomoritett}
        IF    ${sor_hossz} < ${TOKEN_MIN}
            ${sor_index}=    Evaluate    ${sor_index} + 1
            CONTINUE    # Túl rövid sor, kihagyjuk
        END
       
       
        ${sor_index}=    Evaluate    ${sor_index} + 1
       
        ${md5}=    Evaluate    __import__('hashlib').md5(u'''${tomoritett}'''.encode('utf-8')).hexdigest()
        # SQL escape-elés: apostrofok duplikálása
        ${escaped_sor}=    Replace String    ${sor}    '    ''
        ${escaped_sor}=    Replace String    ${escaped_sor}    "    ""  # dupla idézőjel escape
        ${escaped_sor}=    Replace String    ${escaped_sor}    \n    ${EMPTY}
        ${escaped_sor}=    Replace String    ${escaped_sor}    \r    ${EMPTY}
        ${escaped_sor}=    Replace String    ${escaped_sor}    \t    ${EMPTY}
        # Ellenőrizzük, hogy létezik-e már ez a hash az adatbázisban
        @{results}=    Query    SELECT COUNT(*) FROM hashCodes WHERE hash_value = '${md5}'
            ${count}=    Set Variable    0
            Run Keyword If    len(${results}) > 0    Set Variable    ${count}    ${results[0][0]}
            ${exists}=    Set Variable    0
            Run Keyword If    len(${results}) > 1    Set Variable    ${exists}    ${results[1][0]}
            Run Keyword If    len(${results}) == 1    Set Variable    ${exists}    ${results[0][0]}
        IF    '${md5}' not in @{hashValues} and ${exists} == 0
            # Ha előzőleg duplikációs blokkban voltunk, akkor most vége, max értékek frissítése
            IF    ${aktualis_duplikacio_szamlaló} > 0
                ${uj_max_duplikacio}=    Evaluate    max(${max_duplikacio_szamlaló}, ${aktualis_duplikacio_szamlaló})
                ${uj_max_karakter}=    Evaluate    max(${max_ismetelt_karakterszam}, ${ismetelt_karakterszam})

                ${max_duplikacio_szamlaló}=    Set Variable    ${uj_max_duplikacio}
                ${max_ismetelt_karakterszam}=    Set Variable    ${uj_max_karakter}
            END
            Append To List    ${hashValues}    ${md5}
            # Aktuális dátum és idő megszerzése
            ${current_date}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y-%m-%d')
            ${current_time}=    Evaluate    __import__('datetime').datetime.now().strftime('%H:%M:%S')
            # Fájl útvonal kivonása (file_path csak az útvonal fájlnév nélkül)
            ${full_path}=    Evaluate    os.path.abspath(r"${DOCX_FILE}")    modules=os
            ${file_path}=    Evaluate    os.path.dirname(r"${full_path}")    modules=os
            ${file_name_esc}=    Replace String    ${file_name}    '    ''
            ${file_name_esc}=    Replace String    ${file_name_esc}    "    ""
            ${file_name_esc}=    Replace String    ${file_name_esc}    \n    ${EMPTY}
            ${file_name_esc}=    Replace String    ${file_name_esc}    \r    ${EMPTY}
            ${file_name_esc}=    Replace String    ${file_name_esc}    \t    ${EMPTY}
            ${file_path_esc}=    Replace String    ${file_path}    '    ''
            ${file_path_esc}=    Replace String    ${file_path_esc}    "    ""
            ${file_path_esc}=    Replace String    ${file_path_esc}    \n    ${EMPTY}
            ${file_path_esc}=    Replace String    ${file_path_esc}    \r    ${EMPTY}
            ${file_path_esc}=    Replace String    ${file_path_esc}    \t    ${EMPTY}
            Run Keyword And Ignore Error    Execute Sql String    INSERT OR IGNORE INTO hashCodes (hash_value, file_name, file_path, created_date, created_time, line_content, redundancia_id) VALUES ('${md5}', '${file_name_esc}', '${file_path_esc}', '${current_date}', '${current_time}', '${escaped_sor}', ${REDUNDANCIA_ID})
            Log To Console    .    no_newline=True    # új tartalom
            ${overview_string}=    Set Variable    ${overview_string}.    # Progress karakter hozzáadása
            ${progress_counter}=    Evaluate    ${progress_counter} + 1
            # Insert a line break only after every 100th progress character
            Run Keyword If    ${progress_counter} % 100 == 0    Log To Console    ${EMPTY}
            # Új tartalom esetén duplikáció számlálók nullázása
            ${aktualis_duplikacio_szamlaló}=    Set Variable    0
            ${ismetelt_karakterszam}=    Set Variable    0
            ${elozo_duplikalt}=    Set Variable    False
            ${blokkon_beluli_sor_szam}=    Set Variable    0  # Blokkon belüli számláló nullázása
        ELSE
            # Duplikált tartalom - ellenőrizzük a státuszt a jelenleg ismételt karakterszám alapján
            #IF    ${max_ismetelt_karakterszam} >= ${CONFIG_THRESHOLD_MASOLT}
            IF    ${ismetelt_karakterszam} >= ${CONFIG_THRESHOLD_MASOLT}
                Log To Console    !    no_newline=True    # másolt tartalom
                ${overview_string}=    Set Variable    ${overview_string}!    # Progress karakter hozzáadása
                ${progress_counter}=    Evaluate    ${progress_counter} + 1
                # Insert a line break after every 1000th progress character
                Run Keyword If    ${progress_counter} % 100 == 0    Log To Console    ${EMPTY}
            ELSE
                Log To Console    *    no_newline=True    # duplikált tartalom
                ${overview_string}=    Set Variable    ${overview_string}*    # Progress karakter hozzáadása
                ${progress_counter}=    Evaluate    ${progress_counter} + 1
                # Insert a line break after every 1000th progress character
                Run Keyword If    ${progress_counter} % 100 == 0    Log To Console    ${EMPTY}
            END
            # Ha az előző sor nem volt duplikált, új blokkot kezdünk
            IF    '${elozo_duplikalt}' == 'False'
                ${aktualis_block_id}=    Evaluate    ${aktualis_block_id} + 1
                ${blokkon_beluli_sor_szam}=    Set Variable    0  # Új blokk indítása esetén nullázás
            END
            # Blokkon belüli sor szám növelése
            ${blokkon_beluli_sor_szam}=    Evaluate    ${blokkon_beluli_sor_szam} + 1
            # Duplikált tartalom esetén számlálók növelése
            ${aktualis_duplikacio_szamlaló}=    Evaluate    ${aktualis_duplikacio_szamlaló} + 1
            ${sor_hossz}=    Get Length    ${sor}
            ${ismetelt_karakterszam}=    Evaluate    ${ismetelt_karakterszam} + ${sor_hossz}
            # Maximum értékek frissítése ha szükséges
            ${uj_max_duplikacio}=    Evaluate    max(${max_duplikacio_szamlaló}, ${aktualis_duplikacio_szamlaló})
            ${uj_max_karakter}=    Evaluate    max(${max_ismetelt_karakterszam}, ${ismetelt_karakterszam})


            ${max_duplikacio_szamlaló}=    Set Variable    ${uj_max_duplikacio}
            ${max_ismetelt_karakterszam}=    Set Variable    ${uj_max_karakter}
            # Forrás fájl nevének lekérése a hashCodes táblából
            @{source_result}=    Query    SELECT file_name FROM hashCodes WHERE hash_value = '${md5}' LIMIT 1
            ${source_file_name}=    Set Variable    unknown
            ${source_file_path}=    Set Variable    unknown
            @{source_result}=    Query    SELECT file_name, file_path FROM hashCodes WHERE hash_value = '${md5}' LIMIT 1
            IF    ${source_result.__len__()} > 0
                ${source_record}=    Get From List    ${source_result}    0
                ${source_file_name}=    Get From List    ${source_record}    0
                ${source_file_path}=    Get From List    ${source_record}    1
            END
            # Ismételt sor mentése a repeat táblába az új oszlop sorrenddel
            ${current_date}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y-%m-%d')
            ${current_time}=    Evaluate    __import__('datetime').datetime.now().strftime('%H:%M:%S')
            ${source_file_name_esc}=    Replace String    ${source_file_name}    '    ''
            ${source_file_name_esc}=    Replace String    ${source_file_name_esc}    "    ""
            ${source_file_name_esc}=    Replace String    ${source_file_name_esc}    \n    ${EMPTY}
            ${source_file_name_esc}=    Replace String    ${source_file_name_esc}    \r    ${EMPTY}
            ${source_file_name_esc}=    Replace String    ${source_file_name_esc}    \t    ${EMPTY}
            ${source_file_name_esc}=    Replace String    ${source_file_name_esc}    \v    ${EMPTY}
            ${source_file_path_esc}=    Replace String    ${source_file_path}    '    ''
            ${source_file_path_esc}=    Replace String    ${source_file_path_esc}    "    ""
            ${source_file_path_esc}=    Replace String    ${source_file_path_esc}    \n    ${EMPTY}
            ${source_file_path_esc}=    Replace String    ${source_file_path_esc}    \r    ${EMPTY}
            ${source_file_path_esc}=    Replace String    ${source_file_path_esc}    \t    ${EMPTY}
            ${tomoritett_esc}=    Replace String    ${tomoritett}    '    ''
            ${tomoritett_esc}=    Replace String    ${tomoritett_esc}    "    ""
            ${tomoritett_esc}=    Replace String    ${tomoritett_esc}    \n    ${EMPTY}
            ${tomoritett_esc}=    Replace String    ${tomoritett_esc}    \r    ${EMPTY}
            ${tomoritett_esc}=    Replace String    ${tomoritett_esc}    \t    ${EMPTY}
            ${file_path}=    Evaluate    os.path.dirname(r"${docx_file}")    modules=os
            Execute Sql String    INSERT INTO repeat (file_name, file_path, source_file_path, source_file_name, redundancia_id, block_id, line_length, repeated_line, token, created_date, created_time) VALUES ('${file_name_esc}', '${file_path}', '${source_file_path_esc}', '${source_file_name_esc}', ${REDUNDANCIA_ID}, ${blokkon_beluli_sor_szam}, ${sor_hossz}, '${escaped_sor}', '${tomoritett_esc}', '${current_date}', '${current_time}')
            ${elozo_duplikalt}=    Set Variable    True
        END
    END
    # Log To Console    ${EMPTY}    # új sor hozzáadása a végén
    #Otto was here
    # Ha a legutolsó sorok duplikációs blokkban voltak, a max értékeket még egyszer frissíteni kell
    IF    ${aktualis_duplikacio_szamlaló} > 0
        ${uj_max_duplikacio}=    Evaluate    max(${max_duplikacio_szamlaló}, ${aktualis_duplikacio_szamlaló})
        ${uj_max_karakter}=    Evaluate    max(${max_ismetelt_karakterszam}, ${ismetelt_karakterszam})
        ${max_duplikacio_szamlaló}=    Set Variable    ${uj_max_duplikacio}
        ${max_ismetelt_karakterszam}=    Set Variable    ${uj_max_karakter}
    END
    
    # Sum_line_length értékek frissítése valódi blokkok alapján
    
    # Az adott redundancia összes sorát ID szerint rendezve (időrendi sorrend)
    @{all_rows}=    Query    SELECT id, block_id, line_length FROM repeat WHERE redundancia_id = ${REDUNDANCIA_ID} ORDER BY id
    
    ${current_block_start}=    Set Variable    ${None}
    ${current_block_lines}=    Create List
    
    # Soronként végigmegyünk és valódi blokkokat azonosítunk
    FOR    ${row}    IN    @{all_rows}
    Run Keyword If    len(${row}) < 3    Continue For Loop
    ${id}=    Get From List    ${row}    0
    ${block_id}=    Get From List    ${row}    1
    ${line_length}=    Get From List    ${row}    2
        
        # Új blokk kezdődik, ha block_id = 1 (kivéve az első sor)
        IF    ${block_id} == 1 and '${current_block_start}' != 'None'
            # Előző blokk lezárása és sum_line_length frissítése
            ${block_sum}=    Set Variable    0
            FOR    ${block_row}    IN    @{current_block_lines}
                Run Keyword If    len(${block_row}) < 3    Continue For Loop
                ${block_line_length}=    Get From List    ${block_row}    2
                ${block_sum}=    Evaluate    ${block_sum} + ${block_line_length}
            END
            
            # Az előző blokk összes sorának frissítése egyszerre
            ${block_length}=    Get Length    ${current_block_lines}
            IF    ${block_length} > 0
                ${first_block_row}=    Get From List    ${current_block_lines}    0
                ${block_id}=    Get From List    ${first_block_row}    1
                Execute Sql String    UPDATE repeat SET sum_line_length = ${block_sum}, repeat_block_nbr = ${block_length} WHERE redundancia_id = ${REDUNDANCIA_ID} AND block_id = ${block_id}
            END
            
            # Új blokk kezdése
            ${current_block_lines}=    Create List
        END
        
        # Ha ez az első sor vagy új blokk kezdődik
        IF    '${current_block_start}' == 'None'
            ${current_block_start}=    Set Variable    ${id}
        END
        
        # Jelenlegi sor hozzáadása a blokkhoz
        Append To List    ${current_block_lines}    ${row}
    END
    
    # Az utolsó blokk feldolgozása
    IF    len(@{current_block_lines}) > 0
        ${block_sum}=    Set Variable    0
        FOR    ${block_row}    IN    @{current_block_lines}
            Run Keyword If    len(${block_row}) < 3    Continue For Loop
            ${block_line_length}=    Get From List    ${block_row}    2
            ${block_sum}=    Evaluate    ${block_sum} + ${block_line_length}
        END
        
        ${block_length}=    Get Length    ${current_block_lines}
        IF    ${block_length} > 0
            ${first_block_row}=    Get From List    ${current_block_lines}    0
            ${block_id}=    Get From List    ${first_block_row}    1
            Execute Sql String    UPDATE repeat SET sum_line_length = ${block_sum}, repeat_block_nbr = ${block_length} WHERE redundancia_id = ${REDUNDANCIA_ID} AND block_id = ${block_id}
        END
    END
    
    # Max értékek, status és overview mező update-je egyetlen SQL-ben, a végleges értékekkel (NORMÁL ÁG)
    Set Global Variable    ${max_duplikacio_szamlaló}
    Set Global Variable    ${max_ismetelt_karakterszam}
    Set Global Variable    ${overview_string}
    Set Global Variable    ${aktualis_block_id}
    ${overview_string_trimmed}=    Strip String    ${overview_string}
    ${overview_string_esc}=    Replace String    ${overview_string_trimmed}    '    ''
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    "    ""
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    \n    ${EMPTY}
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    \r    ${EMPTY}
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    \t    ${EMPTY}
    Execute Sql String    UPDATE redundancia SET max_ismetlesek_szama = ${max_duplikacio_szamlaló}, max_ismetelt_karakterszam = ${max_ismetelt_karakterszam}, status = CASE WHEN ${max_ismetelt_karakterszam} < ${CONFIG_THRESHOLD_GYANUS} THEN 'Rendben' WHEN ${max_ismetelt_karakterszam} >= ${CONFIG_THRESHOLD_GYANUS} AND ${max_ismetelt_karakterszam} < ${CONFIG_THRESHOLD_MASOLT} THEN 'Gyanús' ELSE 'Másolt' END, overview = '${overview_string_esc}' WHERE id = ${REDUNDANCIA_ID}
    # repeat_block_nbr mező update: feldolgozás közben számláljuk
    Execute Sql String    UPDATE redundancia SET repeat_block_nbr = ${aktualis_block_id} WHERE id = ${REDUNDANCIA_ID}