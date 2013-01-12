#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use autodie;
use DateTime::TimeZone::Olson
  qw/olson_canonical_names olson_country_selection olson_tz/;
use DateTime;
use DateTime::Format::Natural;
use Digest::MD5 qw/md5_hex/;
use List::AllUtils qw/min/;

my @dst_dates = DateTime->now;
for ( 1 .. 365 ) {
  push @dst_dates, $dst_dates[-1]->clone->add( days => 1 );
}

sub format_offset {
  my ($raw_offset) = @_;
  my $offset = sprintf( "%+f", $raw_offset / 3600 );
  $offset =~ s/\.0+$//;
  $offset =~ s/\.(.+?)0+$/.$1/;
  return $offset;
}

sub dst_digest {
  my ($tz) = @_;
  my @offsets = map {
    eval { $tz->offset_for_local_datetime($_) }
      // "?"
  } @dst_dates;
  return ( md5_hex(@offsets), min( grep { $_ ne "?" } @offsets ) );
}

my $countries = olson_country_selection;

my %cluster;

for my $code ( sort keys %$countries ) {
  my $country_name = $countries->{$code}{olson_name};
  my $regions      = $countries->{$code}{regions};
  my %digests;
  for my $desc ( keys %$regions ) {
    my $zone = $regions->{$desc}{timezone_name};
    next unless $zone;
    my $tz = olson_tz($zone);
    my ( $digest, $offset ) = dst_digest($tz);
    $digests{$digest} //= [];
    push $digests{$digest},
      {
      timezone_name     => $zone,
      olson_description => $desc,
      offset            => defined($offset) ? format_offset($offset) : '',
      };
  }
  $cluster{$code}{olson_name} = $country_name;
  for my $k ( sort { $digests{$a}[0]{offset} <=> $digests{$b}[0]{offset} } keys %digests ) {
    my $v = $digests{$k};
    push @{ $cluster{$code}{clusters} },
      {
      offset => $v->[0]{offset},
      zones  => [ map { my %z = %$_; delete $z{offset}; \%z } @$v ],
      };
  }
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
print Dumper( \%cluster );

warn "Countries: " . keys %cluster;
use Devel::Size qw/total_size/;
warn 'Cluster is ' . total_size(\%cluster);

use Sereal qw/encode_sereal/;
use Path::Class;
file("olson_cluster.srl")->spew(encode_sereal(\%cluster));
