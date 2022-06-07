FROM ubuntu:18.04 AS base
LABEL maintainer="Frank Earnhardt <frank.earnhardt@outlook.com>"

RUN apt-get update \
    && apt-get upgrade -y \
       perl

WORKDIR /opt

FROM base AS build
RUN apt-get update \
    && apt-get install -yq \
       build-essential \
       cpanminus \
       iputils-ping \
       apt-utils

RUN cpanm Data::Dumper

FROM base AS run

COPY --from=build /usr/local /usr/local

COPY ./src_code/prepareVIRs.pl /opt/src_code/prepareVIRs.pl
#COPY ./src_data/vir_*.csv /opt/src_data/

ENTRYPOINT [ "perl", "/opt/src_code/prepareVIRs.pl" ]