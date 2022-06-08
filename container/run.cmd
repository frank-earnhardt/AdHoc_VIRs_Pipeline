@ECHO OFF
docker build -t vir_report .
docker run -v %~dp0\src_data:/opt/src_data --rm vir_report -mcron

ECHO Local: %~dp0\src_data\virs_report.csv