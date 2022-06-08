@ECHO OFF
docker build -t vir_report .
docker run -v %~dp0\src_data:/opt/src_data --rm vir_report -mcron