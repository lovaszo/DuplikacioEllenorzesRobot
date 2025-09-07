@echo off
REM =========================================
REM  DUPLIKACIO ELLENORZO RENDSZER - TELEPITO
REM =========================================
setlocal EnableDelayedExpansion

echo.
echo =========================================
echo   DUPLIKACIO ELLENORZO RENDSZER TELEPITO
echo   Automatikus telepites es beallitas
echo =========================================
echo.

REM Telepitesi konyvtar bekeres
echo Adja meg a telepitesi konyvtar eleresi utjat:
echo (pl: C:\DuplikacioEllenorzo vagy D:\MyProjects\DuplikacioSystem)
echo.
set /p TARGET_DIR="Telepitesi konyvtar: "

if "%TARGET_DIR%"=="" (
    echo HIBA: Nem adott meg telepitesi konyvtarat!
    pause
    exit /b 1
)

echo.
echo Telepitesi cel: %TARGET_DIR%
echo.

REM Ellenorizzuk a Python megletet
python --version >nul 2>&1
if errorlevel 1 (
    echo HIBA: Python nincs telepitve vagy nem elerheto!
    echo Kerem telepitse a Python 3.8+ verzioit a python.org oldalrol.
    pause
    exit /b 1
)

echo Python verzio:
python --version
echo.

REM Konyvtar letrehozasa ha nem letezik
if not exist "%TARGET_DIR%" (
    echo Konyvtar letrehozasa: %TARGET_DIR%
    mkdir "%TARGET_DIR%"
    if errorlevel 1 (
        echo HIBA: Nem sikerult letrehozni a konyvtarat!
        pause
        exit /b 1
    )
) else (
    echo Konyvtar mar letezik: %TARGET_DIR%
)

echo.
echo Fajlok masolasa...

REM Szukseges fajlok masolasa
copy "PLG-00-main.robot" "%TARGET_DIR%\"
copy "PLG-02-read_docx.robot" "%TARGET_DIR%\"
copy "PLG-03-write-excel.robot" "%TARGET_DIR%\"
copy "Duplikacio.config" "%TARGET_DIR%\"
copy "TELEPITO_UTMUTATO.txt" "%TARGET_DIR%\"

REM Markdown dokumentacio fajlok masolasa
copy "README.md" "%TARGET_DIR%\"
copy "DOKUMENTACIO.md" "%TARGET_DIR%\"
copy "TECHNIKAI_ATTEKINTES.md" "%TARGET_DIR%\"
copy "GYORS_REFERENCIA.md" "%TARGET_DIR%\"

REM Libraries mappa masolasa
if exist "libraries" (
    echo Konyvtarak konyvtar masolasa...
    xcopy "libraries" "%TARGET_DIR%\libraries" /E /I /Y
)

REM Resources mappa masolasa
if exist "resources" (
    echo Eroforras konyvtar masolasa...
    xcopy "resources" "%TARGET_DIR%\resources" /E /I /Y
)

REM Test mappa masolasa
if exist "test" (
    echo Teszt konyvtar masolasa...
    xcopy "test" "%TARGET_DIR%\test" /E /I /Y
)

echo Fajlok sikeresen masolva.

REM Ellenorizzuk es javitsuk a hianyzo fajlokat
echo Hianyzo fajlok ellenorzese...
if not exist "%TARGET_DIR%\duplikacio_config.py" (
    echo duplikacio_config.py hianyzo, ujra letrehozas...
    copy "duplikacio_config.py" "%TARGET_DIR%\"
)

echo.

REM Atlepunk a cel konyvtarba
cd /d "%TARGET_DIR%"

REM Virtualis kornyezet letrehozasa
echo Virtualis kornyezet letrehozasa...
if not exist "rf_env" (
    python -m venv rf_env
    if errorlevel 1 (
        echo HIBA: Virtualis kornyezet letrehozasa sikertelen!
        pause
        exit /b 1
    )
    echo Virtualis kornyezet sikeresen letrehozva.
) else (
    echo Virtualis kornyezet mar letezik.
)
echo.

REM Virtualis kornyezet aktivalasa es csomagok telepitese
echo Csomagok telepitese...
REM rf_env\Scripts\activate (nem szükséges, pip elérési út miatt)
rf_env\Scripts\pip.exe install --upgrade pip
rf_env\Scripts\pip.exe install robotframework
rf_env\Scripts\pip.exe install robotframework-databaselibrary
rf_env\Scripts\pip.exe install openpyxl
rf_env\Scripts\pip.exe install python-docx
rf_env\Scripts\pip.exe install pywin32

if errorlevel 1 (
    echo HIBA: Csomagok telepitese sikertelen!
    pause
    exit /b 1
)

echo.
echo start.bat fajl letrehozasa...

REM start.bat fajl letrehozasa
echo @echo off > start.bat
echo REM ========================================= >> start.bat
echo REM  DUPLIKACIO ELLENORZO RENDSZER FUTTATAS >> start.bat
echo REM ========================================= >> start.bat
echo echo. >> start.bat
echo echo ========================================= >> start.bat
echo echo   DUPLIKACIO ELLENORZO RENDSZER >> start.bat
echo echo   Main robot futtatas >> start.bat
echo echo ========================================= >> start.bat
echo echo. >> start.bat
echo. >> start.bat
echo REM Ellenorizzuk a virtualis kornyezet megletet >> start.bat
echo if not exist "rf_env\Scripts\robot.exe" ^( >> start.bat
echo     echo HIBA: Virtualis kornyezet nem talalhato! >> start.bat
echo     echo Futtassa eloszor a telepito.bat fajlt! >> start.bat
echo     pause >> start.bat
echo     exit /b 1 >> start.bat
echo ^) >> start.bat
echo. >> start.bat
echo echo Konfiguracio ellenorzese... >> start.bat
echo if not exist "Duplikacio.config" ^( >> start.bat
echo     echo HIBA: Duplikacio.config fajl nem talalhato! >> start.bat
echo     echo Ellenorizze a konfiguracios fajlt! >> start.bat
echo     pause >> start.bat
echo     exit /b 1 >> start.bat
echo ^) >> start.bat
echo. >> start.bat
echo REM Results konyvtar letrehozasa ha nem letezik >> start.bat
echo if not exist "results" ^( >> start.bat
echo     echo Results konyvtar letrehozasa... >> start.bat
echo     mkdir "results" >> start.bat
echo ^) >> start.bat
echo. >> start.bat
echo echo Robot Framework teszt futtatasa... >> start.bat
echo rf_env\Scripts\robot.exe --outputdir results PLG-00-main.robot >> start.bat
echo. >> start.bat
echo if errorlevel 1 ^( >> start.bat
echo     echo HIBA: A teszt futtatasa sikertelen! >> start.bat
echo     echo Ellenorizze a results\log.html fajlt a reszletekert. >> start.bat
echo ^) else ^( >> start.bat
echo     echo. >> start.bat
echo     echo ========================================= >> start.bat
echo     echo TESZT SIKERESEN BEFEJEZODOTT! >> start.bat
echo     echo. >> start.bat
echo     echo Eredmenyek: >> start.bat
echo     echo - Log: results\log.html >> start.bat
echo     echo - Report: results\report.html >> start.bat
echo     echo - Email elkuldve a konfiguralt cimre >> start.bat
echo     echo ========================================= >> start.bat
echo ^) >> start.bat
echo. >> start.bat
echo pause >> start.bat

echo.
echo =========================================
echo TELEPITES SIKERES!
echo.
echo Telepitesi hely: %TARGET_DIR%
echo.
echo Telepitett komponensek:
echo - Robot Framework
echo - Database Library  
echo - OpenPyXL (Excel export)
echo - Python-docx (DOCX olvaso)
echo - PyWin32 (email kuldes)
echo - Teljes projekt fajlok
echo - start.bat futtato script
echo.
echo Hasznalat:
echo 1. Menjen a telepitesi konyvtarba: %TARGET_DIR%
echo 2. Futtassa: start.bat
echo.
echo Konfiguracio: Duplikacio.config fajl szerkesztese
echo Tesztfajlok: test\ konyvtar
echo Eredmenyek: results\ konyvtar
echo =========================================
echo.
echo Szeretne most tesztelni a telepitett rendszert? (i/n)
set /p TEST_NOW="Teszt futtatasa most: "

if /i "%TEST_NOW%"=="i" (
    echo.
    echo Teszt futtatasa...
    cd /d "%TARGET_DIR%"
    call start.bat
) else (
    echo.
    echo A rendszer keszen all a hasznalatra!
    echo Menjen a %TARGET_DIR% konyvtarba es futtassa a start.bat fajlt.
)
echo.
pause
