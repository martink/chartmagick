use strict;

use Chart::Magick::Axis::Lin;
use Chart::Magick::Axis::Polar;
use Chart::Magick::Axis::LinLog;
use Chart::Magick::Chart::Line;
use Chart::Magick::Chart::Bar;
use Chart::Magick::Chart::Pie;
use Chart::Magick;
use Chart::Magick::Data;

use Image::Magick;
use Data::Dumper;

use constant pi => 3.14159265358979;

# Setup data
my $ds = Chart::Magick::Data->new;
$ds->addDataset(
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 1 3 5.9 3 2 ) ],
);
$ds->addDataset(
    [ qw( 1 2 3 4 6 ) ],
    [ qw( 7 -4 6 1 9 ) ],
);
$ds->addDataset(
    [ qw( 1 2 3 4 5 6 ) ],
    [ qw( 0.5 5 1 4 2 -2) ],
);

for ( 1 .. -1 ) {
    $ds->addDataset(
        [ 1..5 ],
        [ map { rand( 10) - 5} 1..5 ],
    );
}

# Setup axis
my $axis    = Chart::Magick::Axis::Lin->new( {
    width   => 1000,
    height  => 600,
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

    xTickOffset     => 0,
    ticksOutside    => 0,
    axisColor       => 'black',
} );

#$axis->set( xSubtickCount => 10, ySubtickCount => 5 );
# Setup chart
my $chart   = Chart::Magick::Chart::Bar->new( );
#$chart->setData( $ds );
$chart->addDataset( [ 0 .. 100 ], [ map { rand( 100) - 50 } 1 .. 101 ] );

$chart->set(
#    'drawMode',     'cumulative',
#    'barSpacing' => 0,
);

# Add the bar graph to the axis
$axis->addChart( $chart );

# Set labels for the axis ticks
#$axis->addLabels( { 1 => 'jan', 2 => 'feb', 3 => 'mrt', 4 => 'apr da\'s nou ook niet echt een hele lange naam toch?', 5 => 'eeennnn hele lange maand naam zoals bijvoorbeld zoiets als mei of misschien ook nog wel iets anders zeg maar' } );
$axis->draw;

# Write graph
$axis->im->Write('out.png');

