use strict;

use Chart::Magick::Axis::Lin;
use Chart::Magick::Chart::Bar;
use Time::HiRes qw( gettimeofday tv_interval );

use Data::Dumper;

use constant pi => 3.14159265358979;

# Setup data
my @ds1 = (
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 1 3 5.9 3 2 ) ],
);
my @ds2 = (
    [ qw( 1 2 3 4 6 ) ],
    [ qw( 7 -4 6 1 9 ) ],
);
my @ds3 = (
    [ qw( 1 2 3 4 5 6 ) ],
    [ qw( 0.5 5 1 4 2 -2) ],
);

# Timekeeping
my $time = [ gettimeofday ];


# Setup axis
my $axis    = Chart::Magick::Axis::Lin->new( {
    width       => 1000,
    height      => 600,
    drawLegend  => 1,
} );
$axis->set( {
    margin          => 10,

    font            => '/usr/share/fonts/truetype/dustin/PenguinAttack.ttf',
    fontSize        => 15,
    fontColor       => 'black',

    # This overrides the default color set by fontColor.
    titleColor      => 'purple',
    title           => 'Een barretje om aan te borrelen?',
    xTitle          => 'kalabam!',
    yTitle          => 'zlomp!',

#    yTickWidth      => 2,
#    axesOutside     => 0,
    flipAxes        => 1,

    xTickOffset     => 0,
    ticksOutside    => 0,
    axisColor       => 'black',
} );

#$axis->set( xSubtickCount => 10, ySubtickCount => 5 );
# Setup chart
my $chart   = Chart::Magick::Chart::Bar->new( );
$chart->addDataset( @ds1, 'Data1' );
$chart->addDataset( @ds2, 'Data2' );
$chart->addDataset( @ds3, 'Data3' );
#$chart->setData( $ds );
#$chart->addDataset( [ 0 .. 100 ], [ map { rand( 100) - 50 } 1 .. 101 ] );

$chart->set(
#    'drawMode',     'cumulative',
#    'barSpacing' => 0,
);

# Add the bar graph to the axis
$axis->addChart( $chart );


# Set labels for the axis ticks
#$axis->addLabels( { 1 => 'jan', 2 => 'feb', 3 => 'mrt', 4 => 'apr da\'s nou ook niet echt een hele lange naam toch?', 5 => 'eeennnn hele lange maand naam zoals bijvoorbeld zoiets als mei of misschien ook nog wel iets anders zeg maar' } );

print "setup  : ", tv_interval( $time ), "s\n";
$time = [ gettimeofday ];

$axis->draw;

print "drawing: ", tv_interval( $time ), "s\n";
$time = [ gettimeofday ];


# Write graph
$axis->im->Write('out.png');
print "write  : ", tv_interval( $time ), "s\n";

