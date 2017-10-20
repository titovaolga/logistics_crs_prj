call %~dp0\PGVARS.cmd

%PGBIN%\pg_ctl.exe -D %PG_DATADIR% -w -m f stop
