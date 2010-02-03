use strict;
use warnings;

use Chart::Magick;

# Simple dataset 
my $data = [
    [  1,  2,  3,  4,  5 ],
    [ 10, 25,  5, 12, 30 ],
];

# Create 6 different pies with different tilt angles
my @pies;
for ( 0 .. 5 ) {
    my $tilt = 15 * $_;

    push @pies, Chart::Magick->pie(
        data        => [ $data ],
        axis        => {
            title       => "Tilt angle = $tilt",
        },
        chart       => {
            tiltAngle   => $tilt,
        },
    );
}

# Put the pies in a matrix.
my $matrix = Chart::Magick->matrix( 1000, 600, [
    [ @pies[ 0 .. 2 ] ],
    [ @pies[ 3 .. 5 ] ],
]);

# And write the image to disk.
$matrix->write( 'pie_tilt_angles.png' );

