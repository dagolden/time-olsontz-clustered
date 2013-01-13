#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use autodie;
use Path::Class;
use Sereal::Encoder qw/encode_sereal/;

my $infile = shift
  or die "Usage: $0 <file>";

my $outfile = $infile;
$outfile =~ s/\.dd$/.srl/;

my $data = do {
  no strict;
  eval file($infile)->slurp;
};
die $@ if $@;

file($outfile)->spew( encode_sereal($data) );

