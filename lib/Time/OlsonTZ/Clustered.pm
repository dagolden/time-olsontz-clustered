use 5.008001;
use strict;
use warnings;

package Time::OlsonTZ::Clustered;
# ABSTRACT: Olson time zone clusters based on similar offset and DST changes
# VERSION

use Sub::Exporter -setup => {
    exports => [
        qw/find_cluster find_primary is_primary primary_zones timezone_clusters country_codes country_name/
    ]
};

use File::ShareDir::Tarball qw/dist_file/;
use Path::Class;
use Sereal::Encoder qw/encode_sereal/;
use Sereal::Decoder qw/decode_sereal/;

{
    my $clusters;
    my $reverse;

    sub _clusters {
        return $clusters if defined $clusters;
        my $file = dist_file( 'Time-OlsonTZ-Clustered', 'cluster.srl' )
          or die "Can't find cluster.srl in distribution share data";
        $clusters = decode_sereal( scalar file($file)->slurp );
    }

    sub _get_country {
        my ($code) = shift;
        my $cluster = _clusters()->{ uc $code };
        return $cluster ? decode_sereal( encode_sereal($cluster) ) : undef;
    }

    sub _reverse_map {
        return $reverse if defined $reverse;
        my $file = dist_file( 'Time-OlsonTZ-Clustered', 'reverse.srl' )
          or die "Can't find reverse.srl in distribution share data";
        $reverse = decode_sereal( scalar file($file)->slurp );
    }
}

#--------------------------------------------------------------------------#
# high level functions
#--------------------------------------------------------------------------#

=func primary_zones

    my $zones = primary_zones('US');

Takes a country code and returns a reference to an array of hash references.
Each element in the array represents one timezone cluster in the country.
The hash reference contains the following keys:

=for :list
* description: Description of the zone or the Olson country name if there only one cluster
* offset: UTC offset, expressed in hours ('+5', '-2')
* timezone_name: the primary Olson zone name for the cluster ('America/Chicago')

For example, here are some of the items returned from C<primary_zones('AQ')>:

    [
        {
            'description'   => 'Palmer Station, Anvers Island',
            'offset'        => -4,
            'timezone_name' => 'Antarctica/Palmer'
        },
        {
            'description'   => 'Rothera Station, Adelaide Island',
            'offset'        => -3,
            'timezone_name' => 'Antarctica/Rothera'
        },
        ...
    ]

The description may be the Olson description of the primary zone or it may be a
custom alternative that the author feels best describes the cluster.

Offsets given are the smallest offset observed during the year.  This should correspond
to the non-daylight savings time offset in zones that observe daylight savings time
for part of the year.

The primary zone is the best guess at the most common or recognizable Olson
name in the cluster; see the L</DESCRIPTION> section for details.

If an invalid country code is given, the function returns an empty array reference.

=cut

sub primary_zones {
    my ($code) = @_;

    my $country = _get_country($code)
      or return [];
    my $clusters     = $country->{clusters};
    my $order        = $country->{cluster_order};
    my $country_name = $country->{olson_name};

    my @zones;
    for my $c (@$order) {
        my $description = $clusters->{$c}{description};
        my $first       = $clusters->{$c}{zones}[0];
        my %primary     = (
            description => $description || $country_name,
            offset => $first->{offset},
            timezone_name => $first->{timezone_name},
        );
        push @zones, \%primary;
    }
    return \@zones;
}

=func find_primary

    my $primary = find_primary("America/Indiana/Indianapolis");
    # returns "America/New_York"

Given an Olson time zone name, returns the primary zone name for the cluster
containing the zone.  Returns undef or the empty list if the zone is
not recognized.

=cut

sub find_primary {
    my ($zone) = @_;
    my $cluster = find_cluster($zone)
      or return;
    return $cluster->{zones}[0]{timezone_name};
}

=func is_primary {

    if ( is_primary("America/Chicago") ) { ... }

A boolean function to check if a time zone is primary for its cluster.

=cut

sub is_primary {
    my ($zone) = @_;
    my $primary = find_primary($zone) || '';
    return $primary eq $zone;
}

#--------------------------------------------------------------------------#
# lower level functions
#--------------------------------------------------------------------------#

=func country_codes

    for my $cc ( country_codes() ) {
        ...
    }

Returns a sorted list of known country codes in the cluster
database.

=cut

sub country_codes {
    my @list = sort keys %{ _clusters() };
    return @list;
}

=func country_name

    my $name = country_name("US");

Returns the Olson country name (or an empty string)
for a given country code.  This duplicate information
available elsewhere and is provided her for convenience.

=cut

sub country_name {
    my ($code) = @_;
    my $country = _get_country($code)
      or return '';
    return $country->{olson_name} || '';
}

=func timezone_clusters

    for my $cluster ( @{ timezone_clusters('US') } ) {
        ...
    }

Given a country code, returns an array reference of raw cluster data for the
country (or an empty array reference if the country code is not found).

Each cluster is a hash reference with C<description> and C<zones>. The C<zones>
entry is an array reference of time zone hashes similar to that returned by
C<primary_zones>, but with C<olson_description> containing the the original
Olson description rather than C<description> for the cluster.  Note that for
single-cluster countries, the cluster description will be blank.

For example, C<timezone_clusters("US")> will return a data structure like this:

    [
        {
            'description' => 'Hawaii',
            'zones'       => [
                {
                    'offset'            => -10,
                    'olson_description' => 'Hawaii',
                    'timezone_name'     => 'Pacific/Honolulu'
                }
            ]
        },
        {
            'description' => 'Aleutian Islands',
            'zones'       => [
                {
                    'offset'            => -10,
                    'olson_description' => 'Aleutian Islands',
                    'timezone_name'     => 'America/Adak'
                }
            ]
        },
        {
            'description' => 'Alaska Time',
            'zones'       => [
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time',
                    'timezone_name'     => 'America/Anchorage'
                },
                {
                    'offset'            => -9,
                    'olson_description' => 'Alaska Time - west Alaska',
                    'timezone_name'     => 'America/Nome'
                },
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time - Alaska panhandle',
                    'timezone_name'     => 'America/Juneau'
                },
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time - Alaska panhandle neck',
                    'timezone_name'     => 'America/Yakutat'
                },
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time - southeast Alaska panhandle',
                    'timezone_name'     => 'America/Sitka'
                },
            ]
        },
        ...
    ]

=cut

sub timezone_clusters {
    my ($code) = @_;
    my $country = _get_country($code)
      or return [];
    my $clusters = $country->{clusters};
    my $order    = $country->{cluster_order};

    return [ map { $clusters->{$_} } @$order ];
}

=func find_cluster

    my $cluster = find_cluster("America/Indiana/Indianapolis");

Given an Olson time zone name, returns the cluster data structure
containing the time zone.  It returns undef or the empty list
if the time zone name is not recognized.

=cut

sub find_cluster {
    my ($zone) = @_;
    my $reverse = _reverse_map()->{$zone}
      or return;
    my ( $code, $digest ) = @$reverse;
    my $country = _get_country($code)
      or return;
    return $country->{clusters}{$digest};
}

1;

=for Pod::Coverage method_names_here

=head1 SYNOPSIS

    use Time::OlsonTZ::Clustered ':all';

    say $_->timezone_name for @{ primary_zones('US') };
    # Pacific/Honolulu
    # America/Adak
    # America/Anchorage
    # America/Los_Angeles
    # America/Metlakatla
    # America/Denver
    # America/Phoenix
    # America/Chicago
    # America/New_York

    say find_primary("America/Indiana/Indianapolis");
    # America/New_York

=head1 DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

=head1 USAGE

All functions are optionally exported using L<Sub::Exporter>.  See
individual function descriptions for details.

=head1 SEE ALSO

=for :list
* L<DateTime::TimeZone::Olson>

=head1 ACKNOWLEDGMENTS

The author would like to thank the following people for their help:

=for :list
* Andrew Main (ZEFRAM) for his time zone modules and advice on zone clustering heuristics.
* Breno Olivera (GARU) for his patient explanations and advice regarding Brazilian time zones.

Any errors are solely those of the author (or the upstream Olson database).

=cut

# vim: ts=4 sts=4 sw=4 et:
