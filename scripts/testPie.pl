use strict;

use Chart::Magick::Palette;
use Chart::Magick;

use Data::Dumper;

use constant pi => 3.14159265358979;

my $data = [
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 1 3 5.9 3 2 ) ],
];

my $data2 = [
    [ qw( 1 2 3 4 ) ],
    [ qw( 1.5 1 3 1 ) ],
];

my $data3 = [ [ 1, 2 ], [ 90, 270 ] ];

my $palette = Chart::Magick::Palette->new( [
    {fillTriplet    => 'ff0000' },
    {fillTriplet    => '00ff00' },
    {fillTriplet    => '0000ff' },
    {fillTriplet    => 'ff00ff' },
    {fillTriplet    => 'ffff00' },
] );    



my @rows;
for ( 0 .. 7 ) {
    print "\n\n\nPie $_\n\n";

    push @{ $rows[ int $_ / 4] }, Chart::Magick->pie( 
        chart   => {
            tiltAngle       => 15 * $_,
            stickLength     => 10,
            startAngle      => 0,
#            explosionLength => 10,
            explosionWidth  => 5,
#            pieMode        => 'stepped',

#           scaleFactor => 2,
#            radius      => 100,
        },
        data    => [ $data2 ],
        palette => $palette,
        labels  => [ { 1 => 'jan', 2 => 'feb', 3 => 'mrt', 4 => 'apr', 5 => 'mei' } ],
    );
    
}

my $matrix = Chart::Magick->matrix( 1200, 600, [ @rows ] );
$matrix->draw;
$matrix->write('pie.png');

