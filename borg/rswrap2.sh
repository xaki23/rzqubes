#!/bin/sh

exec qvm-run -a -p --user root srv-backup "rsync $5 $6 $7 $8 $9"

