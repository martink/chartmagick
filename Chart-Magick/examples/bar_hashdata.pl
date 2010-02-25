use strict;

use Chart::Magick;

# Draw the Chart
Chart::Magick->bar( 
    width   => 600,
    height  => 300,
    data    => [ 
        [ { 1 => 6, 2 => -3, 3 =>  2, 4 => 7  , 5 => 0 }, 'Dataset 1' ],
        [ { 1 => 3, 2 =>  2, 3 => -5, 4 => 0.3, 5 => 1 }, 'Dataset 2' ],
        [ { 1 => 7, 2 =>  6, 3 =>  9, 4 => 2.5, 5 => 2 }, 'Dataset 3' ],
    ],
    labels  => [
        { 1 => 'q1 2009', 2 => 'q2 2009', 3 => 'q3 2009', 4 => 'q4 2009', 5 => '2010' },
    ],
    legend  => {
        backgroundColor => 'none',
        position        => 'bottom center',
    },
)->write( 'bar_hashdata.png' );

