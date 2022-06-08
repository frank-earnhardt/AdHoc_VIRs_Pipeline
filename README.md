PreReq 0: **Working git** \
--_win10_: https://git-scm.com/download/win \
--_macOS_: `brew install git` \
PreReq 1: **Working docker** \
--_win10_: https://docs.docker.com/desktop/windows/install \
--_macOS_: `brew cask install docker`
  
---
Step 0: `mkdir AdHoc` ~ Location doesn't matter \
Step 1: `cd AdHoc` \
Step 2: `git clone https://github.com/earnhardt3rd/AdHoc_VIRs_Pipeline.git` \
Step 3: `cd AdHoc_VIRs_Pipeline` \
Step 4: `cd container` ~ Record Path as <containerPath> \
Step 5: `docker build -t vir_report .` \
Setp 6: `docker run -it -v <containerPath>/src_data:/opt/src_data:/opt/src_data --rm vir_report`

---
--_win10_: `docker run -it -v c:\AdHoc\AdHoc_VIRs_Pipeline\container\src_data:/opt/src_data --rm vir_report -mcron` \
--_macOS_: `docker run -it -v /AdHoc/AdHoc_VIRs_Pipeline/container/src_data:/opt/src_data --rm vir_report -mcron`

---
 \
**See Report**: <containerPath>/src_data/virs_report.tsv
