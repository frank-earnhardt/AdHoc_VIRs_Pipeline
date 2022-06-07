FROM ubuntu:18.04 AS base
LABEL maintainer="Frank Earnhardt <frank.earnhardt@outlook.com>"

RUN apt-get update \
    && apt-get upgrade -y \
       perl \
       curl

WORKDIR /opt

FROM base AS core
RUN apt-get update \
    && apt-get install -yq \
       build-essential \
       cpanminus \
       iputils-ping \
       apt-utils

FROM core AS build
RUN apt-get update \
    && apt-get install -y \
    curl
CMD /bin/bash

RUN cpanm Data::Dumper

FROM build AS run

COPY --from=build /usr/local /usr/local

COPY ./src_code/prepareVIRs.pl /opt/src_code/prepareVIRs.pl
#COPY ./src_data/vir_*.csv /opt/src_data/

ENTRYPOINT [ "perl", "/opt/src_code/prepareVIRs.pl" ]