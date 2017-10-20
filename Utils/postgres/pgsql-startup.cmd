call %~dp0\PGVARS.cmd

%PGBIN%\pg_ctl.exe -D %PG_DATADIR% -l %~dp0\pgsql.log -w start
