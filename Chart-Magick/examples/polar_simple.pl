use strict;
use warnings;

use Chart::Magick;

my $data = [
    [ 0 .. 300 ],
    [ 0 .. 300 ],
];

my @charts;
for ( 1 .. 4 ) {
    my $x_stop = 300 / $_;
    push @charts, Chart::Magick->line(
        width       => 300,
        height      => 300,
        axisType    => 'Polar',
        data        => [ $data ],
        axis        => {
            xStop   => $x_stop,
            title   => "xStop = $x_stop",
        },
    );
}

my $matrix = Chart::Magick->matrix( 600, 600, [ [ @charts[ 0 .. 1 ] ], [ @charts[ 2 .. 3 ] ] ]);
$matrix->write( 'polar_simple.png' );

