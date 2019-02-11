#!/bin/sh


dd if=$1 of=/dev/null bs=1M count=10 skip=$RANDOM


