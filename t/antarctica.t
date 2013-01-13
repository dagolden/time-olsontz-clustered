use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';
use Test::File::ShareDir -share =>
  { -dist => { 'Time-OlsonTZ-Clustered' => 'share' } };

use Time::OlsonTZ::Clustered qw/primary_zones/;

my %country = (
    label    => 'Antarctic',
    code     => 'AQ',
    name     => 'Antarctic',
    clusters => [
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
        {
            'description'   => 'Syowa Station, E Ongul I',
            'offset'        => '+3',
            'timezone_name' => 'Antarctica/Syowa'
        },
        {
            'description'   => 'Mawson Station, Holme Bay',
            'offset'        => '+5',
            'timezone_name' => 'Antarctica/Mawson'
        },
        {
            'description'   => 'Vostok Station, Lake Vostok',
            'offset'        => '+6',
            'timezone_name' => 'Antarctica/Vostok'
        },
        {
            'description'   => 'Davis Station, Vestfold Hills',
            'offset'        => '+7',
            'timezone_name' => 'Antarctica/Davis'
        },
        {
            'description'   => 'Casey Station, Bailey Peninsula',
            'offset'        => '+8',
            'timezone_name' => 'Antarctica/Casey'
        },
        {
            'description'   => 'Dumont-d\'Urville Station, Terre Adelie',
            'offset'        => '+10',
            'timezone_name' => 'Antarctica/DumontDUrville'
        },
        {
            'description'   => 'Macquarie Island Station, Macquarie Island',
            'offset'        => '+11',
            'timezone_name' => 'Antarctica/Macquarie'
        },
        {
            'description'   => 'McMurdo Station, Ross Island',
            'offset'        => '+12',
            'timezone_name' => 'Antarctica/McMurdo'
        },
    ],
);

cmp_deeply( primary_zones( $country{code} ),
    $country{clusters}, "primary_zones('AQ')" );

done_testing;
# COPYRIGHT
