# syntax=docker/dockerfile:1

FROM python:3.6 as python-support

# --- KALDI SUPPORT ---
FROM python-support AS kaldi-support

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        make \
        automake \
        autoconf \
        bzip2 \
        unzip \
        wget \
        sox \
        libtool \
        git \
        subversion \
        python2.7 \
        zlib1g-dev \
        ca-certificates \
        gfortran \
        patch \
        ffmpeg \
	vim && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/kaldi-asr/kaldi.git /root/kaldi #EOL
RUN cd /root/kaldi/tools && \
       ./extras/install_mkl.sh && \
       make -j $(nproc) && \
       cd /root/kaldi/src && \
       ./configure --shared && \
       make depend -j $(nproc) && \
       make -j $(nproc) && \
       rm -rf /root/kaldi/.git

# ---------------------
# ---------------------

FROM kaldi-support AS main-support

ENV KALDI_ROOT='/root/kaldi'
ENV LD_LIBRARY_PATH="$KALDI_ROOT/src/lib:$KALDI_ROOT/tools/openfst/lib:$KALDI_ROOT/tools/openfst-1.7.2/lib"

RUN cd /root
WORKDIR /root

# Kaldi
RUN cd /root/kaldi
WORKDIR /root/kaldi

RUN mkdir /root/kaldi/nlp-generator-master
COPY fb_nlplib.jar /root/kaldi/nlp-generator-master/

RUN python3 -m pip install --upgrade pip

COPY requirements.txt /root/

# Model paths
RUN mkdir /models && \
      mkdir /data

RUN cd /data
WORKDIR /data
RUN pip3 install -r /root/requirements.txt

RUN apt update -q && \
	apt install -y \
	swig \
	openjdk-11-jdk \
	dos2unix \
	unzip \
	tree

RUN cd /root
WORKDIR /root

RUN mkdir scripts
COPY scripts/ /root/scripts/

RUN cp /root/scripts/install_sequitur.sh /root/kaldi/tools/install_sequitur.sh
RUN chmod +x /root/kaldi/tools/install_sequitur.sh
RUN cd /root/kaldi/tools
WORKDIR /root/kaldi/tools
RUN ["./install_sequitur.sh"]

# sudo permission
RUN apt-get update && \
      apt-get -y install sudo

RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

USER root

# Moving file to kaldi dir
RUN cd /root/kaldi/egs/commonvoice/s5
WORKDIR /root/kaldi/egs/commonvoice/s5

RUN cp /root/scripts/cmd.sh .   

RUN mv run.sh run_old.sh
RUN cp /root/scripts/run.sh .
RUN chmod +x run.sh

RUN cd /root/kaldi/egs/commonvoice/s5/local
WORKDIR /root/kaldi/egs/commonvoice/s5/local

RUN mv data_prep.pl data_prep_old.pl
RUN mv prepare_dict.sh prepare_dict_old.sh
RUN mv prepare_lm.sh prepare_lm_old.sh

RUN cp /root/scripts/data_prep.pl .
RUN cp /root/scripts/prepare_dict.sh .
RUN cp /root/scripts/prepare_lm.sh .

RUN chmod +x prepare_dict.sh
RUN chmod +x prepare_lm.sh

RUN mv nnet3/run_ivector_common.sh nnet3/run_ivector_common_old.sh
RUN cp /root/scripts/run_ivector_common.sh nnet3/run_ivector_common.sh

RUN cd /root/kaldi/egs/commonvoice/s5/local/chain/tuning
WORKDIR /root/kaldi/egs/commonvoice/s5/local/chain/tuning

RUN mv run_tdnn_1a.sh run_tdnn_1a_old.sh
RUN cp /root/scripts/run_tdnn_1a.sh .

RUN chmod +x run_tdnn_1a.sh

#
RUN cd /root
WORKDIR /root
