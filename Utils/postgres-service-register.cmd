@echo off


:setdbdisk
set PG_DATA_DISK=C:
if not "%PG_DATA_DISK%"=="" if not exist %PG_DATA_DISK% goto errdisk

:initdatabase
pushd %~dp0\postgres\
    call PGVARS.cmd
popd

if exist %PG_DATADIR% goto serverreg

pushd %~dp0\postgres\
    call pgsql-init.cmd
popd
if ERRORLEVEL 1 goto errcode
@echo INIT DATABASE OK

:serverreg
pushd %~dp0\postgres\
    call pgsql-register.cmd
popd
if ERRORLEVEL 1 goto errcode
@echo Postgres service registered

net start postgres
if ERRORLEVEL 1 goto errcode


goto end

:errdisk
echo Disk '%PG_DATA_DISK%' does not exist
goto usage

:usage
echo postgres-service-register.cmd local_disk_name
echo    where local_disk_name is a drive ('C:', 'D:', etc) to deploy NavDP_Database
goto end

:errcode
echo Errorcode %ERRORLEVEL%
goto end

:end

