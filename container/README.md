PreReq 0: Working git
PreReq 1: Working docker

Step 0: mkdir AdHoc ~ Location doesn't matter 
Step 1: cd AdHoc
Step 2: git clone https://github.com/earnhardt3rd/AdHoc_VIRs_Pipeline.git
Step 3: cd AdHoc_VIRs_Pipeline
Step 4: cd container ~ Record Path as <containerPath>
Step 5: docker build -t vir_report .
Setp 6: docker run -it -v <containerPath>/src_data:/opt/src_data --rm vir_report

See Report: <containerPath>/src_data/virs_report.tsv