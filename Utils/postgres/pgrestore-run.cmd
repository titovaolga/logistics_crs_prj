call %~dp0\PGVARS.cmd

set SRC=%1

%PGBIN%\pg_restore.exe --host %PGHOST% --port %PGPORT% --username %PGUSER% --dbname %PGDATABASE% --no-password  --verbose %SRC%
