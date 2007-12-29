call "%VS71COMNTOOLS%\vsvars32.bat"

devenv %1 /useenv /build release

exit %ERRORLEVEL%
