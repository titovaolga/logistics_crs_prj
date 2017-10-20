call %~dp0\PGVARS.cmd

%PGBIN%\pgbench.exe -i -d "%PG_DB%" -C -j 12 -t 1000 -c 10  -s 100000
