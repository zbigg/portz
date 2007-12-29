call %VS71COMNTOOLS%\vsvars32.bat

devenv /build Release /project %1

exit %ERRORLEVEL%
