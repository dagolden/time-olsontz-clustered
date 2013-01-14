#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use autodie;
use Data::Dumper;
use DateTime::TimeZone::Olson qw/olson_country_selection olson_tz/;
use DateTime;
use Digest::MD5 qw/md5_hex/;
use List::AllUtils qw/min/;
use Path::Class;

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
my %reverse;

for my $code ( sort keys %$countries ) {
    my $country_name = $countries->{$code}{olson_name};
    my $regions      = $countries->{$code}{regions};

    # Cluster regions
    my %digests;
    for my $desc ( keys %$regions ) {
        my $zone = $regions->{$desc}{timezone_name};
        next unless $zone;
        my $tz = olson_tz($zone);
        my ( $digest, $offset ) = dst_digest($tz);
        $digests{$digest}{description} //= $desc;
        $digests{$digest}{zones} //= [];
        push $digests{$digest}{zones},
          {
            timezone_name     => $zone,
            olson_description => $desc,
            offset            => defined($offset) ? format_offset($offset) : '',
          };
        $reverse{$zone} = [ $code, $digest ];
    }

    # XXX should sort digest arrays based on current primary status and set description
    # based on cluster for primary zone -- i.e. try to keep

    # Assemble output for country
    $cluster{$code}{olson_name}    = $country_name;
    $cluster{$code}{clusters}      = \%digests;
    $cluster{$code}{cluster_order} = [
        sort {
            ( $digests{$a}{zones}[0]{offset} || 0 ) <=> ( $digests{$b}{zones}[0]{offset} || 0 )
              || $#{ $digests{$b}{zones} } <=> $#{ $digests{$a}{zones} }
        } keys %digests
    ];
}

$Data::Dumper::Sortkeys = 1;
file("olson_cluster.dd")->spew( Dumper( \%cluster ) );
file("olson_reverse.dd")->spew( Dumper( \%reverse ) );

