use strict;

use Chart::Magick;
use Chart::Magick::Palette;

=head1 custom_palette.pl

Shows how to pass a custom palette to a Chart::Magick chart.

=cut

# Create some datasets
my $dsx     = [ 1 .. 5 ];
my $dsy     = [ map { 4  + rand 2 } @$dsx   ];
my $dsy2    = [ map { $_ + rand 1 } @$dsy   ];
my $dsy3    = [ map { 10 - $_     } @$dsy2  ];

# Draw the Chart
my $chart = Chart::Magick->bar( 
    width   => 600,
    height  => 300,
    data    => [ 
        [ $dsx, $dsy,  'Random prognosis'       ],
        [ $dsx, $dsy2, 'Adjusted prognosis'     ],
        [ $dsx, $dsy3, 'Projected deficiency'   ],
    ],
    palette => Chart::Magick::Palette->new( [
        { fillTriplet   => 'ff0000', fillAlpha => '77', strokeTriplet => 'ff0000', strokeAlpha => 'ff' },
        { fillTriplet   => '00ff00', fillAlpha => '77', strokeTriplet => '00ff00', strokeAlpha => 'ff' },
        { fillTriplet   => '0000ff', fillAlpha => '77', strokeTriplet => '0000ff', strokeAlpha => 'ff' },
    ] ),
);

#$chart->display;
$chart->write( 'custom_palette.png' );

