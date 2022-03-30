#!/bin/bash

# Recipe for Mozilla Common Voice corpus v1
#
# Copyright 2017   Ewald Enzinger
# Apache 2.0

data=/data
jobs=3
lm_name="lm_vaudimus_small.arpa.gz"

. ./cmd.sh
. ./path.sh

stage=-1

. ./utils/parse_options.sh

set -euo pipefail

if [ $stage -le -2 ]; then
  #mkdir -p $data
  #local/download_and_untar.sh $(dirname $data) $data_url

  #### Diego
  #python3 local/download_file.py $data consulta_31_05_2020-06_06_2020.csv $data/clips/radios
  #python3 local/data_split.py $data validated.csv consulta_31_05_2020-06_06_2020.csv $data/clips/radios
  #python3 $HOME/kaldi/global_pt_data/preprocess/data_to_all.py $HOME/kaldi/global_pt_data/ all.csv

  mv $data/sample_metadata_train_final.csv $data/cv-valid-train.csv
  mv $data/sample_metadata_dev_final.csv $data/cv-valid-test.csv
fi

if [ $stage -le -1 ]; then
  for part in valid-train valid-test; do
    # use underscore-separated names clearin data directories.
    local/data_prep.pl $data cv-$part data/$(echo $part | tr - _)
  done

  ##FalaBrasil
  local/prepare_lm.sh
  # Prepare the lexicon and various phone lists
  # Pronunciations for OOV words are obtained using a pre-trained Sequitur model

  local/prepare_dict.sh
fi

if [ $stage -le 0 ]; then
  ## Prepare data/lang and data/local/lang directories
  utils/prepare_lang.sh data/local/dict \
    '<unk>' data/local/lang data/lang || exit 1
 
  utils/format_lm.sh data/lang /models/$lm_name data/local/dict/lexicon.txt data/lang_test/  
fi

wait
exit 1

if [ $stage -le 1 ]; then
  mfccdir=mfcc
  # spread the mfccs over various machines, as this data-set is quite large.
  #if [[  $(hostname -f) ==  *.clsp.jhu.edu ]]; then
  #  mfcc=$(basename mfccdir) # in case was absolute pathname (unlikely), get basename.
  #  utils/create_split_dir.pl /export/b{07,14,16,17}/$USER/kaldi-data/mfcc/commonvoice/s5/$mfcc/storage \
  #    $mfccdir/storage
  #fi

  for part in valid_train valid_test; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $jobs data/$part exp/make_mfcc/$part $mfccdir
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
  done

  # Get the shortest 250 utterances first because those are more likely
  # to have accurate alignments.
  #utils/subset_data_dir.sh --shortest data/valid_train 27800 data/train_27kshort || exit 1;
  #utils/subset_data_dir.sh data/valid_train 18200 data/train_20k || exit 1;
  #utils/subset_data_dir.sh data/valid_train 20000 data/train_20k || exit 1;
fi

if [ $stage -le 2 ]; then
  mfccdir=mfcc

  # Get the shortest 27000 utterances first because those are more likely
  # to have accurate alignments.
  utils/subset_data_dir.sh --shortest data/valid_train 60316 data/train_60kshort || exit 1;
fi

# train a monophone system
if [ $stage -le 3 ]; then
  steps/train_mono.sh --boost-silence 1.25 --nj $jobs --cmd "$train_cmd" \
    data/train_60kshort data/lang exp/mono || exit 1;
  (
    utils/mkgraph.sh data/lang_test exp/mono exp/mono/graph
    for testset in valid_test; do
      steps/decode.sh --nj $jobs --cmd "$decode_cmd" exp/mono/graph \
        data/$testset exp/mono/decode_$testset
      #steps/decode.sh --nj 2 exp/mono/graph data/$testset exp/mono/decode_$testset
    done
  )&
  steps/align_si.sh --boost-silence 1.25 --nj $jobs --cmd "$train_cmd" \
    data/train data/lang exp/mono exp/mono_ali_train
fi

# 57  60316
# 67.17 totgauss=1000 # Target #Gaussians.

# train a first delta + delta-delta triphone system
if [ $stage -le 4 ]; then
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/valid_train data/lang exp/mono exp/tri1

  # decode using the tri1 model
  (
    utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph
    for testset in valid_test; do
      steps/decode.sh --nj $jobs --cmd "$decode_cmd" exp/tri1/graph \
        data/$testset exp/tri1/decode_$testset
      #steps/decode.sh --nj 2 exp/tri1/graph data/$testset exp/tri1/decode_$testset
    done
  )&

  steps/align_si.sh --nj $jobs --cmd "$train_cmd" \
    data/train_60k data/lang exp/tri1 exp/tri1_ali_train_60k
fi
 
# 56.38 03/03/2021
# 59.23 num_iters=35 2000 10000

# train an LDA+MLLT system.
if [ $stage -le 5 ]; then
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    data/train_60kshort data/lang exp/tri1 exp/tri2b
  #2500 15000

  #steps/train_lda_mllt.sh --cmd "$train_cmd" \
  #  --splice-opts "--left-context=3 --right-context=3" 250 1500 \
  #  data/train_20k data/lang exp/tri1_ali_train_20k exp/tri2b  

  # decode using the LDA+MLLT model
  utils/mkgraph.sh data/lang_test exp/tri2b exp/tri2b/graph
  (
    for testset in valid_test; do
      steps/decode.sh --nj $jobs --cmd "$decode_cmd" exp/tri2b/graph \
        data/$testset exp/tri2b/decode_$testset
      #steps/decode.sh --nj 2 exp/tri2b/graph data/$testset exp/tri2b/decode_$testset
    done
  )&

  # Align utts using the tri2b model
  steps/align_si.sh --nj $jobs --cmd "$train_cmd" --use-graphs true \
    data/train_60kshort data/lang exp/tri2b exp/tri2b_ali_train_60k
fi

# Train tri3b, which is LDA+MLLT+SAT
if [ $stage -le 6 ]; then
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    data/train_60kshort data/lang exp/tri2b_ali_train_60k exp/tri3b

  #2500 15000

  #steps/train_sat.sh 250 1500 \
  #  data/train_20k data/lang exp/ttri3b_ali_valid_trainri2b_ali_train_20k exp/tri3b

  # decode using the tri3b model
  (
    utils/mkgraph.sh data/lang_test exp/tri3b exp/tri3b/graph
    for testset in valid_test; do
      steps/decode_fmllr.sh --nj $jobs --cmd "$decode_cmd" \
        exp/tri3b/graph data/$teststri3b_ali_train_60k exp/tri3b/decode_$testset
      #steps/decode_fmllr.sh --nj 2 exp/tri3b/graph data/$testset exp/tri3b/decode_$testset
    done
  )&
fi

if [ $stage -le 7 ]; then
  # Align utts in the full training set using the tri3b model
  steps/align_fmllr.sh --nj $jobs --cmd "$train_cmd" \
    data/valid_train data/lang \
    exp/tri3b exp/tri3b_ali_valid_train

  # train another LDA+MLLT+SAT system on the entire training set
  steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
    data/valid_train data/lang \
    exp/tri3b_ali_valid_train exp/tri4b

  #steps/train_sat.sh 420 4000 data/valid_train data/lang exp/tri3b_ali_valid_train exp/tri4b

  # decode using the tri4b model
  (
    utils/mkgraph.sh data/lang_test exp/tri4b exp/tri4b/graph
    for testset in valid_test; do
      steps/decode_fmllr.sh --nj $jobs --cmd "$decode_cmd" \
        exp/tri4b/graph data/$testset \
        exp/tri4b/decode_$testset
      #steps/decode_fmllr.sh --nj 2 exp/tri4b/graph data/$testset exp/tri4b/decode_$testset
    done
  )&
fi

# 39 13/03/8

if [ $stage -le 8 ]; then
  for part in valid_train valid_test; do
    utils/data/fix_data_dir.sh data/$part
  done
fi

# Train a chain model
if [ $stage -le 9 ]; then
  local/chain/run_tdnn.sh --stage 0
fi

# Don't finish until all background decoding jobs are finished.
wait
