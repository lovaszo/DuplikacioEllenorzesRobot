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
    # Ha tuple vagy lista, alakítsuk sztringgé
    # Egyszerű sztringgé alakítás tuple/list esetén
    # Robusztus sztringgé alakítás tuple vagy lista esetén
    Run Keyword If    "${szoveg.__class__.__name__}" == "tuple" or "${szoveg.__class__.__name__}" == "list"    Set Variable    ${szoveg}    ${Catenate    SEPARATOR=\n    @{szoveg}}
    # Most már biztosan sztring
    # Ha üres a szöveg vagy tartalmazza a [HIBA] szöveget, azonnal visszatérés
    #otto was here
    #Log To Console     ${szoveg}

    IF    "[HIBA]" in $szoveg
        Execute Sql String    UPDATE redundancia SET status = 'Hibás', overview = '${szoveg}' WHERE id = ${REDUNDANCIA_ID}
        # Max értékek, status és overview mező update-je egyetlen SQL-ben, a végleges értékekkel
        Set Global Variable    ${max_duplikacio_szamlalo}    0
    Set Global Variable    ${max_ismetelt_karakterszam}    0
        Set Global Variable    ${overview_string}    ${EMPTY}
        Set Global Variable    ${aktualis_block_id}   0
        ${overview_string_trimmed}=    Strip String    ${overview_string}
        ${overview_string_esc}=    Replace String    ${overview_string_trimmed}    '    ''
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    "    ""
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    \n    ${EMPTY}
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    \r    ${EMPTY}
        ${overview_string_esc}=    Replace String    ${overview_string_esc}    \t    ${EMPTY}
        Execute Sql String    UPDATE redundancia SET max_ismetlesek_szama = ${max_duplikacio_szamlalo}, max_ismetelt_karakterszam = ${max_ismetelt_karakterszam}, status = CASE WHEN ${max_ismetelt_karakterszam} < ${CONFIG_THRESHOLD_GYANUS} THEN 'Rendben' WHEN ${max_ismetelt_karakterszam} >= ${CONFIG_THRESHOLD_GYANUS} AND ${max_ismetelt_karakterszam} < ${CONFIG_THRESHOLD_MASOLT} THEN 'Gyanús' ELSE 'Másolt' END, overview = '${overview_string_esc}' WHERE id = ${REDUNDANCIA_ID}
        Execute Sql String    UPDATE redundancia SET repeat_block_nbr = ${aktualis_block_id} WHERE id = ${REDUNDANCIA_ID}
        Return From Keyword
    END

    ${kisbetus}=    Convert To Lowercase    ${szoveg}
    @{sorok}=    Split String    ${kisbetus}    \n
    ${ossz_sor}=    Get Length    ${sorok}
    ${ossz_str}=    Convert To String    ${ossz_sor}
    # Log To Console    Feldolgozandó sorok száma: ${ossz_str}
    # line_number mező frissítése a redundancia táblában
    #Execute Sql String    UPDATE redundancia SET line_number = ${ossz_sor} WHERE id = ${REDUNDANCIA_ID}
    
    ${ismetelt_karakterszam}=    Set Variable    0
    ${max_ismetelt_karakterszam}=    Set Variable    0
    
    ${elozo_duplikalt}=    Set Variable    False
    ${aktualis_block_id}=    Set Variable    0
    ${blokkon_beluli_sor_szam}=    Set Variable    0  # Blokkon belüli sor számláló
    
    ${aktualis_duplikacio_szamlaló}=    Set Variable    0
    ${max_duplikacio_szamlalo}=    Set Variable    0
    
    
    ${overview_string}=    Set Variable    ${EMPTY}    # Progress karakterek gyűjtése
    
    ${total_ismetelt_karakterszam}=    Set Variable    0
    ${max_total_ismetelt_karakterszam}=    Set Variable    0
        
    ${current_status}=    Set Variable    Üres
    ${marker}=    Set Variable    .
  
    #
    # Fájl név és file_path kivonása (közös használatra)
    #
    ${file_name}=    Evaluate    os.path.basename(r"${DOCX_FILE}")    modules=os
    ${full_path}=    Evaluate    os.path.abspath(r"${DOCX_FILE}")    modules=os
    ${file_path}=    Evaluate    os.path.dirname(r"${full_path}")    modules=os
    IF     $True     #Escapelés
        # SQL escape-elés: apostrofok duplikálása
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
    END  

    # Korábbi rekordok törlése csak akkor, ha a file_name ÉS a file_path is megegyezik
    Execute Sql String    DELETE FROM hashCodes WHERE file_name = '${file_name}' AND file_path = '${file_path}'
    Execute Sql String    DELETE FROM repeat WHERE file_name = '${file_name}' AND file_path = '${file_path}'
    
    ${sor_index}=    Set Variable    0
    # REDUNDANCIA_ID globálissá tétele, ha más kulcsszóból is kellene
    Set Global Variable    ${REDUNDANCIA_ID}
    ${TOKEN_MIN}=    Evaluate    __import__('sys').path.append('libraries') or int(__import__('duplikacio_config').DuplikacioConfig().get('token_min', 10))
    # ${tul_rovid_szamlalo}=    Set Variable    0
    ${progress_counter}=    Set Variable    0

 # Aktuális dátum és idő megszerzése csak egyszer
    ${current_date}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y-%m-%d')
    ${current_time}=    Evaluate    __import__('datetime').datetime.now().strftime('%H:%M:%S')
     FOR    ${sor}    IN    @{sorok}
     
    
       # Szerepel-e legalább 4 szóköz karakter a sor-ban?
        @{spaces}=    Split String    ${sor}    ${SPACE}
        ${space_count}=    Get Length    ${spaces}
        IF    ${space_count} < 4    
            #Log To Console   Skipped ( ${sor} )     no_newline=True
            CONTINUE
        END

        ${sor_hossz}=    Get Length    ${sor}
        ${tomoritett}=    Replace String Using Regexp    ${sor}    [^a-zA-ZáéíóöőúüűÁÉÍÓÖŐÚÜŰ]    ${EMPTY}

        ${sor_index}=    Evaluate    ${sor_index} + 1
        Log To Console    \n${sor_index}--> ${sor}}\n
         CONTINUE
        IF    True    # SQL escape-elés: apostrofok duplikálása
            ${escaped_sor}=    Replace String    ${sor}    '    ''
            ${escaped_sor}=    Replace String    ${escaped_sor}    "    ""  # dupla idézőjel escape
            ${escaped_sor}=    Replace String    ${escaped_sor}    \n    ${EMPTY}
            ${escaped_sor}=    Replace String    ${escaped_sor}    \r    ${EMPTY}
            ${escaped_sor}=    Replace String    ${escaped_sor}    \t    ${EMPTY}
        END
        
        #MD5 érték számolása
        ${md5}=    Evaluate    __import__('hashlib').md5(u'''${tomoritett}'''.encode('utf-8')).hexdigest()
              
        # Ellenőrizzük, hogy létezik-e már ez a hash az adatbázisban
        @{results}=    Query    SELECT COUNT(*) FROM hashCodes WHERE hash_value = '${md5}'
        ${exists}=    Set Variable    0
        ${exists}=    Set Variable If    len(${results}) > 0    ${results[0][0]}    0
        #Log To Console    ===== ${exists} / ${results}=====
        IF    $exists > 0     #már létezik
            #Log To Console  ${exists} - ${sor_index} ${sor} -->>>LÉTEZŐ  HASH<<<
          #lekérjük a benne lévő file_name és file_path értékét és escapeljük
            @{source_result}=    Query    SELECT file_name, file_path FROM hashCodes WHERE hash_value = '${md5}'  LIMIT 1
            IF     True    #source_file kezelése
                ${source_file_name}=    Set Variable    unknown
                ${source_file_path}=    Set Variable    unknown
                IF    ${source_result.__len__()} > 0
                    ${source_record}=    Get From List    ${source_result}    0
                    ${source_file_name}=    Get From List    ${source_record}    0
                    ${source_file_path}=    Get From List    ${source_record}    1
                END
                ${_source_file_name_esc1}=    Replace String    ${source_file_name}    '    ''
                ${_source_file_name_esc2}=    Replace String    ${_source_file_name_esc1}    "    ""
                ${_source_file_name_esc3}=    Replace String    ${_source_file_name_esc2}    \n    ${EMPTY}
                ${_source_file_name_esc4}=    Replace String    ${_source_file_name_esc3}    \r    ${EMPTY}
                ${_source_file_name_esc5}=    Replace String    ${_source_file_name_esc4}    \t    ${EMPTY}
                ${source_file_name_esc}=    Replace String    ${_source_file_name_esc5}    \v    ${EMPTY}
                ${_source_file_path_esc1}=    Replace String    ${source_file_path}    '    ''
                ${_source_file_path_esc2}=    Replace String    ${_source_file_path_esc1}    "    ""
                ${_source_file_path_esc3}=    Replace String    ${_source_file_path_esc2}    \n    ${EMPTY}
                ${_source_file_path_esc4}=    Replace String    ${_source_file_path_esc3}    \r    ${EMPTY}
                ${source_file_path_esc}=    Replace String    ${_source_file_path_esc4}    \t    ${EMPTY}
                ${_tomoritett_esc1}=    Replace String    ${tomoritett}    '    ''
                ${_tomoritett_esc2}=    Replace String    ${_tomoritett_esc1}    "    ""
                ${_tomoritett_esc3}=    Replace String    ${_tomoritett_esc2}    \n    ${EMPTY}
                ${_tomoritett_esc4}=    Replace String    ${_tomoritett_esc3}    \r    ${EMPTY}
                ${tomoritett_esc}=    Replace String    ${_tomoritett_esc4}    \t    ${EMPTY}
        END            
     
            IF     ${elozo_duplikalt} == False
                #új ismétlési blokk kezdődik
                 ${ismetelt_karakterszam}=    Set Variable    0
                ${aktualis_block_id}=    Evaluate    ${aktualis_block_id} + 1

            ELSE
                #folytatódik az ismétlési blokk
                 ${ismetelt_karakterszam}=    Evaluate    ${ismetelt_karakterszam} + ${sor_hossz}
                 ${aktualis_duplikacio_szamlaló}=    Evaluate    ${aktualis_duplikacio_szamlaló} + 1
            END
             ${elozo_duplikalt}=    Set Variable    True
            # Duplikált tartalom esetén számlálók növelése

           
            # Blokkon belüli sor szám növelése
            ${blokkon_beluli_sor_szam}=    Evaluate    ${blokkon_beluli_sor_szam} + 1
            ${total_ismetelt_karakterszam}=     Evaluate    ${sor_hossz} + ${total_ismetelt_karakterszam}
            ${max_total_ismetelt_karakterszam}=    Evaluate    max(${total_ismetelt_karakterszam}, ${max_total_ismetelt_karakterszam})
            ${max_duplikacio_szamlalo}=    Evaluate    max(${max_duplikacio_szamlalo}, ${aktualis_block_id})
           
           #Log To Console   ISMETELT_KARAKTERSZAM: ${ismetelt_karakterszam}        
           # Duplikált tartalom - ellenőrizzük a státuszt a jelenleg ismételt karakterszám alapján
             IF    ${ismetelt_karakterszam} < ${CONFIG_THRESHOLD_GYANUS}
                    ${marker}=    Set Variable    *
            END
   IF        ${ismetelt_karakterszam} >= ${CONFIG_THRESHOLD_MASOLT}
                IF     '${current_status}' == 'Gyanús'
                    ${current_status}=    Set Variable    Másolt
                END
                ${marker}=    Set Variable    !
            END 
            IF    ${ismetelt_karakterszam} >= ${CONFIG_THRESHOLD_GYANUS} and ${ismetelt_karakterszam} < ${CONFIG_THRESHOLD_MASOLT}
                   IF     '${current_status}' == 'Rendben'
                        ${current_status}=    Set Variable    Gyanús
                    END
                ${marker}=    Set Variable    ?
                #Log To Console    ${marker} ${ismetelt_karakterszam}
            END
  
         
            
            #beírás repeat táblába
            Execute Sql String    INSERT INTO repeat (file_name, file_path, source_file_path, source_file_name, redundancia_id, block_id, line_length, sum_line_length, repeated_line, token, created_date, created_time) VALUES ('${file_name_esc}', '${file_path}', '${source_file_path_esc}', '${source_file_name_esc}', ${REDUNDANCIA_ID}, ${aktualis_block_id}, ${sor_hossz}, ${max_ismetelt_karakterszam}, '${escaped_sor}', '${tomoritett_esc}', '${current_date}', '${current_time}')
        ELSE
            #
            # Nem létezik a sor még a hash táblában F    '$exists = 0'
            #
            IF     '${current_status}' == 'Üres'
                ${current_status}=    Set Variable    Rendben
            END
            ${marker}=    Set Variable    .
            #Log To Console    ${sor_index} ${sor} --<<<HIÁNYZÓ HASH>>>
            ${elozo_duplikalt}=    Set Variable    False
            ${blokkon_beluli_sor_szam}=    Set Variable    0  # Új blokk indítása esetén nullázás
            ${ismetelt_karakterszam}=    Set Variable    0       
        END
        # overview sor kiirása
        Log To Console    ${marker} [${sor}]   no_newline=True    # duplikált tartalom
        ${overview_string}=    Set Variable    ${overview_string}${marker}
        ${progress_counter}=    Evaluate    ${progress_counter} + 1
        #Insert a single line break after every 100th, and a double after every 1000th progress character
        Run Keyword If    ${progress_counter} % 1000 == 0    Log To Console    \n
        Run Keyword If    ${progress_counter} % 100 == 0 and ${progress_counter} % 1000 != 0    Log To Console    ${EMPTY}
        
        #az első előfordulás hosszát is beszámítjuk
        ${sor_hossz}=    Get Length    ${sor}
        ${ismetelt_karakterszam}=    Evaluate    ${ismetelt_karakterszam} + ${sor_hossz}
           
        #Beírjuk a hash táblába
        Run Keyword And Ignore Error    Execute Sql String    INSERT INTO hashCodes (hash_value, file_name, file_path, created_date, created_time, used_by_nbr, line_content, redundancia_id) VALUES ('${md5}', '${file_name_esc}', '${file_path_esc}', '${current_date}', '${current_time}', 0, '${escaped_sor}', ${REDUNDANCIA_ID})
        #Növeljük a használtság számlálót
        Execute Sql String    UPDATE hashCodes SET used_by_nbr = used_by_nbr + 1 WHERE hash_value = '${md5}'   

    END
 
    # Max értékek, status és overview mező update-je egyetlen SQL-ben, a végleges értékekkel (NORMÁL ÁG)
    #Set Global Variable    ${max_duplikacio_szamlaló}
    Set Global Variable    ${max_ismetelt_karakterszam}
    Set Global Variable    ${overview_string}
    Set Global Variable    ${aktualis_block_id}
    ${overview_string_trimmed}=    Strip String    ${overview_string}
    ${overview_string_esc}=    Replace String    ${overview_string_trimmed}    '    ''
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    "    ""
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    \n    ${EMPTY}
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    \r    ${EMPTY}
    ${overview_string_esc}=    Replace String    ${overview_string_esc}    \t    ${EMPTY}


    Log To Console    [>>> ${current_status} <<<]\n

    Execute Sql String    UPDATE redundancia SET repeat_block_nbr = ${aktualis_block_id} ,max_ismetlesek_szama = ${max_duplikacio_szamlalo}, max_ismetelt_karakterszam = ${max_ismetelt_karakterszam}, status = '${current_status}', overview = '${overview_string_esc}' WHERE id = ${REDUNDANCIA_ID}
    