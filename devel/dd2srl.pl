#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use autodie;
use Path::Class;
use Sereal::Encoder qw/encode_sereal/;

unless (@ARGV) {
    die "Usage: $0 <file>";
}

for my $infile (@ARGV) {
    if ( !-r $infile ) {
        warn "$infile not found or not readable";
        next;
    }

    my $outfile = $infile;
    $outfile =~ s/\.dd$/.srl/;

    my $data = do {
        no strict;
        eval file($infile)->slurp;
    };
    die $@ if $@;

    say "Writing $outfile";
    file($outfile)->spew( encode_sereal($data) );
}

