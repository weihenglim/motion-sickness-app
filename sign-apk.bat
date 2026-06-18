@echo off
setlocal enabledelayedexpansion

set "KEYSTORE_PATH=%~1"
set "KEY_ALIAS=%~2"
set "OUT_APK=%~3"
set "UNSIGNED_APK=%~4"

rem Set defaults
if "%KEYSTORE_PATH%"=="" set "KEYSTORE_PATH=keys/release-key.jks"
if "%KEY_ALIAS%"=="" set "KEY_ALIAS=motion-cue-key"
if "%OUT_APK%"=="" set "OUT_APK=app/build/outputs/apk/release/motion-cue-release.apk"
if "%UNSIGNED_APK%"=="" set "UNSIGNED_APK=app/build/outputs/apk/release/app-release-unsigned.apk"

echo.
echo Using keystore: !KEYSTORE_PATH!
echo Using key alias: !KEY_ALIAS!
echo Output APK: !OUT_APK!
echo Unsigned APK: !UNSIGNED_APK!
echo.

if not exist "!KEYSTORE_PATH!" (
  echo Keystore not found. Generating: !KEYSTORE_PATH!
  rem Create parent directory if it doesn't exist
  for %%D in ("!KEYSTORE_PATH!") do (
    set "KEYSTORE_DIR=%%~dpD"
  )
  if not "!KEYSTORE_DIR!"=="" (
    if not exist "!KEYSTORE_DIR!" mkdir "!KEYSTORE_DIR!"
  )
  keytool -genkeypair -v -keystore "!KEYSTORE_PATH!" -alias "!KEY_ALIAS!" -keyalg RSA -keysize 2048 -validity 10000
  if errorlevel 1 (
    echo Failed to generate keystore
    exit /b 1
  )
  echo Keystore generated successfully
  echo.
) else (
  rem Check if keystore is empty and regenerate if needed
  for %%F in ("!KEYSTORE_PATH!") do (
    if %%~zF equ 0 (
      echo Keystore file is empty. Regenerating: !KEYSTORE_PATH!
      del "!KEYSTORE_PATH!"
      keytool -genkeypair -v -keystore "!KEYSTORE_PATH!" -alias "!KEY_ALIAS!" -keyalg RSA -keysize 2048 -validity 10000
      if errorlevel 1 (
        echo Failed to generate keystore
        exit /b 1
      )
      echo Keystore generated successfully
      echo.
    )
  )
)

if not defined ANDROID_SDK_ROOT (
  if exist local.properties (
    for /f "usebackq tokens=1* delims==" %%A in ("local.properties") do (
      if /i "%%A"=="sdk.dir" set "ANDROID_SDK_ROOT=%%B"
    )
  )
)

if not defined ANDROID_SDK_ROOT (
  echo ANDROID_SDK_ROOT is not set and local.properties does not contain sdk.dir
  exit /b 1
)

rem Normalize sdk.dir paths (e.g. C\:\\Users\\... -^> C:\Users\...)
set "ANDROID_SDK_ROOT=!ANDROID_SDK_ROOT:\:=:!"
set "ANDROID_SDK_ROOT=!ANDROID_SDK_ROOT:\\=\!"

if not exist "!ANDROID_SDK_ROOT!" (
  echo SDK path does not exist: !ANDROID_SDK_ROOT!
  exit /b 1
)

set "BUILD_TOOLS_DIR=!ANDROID_SDK_ROOT!\build-tools"
if not exist "!BUILD_TOOLS_DIR!" (
  echo Build-tools directory not found under !ANDROID_SDK_ROOT!
  exit /b 1
)

rem Find the latest build-tools version
set "LATEST="
for /f "delims=" %%V in ('dir /b /ad "!BUILD_TOOLS_DIR!" 2^>nul ^| sort /r') do (
  set "LATEST=%%V"
  goto :found
)

:found
if "!LATEST!"=="" (
  echo No build-tools versions found under !BUILD_TOOLS_DIR!
  exit /b 1
)

set "APKSIGNER=!BUILD_TOOLS_DIR!\!LATEST!\apksigner.bat"
if not exist "!APKSIGNER!" (
  echo apksigner not found at: !APKSIGNER!
  exit /b 1
)

echo Using: !APKSIGNER!
echo Signing: !UNSIGNED_APK!

"!APKSIGNER!" sign --ks "!KEYSTORE_PATH!" --ks-key-alias "!KEY_ALIAS!" --out "!OUT_APK!" "!UNSIGNED_APK!"
if errorlevel 1 (
  echo Signing failed
  exit /b 1
)

echo.
echo Signed APK created: !OUT_APK!
