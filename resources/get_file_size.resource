*** Keywords ***
Get File Size
    [Arguments]    ${file_path}
    ${size}=    Evaluate    __import__('os').path.getsize(r'''${file_path}''')
    RETURN    ${size}
