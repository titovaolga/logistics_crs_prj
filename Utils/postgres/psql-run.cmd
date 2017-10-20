call %~dp0\PGVARS.cmd

"%PGBIN%\psql"  -d "%PG_DB%" -f %1

