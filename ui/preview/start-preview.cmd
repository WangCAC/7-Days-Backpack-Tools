@echo off
setlocal
set "UI_PREVIEW_ROOT=%~dp0..\.."
set "PATH=C:\Qt\6.9.3\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;%PATH%"
set "QT_QPA_PLATFORM="
if not exist "%UI_PREVIEW_ROOT%\build\UiPreview\compiled\ui-preview.exe" (
  echo UI preview is not built on this computer.
  pause
  exit /b 1
)
start "" "%UI_PREVIEW_ROOT%\build\UiPreview\compiled\ui-preview.exe"
endlocal
