call %~dp0\PGVARS.cmd

if exist %PG_DATADIR% goto end

:createdatadir
%PGBIN%\initdb.exe --locale="English_United States.1252" --encoding=UTF8 -D %PG_DATADIR%  -U %PGUSER%
if ERRORLEVEL 1 goto errcode
@echo initdb.exe ok

:createconnectionstring
set PG_CONFIG=%~dp0\pg_config.h

echo #pragma once > %PG_CONFIG%
echo static const char * vtd_db_connection_string = "%PG_CONNECTION_STRING%"; >> %PG_CONFIG%

echo connection_string = "%PG_CONNECTION_STRING%"; > %~dp0\pg_config.py
if ERRORLEVEL 1 goto errcode
@echo Connection string ok

:serverstart
%PGBIN%\pg_ctl.exe -D %PG_DATADIR% -l %~dp0\pgsql.log -w start
if ERRORLEVEL 1 goto errcode
@echo Server initial start ok

:createdatabase
rem this is an example of how to create a new db and spatially enable it using CREATE EXTENSION
rem make sure, that no any other PostgreSQL installed in OS. Otherwise CREATE EXTENSION could fail.

"%PGBIN%\psql"  -c "CREATE DATABASE %PG_DB% ENCODING 'UTF8'"

if ERRORLEVEL 1 goto errcode
@echo Database creation ok

:servershutdown
%PGBIN%\pg_ctl.exe -D %PG_DATADIR% stop
if ERRORLEVEL 1 goto errcode
@echo Server shutdown ok

:copyconf
if not exist %~dp0\postgresql.conf ( goto errcopyconf )
copy /y "%~dp0\postgresql.conf" "%PG_DATADIR_WIN%\postgresql.conf"
if ERRORLEVEL 1 goto errcode 
@echo postgresql.conf copy ok


goto end

:errcopyconf
echo PostgreSQL config file postgresql.conf is not found at: %~dp0\postgresql.conf
if ERRORLEVEL 1 goto errcode
goto end

:errcode
echo Errorcode %ERRORLEVEL%

:end
