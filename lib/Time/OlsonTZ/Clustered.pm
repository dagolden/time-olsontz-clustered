use 5.008001;
use strict;
use warnings;

package Time::OlsonTZ::Clustered;
# ABSTRACT: Olson time zone clusters based on similar offset and DST changes
# VERSION

use Sub::Exporter -setup =>
  { exports => [qw/find_cluster find_primary is_primary primary_zones/] };

use File::ShareDir::Tarball qw/dist_file/;
use Path::Class;
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

    sub _reverse_map {
        return $reverse if defined $reverse;
        my $file = dist_file( 'Time-OlsonTZ-Clustered', 'reverse.srl' )
          or die "Can't find reverse.srl in distribution share data";
        $reverse = decode_sereal( scalar file($file)->slurp );
    }
}

#--------------------------------------------------------------------------#
# Functions operating on zones
#--------------------------------------------------------------------------#

sub find_cluster {
    my ($zone) = @_;
    my $reverse = _reverse_map()->{$zone}
      or return;
    my ( $code, $digest ) = @$reverse;
    my $country = _clusters()->{$code}
      or return;
    return $country->{clusters}{$digest};
}

sub find_primary {
    my ($zone) = @_;
    my $cluster = find_cluster($zone)
      or return;
    return $cluster->{zones}[0]{timezone_name};
}

sub is_primary {
    my ($zone) = @_;
    my $primary = find_primary($zone) || '';
    return $primary eq $zone;
}

#--------------------------------------------------------------------------#
# Functions operating on country codes
#--------------------------------------------------------------------------#

sub primary_zones {
    my ($code) = @_;

    my $country = _clusters()->{$code}
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

1;

=for Pod::Coverage method_names_here

=head1 SYNOPSIS

  use Time::OlsonTZ::Clustered;

=head1 DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

=head1 USAGE

Good luck!

=head1 SEE ALSO

Maybe other modules do related things.

=cut

# vim: ts=4 sts=4 sw=4 et:
