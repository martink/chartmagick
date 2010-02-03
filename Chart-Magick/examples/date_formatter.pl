use strict;

use Chart::Magick;
use DateTime;

my $start = DateTime->now->set( hour => 0, minute => 0, second => 0 )->epoch;

# Create some datasets
my $dsx     = [ map { $start + 3600 * 24 * $_ } ( 0 .. 3 ) ];
my $dsy     = [ map { 4  + rand 2 } @$dsx   ];
my $dsy2    = [ map { $_ + rand 1 } @$dsy   ];
my $dsy3    = [ map { 10 - $_     } @$dsy2  ];

my $xFormatter = sub {
    my ( $axis, $value, $units ) = @_;

    return DateTime->from_epoch( epoch => $value )->ymd;
};


# Draw the Chart
Chart::Magick->bar( 
    width   => 600,
    height  => 300,
    data    => [ 
        [ $dsx, $dsy,  'Random prognosis'       ],
        [ $dsx, $dsy2, 'Adjusted prognosis'     ],
        [ $dsx, $dsy3, 'Projected deficiency'   ],
    ],
    axis    => {
        xLabelFormatter => sub { $xFormatter },
#        xLabelUnits     => 3600 * 24, # 1 day
    },
    legend  => {
        backgroundColor => 'none',
        position        => 'bottom center',
    },
)->write( 'date_formatter.png' );

