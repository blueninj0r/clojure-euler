@echo off

setLocal EnableExtensions EnableDelayedExpansion

set LEIN_VERSION=2.0.0

if "%LEIN_VERSION:~-9%" == "-SNAPSHOT" (
    set SNAPSHOT=YES
) else (
    set SNAPSHOT=NO
)

set ORIGINAL_PWD=%CD%
:: If ORIGINAL_PWD ends with a backslash (such as C:\),
:: we need to escape it with a second backslash.
if "%ORIGINAL_PWD:~-1%x" == "\x" set "ORIGINAL_PWD=%ORIGINAL_PWD%\"

call :FIND_DIR_CONTAINING_UPWARDS project.clj
if "%DIR_CONTAINING%" neq "" cd "%DIR_CONTAINING%"

:: LEIN_JAR and LEIN_HOME variables can be set manually.

if "x%LEIN_HOME%" == "x" (
    set LEIN_HOME=%USERPROFILE%\.lein
)

if "x%LEIN_JAR%" == "x" set LEIN_JAR=!LEIN_HOME!\self-installs\leiningen-!LEIN_VERSION!-standalone.jar

if "%1" == "self-install" goto SELF_INSTALL
if "%1" == "upgrade"      goto UPGRADE

if exist "%~dp0..\src\leiningen\version.clj" (
    :: Running from source checkout.
    call :SET_LEIN_ROOT "%~dp0.."

    set LEIN_LIBS=
    for %%j in ("!LEIN_ROOT!\leiningen-core\lib\*") do set LEIN_LIBS=!LEIN_LIBS!%%~fj;
    set LEIN_LIBS=!LEIN_LIBS!

    if "x!LEIN_LIBS!" == "x" goto NO_DEPENDENCIES

    set CLASSPATH=!LEIN_LIBS!!LEIN_ROOT!\leiningen-core\src;!LEIN_ROOT!\leiningen-core\resources;!LEIN_ROOT!\leiningen-core\test;!LEIN_ROOT!\src;!LEIN_ROOT!\resources

    :: Apply context specific CLASSPATH entries
    if exist "%~dp0..\.lein-classpath" (
        for /f %%i in ("%~dp0...lein-classpath") do set CONTEXT_CP=%%i

        if NOT "x!CONTEXT_CP!"=="x" (
            set CLASSPATH=!CONTEXT_CP!;!CLASSPATH!
        )
    )
) else (
    :: Not running from a checkout.
    if not exist "%LEIN_JAR%" goto NO_LEIN_JAR
    set CLASSPATH=%LEIN_JAR%
  
    if exist ".lein-classpath" (
        for /f %%i in (.lein-classpath) do set CONTEXT_CP=%%i 

        if NOT "x!CONTEXT_CP!"=="x" (
            set CLASSPATH=!CONTEXT_CP!;!CLASSPATH!
        )
    )
)

if not "x%DEBUG%" == "x" echo CLASSPATH=!CLASSPATH!
:: ##################################################


call :EnsureIsSet JAVA_CMD java
call :EnsureIsSet LEIN_JAVA_CMD %JAVA_CMD%
rem if "x%JAVA_CMD%" == "x" set JAVA_CMD="java"
if "x%JVM_OPTS%" == "x" set JVM_OPTS=%JAVA_OPTS%
goto RUN

:EnsureIsSet 
rem parameters: Variable DefaultValue
rem Variable's value can be empty, if it is then it will be set to the DefaultValue(which is not modified/stripped)
rem it will strip all encountered double quotes from Variable and from Variable's value
rem this script will fail if Variable contains characters like >, <, |, & or even parentheses or even number of double quotes
rem the Variable's value will be surrounded by double quotes (no inner double quotes though, they're all stripped)
rem  except in the case of DefaultValue which is set as it is

SETLOCAL
set _var=%~1

call set _result=%%%_var%%%

for /f "useback tokens=*" %%a in ('%_result%') do (
set _result=%%~a
set _result=%_result:"=%
)

( ENDLOCAL
  if "x%_result%" == "x" (set %_var%=%2) ELSE (set %_var%="%_result%")
)
goto :eof


:NO_LEIN_JAR
echo.
echo %LEIN_JAR% can not be found.
echo You can try running "lein self-install"
echo or change LEIN_JAR environment variable
echo or edit lein.bat to set appropriate LEIN_JAR path.
echo.
goto EOF

:NO_DEPENDENCIES
echo.
echo Leiningen is missing its dependencies.
echo Please see "Building" in the README.
echo.
goto EOF

:SELF_INSTALL
if exist "%LEIN_JAR%" (
    echo %LEIN_JAR% already exists. Delete and retry.
    goto EOF
)

for %%f in ("%LEIN_JAR%") do set LEIN_INSTALL_DIR="%%~dpf"
if not exist %LEIN_INSTALL_DIR% mkdir %LEIN_INSTALL_DIR%

echo Downloading Leiningen now...

set HTTP_CLIENT=wget --no-check-certificate -O
wget>nul 2>&1
if ERRORLEVEL 9009 (
    curl>nul 2>&1
    if ERRORLEVEL 9009 goto NO_HTTP_CLIENT
    set HTTP_CLIENT=curl --insecure -f -L -o
)
:: set LEIN_JAR_URL=https://leiningen.s3.amazonaws.com/downloads/leiningen-%LEIN_VERSION%-standalone.jar
set LEIN_JAR_URL=https://leiningen.s3.amazonaws.com/downloads/leiningen-%LEIN_VERSION%-standalone.jar
%HTTP_CLIENT% "%LEIN_JAR%.pending" %LEIN_JAR_URL%
if ERRORLEVEL 1 (
    del "%LEIN_JAR%.pending" >nul 2>&1
    goto DOWNLOAD_FAILED
)
move /y "%LEIN_JAR%.pending" "%LEIN_JAR%"
goto EOF

:DOWNLOAD_FAILED
echo.
echo Failed to download %LEIN_JAR_URL%
if %SNAPSHOT% == YES echo See README.md for SNAPSHOT build instructions.
echo.
goto EOF


:UPGRADE
set LEIN_BAT=%~dp0%~nx0
echo The script at %LEIN_BAT% will be upgraded to the latest version in series %LEIN_VERSION%.
set /P ANSWER=Do you want to continue (Y/N)?
if /i {%ANSWER%}=={y}   goto YES_UPGRADE
if /i {%ANSWER%}=={yes} goto YES_UPGRADE
echo Aborted.
exit /B 1


:YES_UPGRADE
echo Downloading latest Leiningen batch script...

set HTTP_CLIENT=wget --no-check-certificate -O
wget>nul 2>&1
if ERRORLEVEL 9009 (
    curl>nul 2>&1
    if ERRORLEVEL 9009 goto NO_HTTP_CLIENT
    set HTTP_CLIENT=curl --insecure -f -L -o
)
::set LEIN_BAT_URL=https://raw.github.com/technomancy/leiningen/master/bin/lein.bat
set LEIN_BAT_URL=https://raw.github.com/technomancy/leiningen/preview/bin/lein.bat
set TEMP_BAT=%~dp0temp-lein-%RANDOM%%RANDOM%.bat
%HTTP_CLIENT% "%LEIN_BAT%.pending" %LEIN_BAT_URL%
if ERRORLEVEL 1 (
    del "%LEIN_BAT%.pending" >nul 2>&1
    echo Failed to download %LEIN_BAT_URL%
    goto EOF
)
move /y "%LEIN_BAT%.pending" "%TEMP_BAT%"
echo.
echo Upgrading...
set LEIN_JAR=
call "%TEMP_BAT%" self-install
move /y "%TEMP_BAT%" "%LEIN_BAT%" && goto EOF
goto EOF


:NO_HTTP_CLIENT
echo.
echo ERROR: Wget/Curl not found. Make sure at least either of Wget and Curl is
echo        installed and is in PATH. You can get them from URLs below:
echo.
echo Wget: "http://users.ugent.be/~bpuype/wget/"
echo Curl: "http://curl.haxx.se/dlwiz/?type=bin&os=Win32&flav=-&ver=2000/XP"
echo.
goto EOF


:SET_LEIN_ROOT
set LEIN_ROOT=%~f1
goto EOF

:: Find directory containing filename supplied in first argument
:: looking in current directory, and looking up the parent
:: chain until we find it, or run out
:: returns result in %DIR_CONTAINING%
:: empty string if we don't find it
:FIND_DIR_CONTAINING_UPWARDS
set DIR_CONTAINING=%CD%
set LAST_DIR=

:LOOK_AGAIN
if "%DIR_CONTAINING%" == "%LAST_DIR%" (
    :: didn't find it
    set DIR_CONTAINING=
    goto EOF
)

if EXIST "%DIR_CONTAINING%\%1" (
    :: found it - use result in DIR_CONTAINING
    goto EOF
)

set LAST_DIR=%DIR_CONTAINING%
call :GET_PARENT_PATH "%DIR_CONTAINING%\.."
set DIR_CONTAINING=%PARENT_PATH%
goto LOOK_AGAIN

:GET_PARENT_PATH
set PARENT_PATH=%~f1
goto EOF


:RUN
:: We need to disable delayed expansion here because the %* variable
:: may contain bangs (as in test!). There may also be special
:: characters inside the TRAMPOLINE_FILE.
setLocal DisableDelayedExpansion

if "%1" == "trampoline" (goto RUN_TRAMPOLINE) else (goto RUN_NORMAL)

:RUN_TRAMPOLINE
set "TRAMPOLINE_FILE=%TEMP%\lein-trampoline-%RANDOM%.bat"
%LEIN_JAVA_CMD% -client %LEIN_JVM_OPTS% ^
 -Dclojure.compile.path="%DIR_CONTAINING%/target/classes" ^
 -Dleiningen.original.pwd="%ORIGINAL_PWD%" ^
 -Dleiningen.trampoline-file="%TRAMPOLINE_FILE%" ^
 -cp "%CLASSPATH%" clojure.main -e "(use 'leiningen.core.main)(apply -main (map str '(%*)))"

if not exist "%TRAMPOLINE_FILE%" goto EOF
call "%TRAMPOLINE_FILE%"
del "%TRAMPOLINE_FILE%"
goto EOF

:RUN_NORMAL
%LEIN_JAVA_CMD% -client %LEIN_JVM_OPTS% ^
 -Dclojure.compile.path="%DIR_CONTAINING%/target/classes" ^
 -Dleiningen.original.pwd="%ORIGINAL_PWD%" ^
 -cp "%CLASSPATH%" clojure.main -m leiningen.core.main %*

:EOF

