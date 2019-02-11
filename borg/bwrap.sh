#!/bin/sh


exec qvm-run -a -p --user root srv-backup 'borg serve --restrict-to-path /backup --append-only'

