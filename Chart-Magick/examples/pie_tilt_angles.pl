use strict;
use warnings;

use Chart::Magick::Palette;
use Chart::Magick;

my $data = [
    [  1,  2, 3, 4, 5   ],
    [ 10, 25, 4, 12, 30 ],
];

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

my $matrix = Chart::Magick->matrix( 1000, 600, [
    [ @pies[ 0 .. 2 ] ],
    [ @pies[ 3 .. 5 ] ],
]);

$matrix->write( 'pie_tilt_angles.png' );

