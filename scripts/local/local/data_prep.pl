#!/usr/bin/perl
#
# Copyright 2017   Ewald Enzinger
# Apache 2.0
#
# Usage: data_prep.pl /export/data/cv_corpus_v1/cv-valid-train valid_train

use utf8;
use open qw(:std :utf8);

if (@ARGV != 3) {
  print STDERR "Usage: $0 <path-to-commonvoice-corpus> <dataset> <valid-train|valid-dev|valid-test>\n";
  print STDERR "e.g. $0 /export/data/cv_corpus_v1 cv-valid-train valid-train\n";
  exit(1);
}

($db_base, $dataset, $out_dir) = @ARGV;
mkdir data unless -d data;
mkdir $out_dir unless -d $out_dir;

print "$db_base/$dataset.csv \n";

open(CSV, "<", "$db_base/$dataset.csv") or die "cannot open dataset TSV file $db_base/$dataset.csv";
open(SPKR,">", "$out_dir/utt2spk") or die "Could not open the output file $out_dir/utt2spk";
open(GNDR,">", "$out_dir/utt2gender") or die "Could not open the output file $out_dir/utt2gender";
open(TEXT,">", "$out_dir/text") or die "Could not open the output file $out_dir/text";
open(WAV,">", "$out_dir/wav.scp") or die "Could not open the output file $out_dir/wav.scp";

my $header = <CSV>;
while(<CSV>) {
  chomp;
  ($file_path, $task, $variety, $dataset, $accent, $speech_genre, $speech_style, $up_votes, $down_votes, $votes_for_hesitation, $votes_for_filled_pause, $votes_for_noise_or_low_voice, $votes_for_second_voice, $votes_for_no_identified_problem, $text) = split(",", $_);

  #if ("$gender" eq "female") {
  #  $gender = "f";
  #} else {
    # Use male as default if not provided (no reason, just adopting the same default as in voxforge)
  #  $gender = "m";
  #}
  $gender = "m";

  $uttId = $file_path;
  $uttId =~ s/dev\///g;
  $uttId =~ s/train\///g;
  $uttId =~ s/\.wav//g;
  $uttId =~ s/\.mp3//g;
  $uttId =~ s/\.mp4//g;
  $uttId =~ s/\//33/g;
  $uttId =~ s/\_//g;
  # No speaker information is provided, so we treat each utterance as coming from a different speaker
  $spkr = $uttId;

  print TEXT "$uttId"," ","$text","\n";
  print GNDR "$uttId"," ","$gender","\n";
  print WAV "$uttId"," ffmpeg -y -i $db_base/$file_path -ar 16000 -ac 1 -f wav - | sox -t wav - -t wav - |\n";
  print SPKR "$uttId"," $spkr","\n";
   
}

close(SPKR) || die;
close(TEXT) || die;
close(WAV) || die;
close(GNDR) || die;
close(WAVLIST);

if (system(
  "utils/utt2spk_to_spk2utt.pl $out_dir/utt2spk >$out_dir/spk2utt") != 0) {
  die "Error creating spk2utt file in directory $out_dir";
}
system("env LC_COLLATE=C utils/fix_data_dir.sh $out_dir");
if (system("env LC_COLLATE=C utils/validate_data_dir.sh --no-feats $out_dir") != 0) {
  die "Error validating directory $out_dir";
}
