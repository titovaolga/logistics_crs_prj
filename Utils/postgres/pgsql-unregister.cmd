call %~dp0\PGVARS.cmd

%PGBIN%\pg_ctl.exe unregister -N postgres
