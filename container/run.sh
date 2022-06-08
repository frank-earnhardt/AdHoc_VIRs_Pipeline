#!/bin/bash
CWD=$(pwd)
docker build -t vir_report .
docker run -v $CWD/src_data:/opt/src_data --rm vir_report -mcron 

ECHO LOCAL: $CWD/src_data/virs_report.tsv