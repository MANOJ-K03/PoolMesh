@echo off
title PoolMesh Carpooling System - Review III Localhost Server
color 0A
cls
echo ======================================================================
echo    PoolMesh DB: Campus-to-City Carpooling System - Review III
echo    Vellore Institute of Technology, Vellore
echo    Manoj Kumar S (24BDE0052) ^| Manoj K (24BDE0147) ^| S M Nithin (24BDE0033)
echo ======================================================================
echo.
echo Starting Web Server on http://localhost:5000 ...
echo Connecting to Oracle XE 11g (localhost:1521/XE) ...
echo.

cd /d "%~dp0PoolMesh_Final\app"
start "" "http://localhost:5000"
venv\Scripts\python.exe web_app.py

pause
