use strict;

use Chart::Magick;
use Math::Trig;

# fetch coords and values from dataset
my @coords = ( 1 .. 100 );
my @values = map { 1.5 + sin( pi * $_ / 10 ) } @coords;


my %config = ( 
    data    => [
        [ \@coords, \@values ]
    ],
);

# setup chart;

my $matrix = Chart::Magick->matrix( 750, 750, [ 
    [
        Chart::Magick->line( %config, axisType => 'Lin'     ),
        Chart::Magick->line( %config, axisType => 'Log'     ),
    ],
    [
        Chart::Magick->line( %config, axisType => 'LinLog'  ),
        Chart::Magick->line( %config, axisType => 'Polar'   ),
    ] 
] );


$matrix->draw;
$matrix->write('lin_axes.png');

