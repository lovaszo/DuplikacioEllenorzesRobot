*** Keywords ***
*** Settings ***
Resource    keywords.robot

*** Keywords ***





Hash Es Repeat Feltoltes
    [Arguments]    ${docx_file}    ${redundancia_id}
    ${file_name}=    Evaluate    os.path.basename(r"${docx_file}")    modules=os
    ${szoveg}=    Beolvasom A DOCX Fájlt
    ${kisbetus}=    Convert To Lowercase    ${szoveg}
    @{sorok}=    Split String    ${kisbetus}    \n
    # Törlés először
    @{existing_hashcodes}=    Query    SELECT COUNT(*) FROM hashCodes WHERE file_name = '${file_name}'
    ${hashcodes_count}=    Get From List    ${existing_hashcodes[0]}    0
    @{existing_repeats}=    Query    SELECT COUNT(*) FROM repeat WHERE file_name = '${file_name}'
    ${repeats_count}=    Get From List    ${existing_repeats[0]}    0
    IF    ${hashcodes_count} > 0
    ${file_path}=    Evaluate    os.path.dirname(r"${docx_file}")    modules=os
    Execute Sql String    DELETE FROM hashCodes WHERE file_name = '${file_name}' AND file_path = '${file_path}'
        Log To Console    Törölve ${hashcodes_count} hashCodes rekord
    END
    IF    ${repeats_count} > 0
    ${file_path}=    Evaluate    os.path.dirname(r"${docx_file}")    modules=os
    Execute Sql String    DELETE FROM repeat WHERE file_name = '${file_name}' AND file_path = '${file_path}'
        Log To Console    Törölve ${repeats_count} repeat rekord
    END
    ${hashValues}=    Create List
    ${aktualis_block_id}=    Set Variable    0
    ${blokkon_beluli_sor_szam}=    Set Variable    0
    ${elozo_duplikalt}=    Set Variable    False
    ${sor_index}=    Set Variable    0
    FOR    ${sor}    IN    @{sorok}
    ${file_path}=    Evaluate    os.path.dirname(r"${docx_file}")    modules=os
    ${sor_hossz}=    Get Length    ${sor}
        IF    ${sor_hossz} < 10
            ${sor_index}=    Evaluate    ${sor_index} + 1
            CONTINUE
        END
        ${tomoritett}=    Replace String Using Regexp    ${sor}    [^a-zA-ZáéíóöőúüűÁÉÍÓÖŐÚÜŰ]    ${EMPTY}
        ${sor_index}=    Evaluate    ${sor_index} + 1
        ${md5}=    Evaluate    __import__('hashlib').md5(u'''${tomoritett}'''.encode('utf-8')).hexdigest()
        ${escaped_sor}=    Replace String    ${sor}    '    ''
        @{results}=    Query    SELECT COUNT(*) FROM hashCodes WHERE hash_value = '${md5}'
        ${count}=    Get From List    ${results}    0
        ${exists}=    Get From List    ${count}    0
        IF    '${md5}' not in @{hashValues} and ${exists} == 0
            Append To List    ${hashValues}    ${md5}
            ${current_date}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y-%m-%d')
            ${current_time}=    Evaluate    __import__('datetime').datetime.now().strftime('%H:%M:%S')
            ${full_path}=    Evaluate    os.path.abspath(r"${docx_file}")    modules=os
            ${file_path}=    Evaluate    os.path.dirname(r"${full_path}")    modules=os
            Run Keyword And Ignore Error    Execute Sql String    INSERT OR IGNORE INTO hashCodes (hash_value, file_name, file_path, created_date, created_time, line_content, redundancia_id) VALUES ('${md5}', '${file_name}', '${file_path}', '${current_date}', '${current_time}', '${escaped_sor}', ${redundancia_id})
            ${aktualis_duplikacio_szamlaló}=    Set Variable    0
            ${ismetelt_karakterszam}=    Set Variable    0
            ${elozo_duplikalt}=    Set Variable    False
            ${blokkon_beluli_sor_szam}=    Set Variable    0
        ELSE
            IF    '${elozo_duplikalt}' == 'False'
                ${aktualis_block_id}=    Evaluate    ${aktualis_block_id} + 1
                ${blokkon_beluli_sor_szam}=    Set Variable    0
            END
            ${blokkon_beluli_sor_szam}=    Evaluate    ${blokkon_beluli_sor_szam} + 1
            ${aktualis_duplikacio_szamlaló}=    Evaluate    ${aktualis_duplikacio_szamlaló} + 1
            ${sor_hossz}=    Get Length    ${sor}
            ${ismetelt_karakterszam}=    Evaluate    ${ismetelt_karakterszam} + ${sor_hossz}
            #@{source_result}=    Query    SELECT file_name FROM hashCodes WHERE hash_value = '${md5}' LIMIT 1
            ${source_file_name}=    Set Variable    unknown
            ${source_file_path}=    Set Variable    unknown
            @{source_result}=    Query    SELECT file_name, file_path FROM hashCodes WHERE hash_value = '${md5}' LIMIT 1
            IF    ${source_result.__len__()} > 0
                ${source_record}=    Get From List    ${source_result}    0
                ${source_file_name}=    Get From List    ${source_record}    0
                ${source_file_path}=    Get From List    ${source_record}    1
                Log To Console    ${source_file_path}/${source_file_name}
            END
            ${file_path}=    Evaluate    os.path.dirname(r"${docx_file}")    modules=os
            ${current_date}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y-%m-%d')
            ${current_time}=    Evaluate    __import__('datetime').datetime.now().strftime('%H:%M:%S')
            Execute Sql String    INSERT INTO repeat (file_name, file_path, source_file_path, source_file_name, redundancia_id, block_id, line_length, repeated_line, created_date, created_time) VALUES ('${file_name}', '${file_path}', '${source_file_path}', '${source_file_name}', ${redundancia_id}, ${blokkon_beluli_sor_szam}, ${sor_hossz}, '${escaped_sor}', '${current_date}', '${current_time}')
            ${elozo_duplikalt}=    Set Variable    True
        END
    END
