#!/bin/bash

OUTPUT_NAME="kaldi_model_20220416"

ROOT=/root
KALDI_ROOT=$ROOT/kaldi
KALDI_PROJECT=$KALDI_ROOT/egs/commonvoice/s5

stage=0

cd $KALDI_PROJECT

set -euo pipefail


if [ $stage -le 0 ]; then
  model_dir=/models/$OUTPUT_NAME
  mkdir $model_dir

  # conf
  mkdir $model_dir/conf

  cp $KALDI_PROJECT/conf/mfcc.conf $model_dir/conf/mfcc.conf
  cp $KALDI_PROJECT/conf/online_cmvn.conf $model_dir/conf/online_cmvn.conf

  cp $KALDI_PROJECT/conf/decode.config $model_dir/conf/decode.config
  cp $KALDI_PROJECT/conf/mfcc_hires.conf $model_dir/conf/mfcc_hires.conf
  
  # ivectors_test_hires
  mkdir $model_dir/ivectors_test_hires
  mkdir $model_dir/ivectors_test_hires/conf

  cp $KALDI_PROJECT/conf/* $model_dir/ivectors_test_hires/conf/
  cp $KALDI_PROJECT/exp/chain/tdnn1a_sp_online/conf/splice.conf $model_dir/ivectors_test_hires/conf/splice.conf

  # data
  mkdir $model_dir/data
  mkdir $model_dir/data/lang
  mkdir $model_dir/data/local

  cp -r $KALDI_PROJECT/local/* $model_dir/data/local/
  cp -r $KALDI_PROJECT/data/lang/* $model_dir/data/lang/
  
  # extractor
  mkdir $model_dir/extractor

  cp $KALDI_PROJECT/exp/chain/tdnn1a_sp_online/ivector_extractor/* $model_dir/extractor/

  # model
  mkdir $model_dir/model

  mkdir $model_dir/model/graph
  cp -r $KALDI_PROJECT/exp/chain/tree_sp/graph/* $model_dir/model/graph/

  cp $KALDI_PROJECT/exp/chain/tdnn1a_sp/tree $model_dir/model/tree
  cp $KALDI_PROJECT/exp/chain/tdnn1a_sp/final.mdl $model_dir/model/final.mdl
  cp $KALDI_PROJECT/exp/chain/tdnn1a_sp/cmvn_opts $model_dir/model/cmvn_opts
  cp $KALDI_PROJECT/exp/chain/tdnn1a_sp/den.fst $model_dir/model/den.fst
  cp $KALDI_PROJECT/exp/chain/tdnn1a_sp/normalization.fst $model_dir/model/normalization.fst



  echo "***** Files copied"

  tar -czvf "${OUTPUT_NAME}.tar.gz" $model_dir/
  mv "${OUTPUT_NAME}.tar.gz" /models/

  echo "***** Files compressed"

fi
