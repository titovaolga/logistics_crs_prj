@echo off

net stop postgres

:setdbdisk
set PG_DATA_DISK=%1
if not "%PG_DATA_DISK%"=="" if not exist %PG_DATA_DISK% goto errdisk

:unregister
pushd %~dp0\postgres\
    call pgsql-unregister.cmd
popd
if ERRORLEVEL 1 goto errcode
@echo Postgres service unregistered

goto end

:errdisk
echo Disk '%PG_DATA_DISK%' does not exist
goto usage

:usage
echo run without arguments to stop the database from E: drive
echo or type necessary drive name: 'C:', 'D:', etc
goto end

:errcode
echo Errorcode %ERRORLEVEL%
goto end

:end

