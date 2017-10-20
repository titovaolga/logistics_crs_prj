if "%PG_DATA_DISK%"=="" set "PG_DATA_DISK=C:"
echo Working with database on disk %PG_DATA_DISK%

set PGPORT=5439
set PGHOST=localhost
set PGUSER=postgres
set PGPASSWORD=postgres
set PG_DATADIR=%PG_DATA_DISK%/logistic_Database/pgsql_data
set PG_DATADIR_WIN=%PG_DATA_DISK%\logistic_Database\pgsql_data
set PG_DATADIR_ROOT=%PG_DATA_DISK%\logistic_Database
set PG_DB=logistic
set PGBIN=%~dp0..\..\Foreign\PostgreSQL\bin
set PG_CONNECTION_STRING=dbname='%PG_DB%' host=%PGHOST% port=%PGPORT% user='%PGUSER%' password='%PGPASSWORD%'
