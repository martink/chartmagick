use strict;

use Chart::Magick::Axis::None;
use Chart::Magick::Chart::Pie;
use Chart::Magick::Palette;
use Chart::Magick;
use Chart::Magick::Data;

use Image::Magick;
use Data::Dumper;

use constant pi => 3.14159265358979;

my @data = (
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 1 3 5.9 3 2 ) ],
);

my @data2 = (
    [ qw( 1 2 3 4 ) ],
    [ qw( 1 1 3 1 ) ],
);

my @data3 = ( [ 1, 2 ], [ 90, 270 ] );
my $canvas = Chart::Magick->new( 1200, 600 );
$canvas->matrix( [ qw( None None None None ) ], [ qw( None None None None ) ] );

my $palette = Chart::Magick::Palette->new( [
    {fillTriplet    => 'ff0000' },
    {fillTriplet    => '00ff00' },
    {fillTriplet    => '0000ff' },
    {fillTriplet    => 'ff00ff' },
    {fillTriplet    => 'ffff00' },
] );    

for ( 0 .. 7 ) {
    print "\n\n\nPie $_\n\n";

    my $chart = Chart::Magick::Chart::Pie->new( { 
        tiltAngle       => 15 * $_,
        stickLength     => 10,
        #startAngle      => 315,
        #explosionLength => 20,
        explosionWidth  => 2,
    #   scaleFactor => 2,
#        radius      => 100,
    } );
    $chart->setPalette( $palette );
    $chart->addDataset( @data2 );

    my $axis = $canvas->getAxis( $_ );
    $axis->addChart( $chart );
    $axis->addLabels( { 1 => 'jan', 2 => 'feb', 3 => 'mrt', 4 => 'apr', 5 => 'mei' } );
}

$canvas->draw;

$canvas->im->Write('pie.png');

