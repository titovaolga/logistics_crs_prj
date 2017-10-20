call %~dp0\PGVARS.cmd

%PGBIN%\pg_ctl.exe register -D %PG_DATADIR% -N postgres
