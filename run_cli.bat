@echo off
title PoolMesh DB - CLI Front End (Review III)
color 0B
cls
echo ======================================================================
echo    PoolMesh DB: Campus-to-City Carpooling System - Review III CLI
echo    Vellore Institute of Technology, Vellore
echo ======================================================================
echo.
cd /d "%~dp0PoolMesh_Final\app"
venv\Scripts\python.exe main.py
pause
