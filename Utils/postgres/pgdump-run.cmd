set PGPORT=5445
set PGHOST=localhost
set PGUSER=postgres
set PGPASSWORD=postgres
set PGDATABASE=Coverages

set PGBIN=%~dp0..\..\bin-ext\postgresql-win64-9.1.3-2\bin

"%PGBIN%\pg_dump"  --file=dump --format=d --schema-only --compress=0 --create   

