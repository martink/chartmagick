use strict;

use Chart::Magick;

# Create some datasets
my $dsx     = [ 1 .. 5 ];
my $dsy     = [ map { 4  + rand 2 } @$dsx   ];
my $dsy2    = [ map { $_ + rand 1 } @$dsy   ];
my $dsy3    = [ map { 10 - $_     } @$dsy2  ];

# Draw the Chart
Chart::Magick->bar( 
    width   => 600,
    height  => 300,
    data    => [ 
        [ $dsx, $dsy,  'Random prognosis'       ],
        [ $dsx, $dsy2, 'Adjusted prognosis'     ],
        [ $dsx, $dsy3, 'Projected deficiency'   ],
    ],
    labels  => [
        { 1 => 'q1 2009', 2 => 'q2 2009', 3 => 'q3 2009', 4 => 'q4 2009', 5 => '2010' },
    ],
    legend  => {
        backgroundColor => 'none',
        position        => 'bottom center',
    },
)->write( 'bar_simple.png' );

