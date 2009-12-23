use strict;

use Chart::Magick::Axis::None;
use Chart::Magick::Chart::Gauge;
use Chart::Magick;
use Chart::Magick::Data;

use Image::Magick;
#use IMSVG;

use Data::Dump qw( dd );


use constant pi => 3.14159265358979;

# Setup data
my $ds = Chart::Magick::Data->new;
#$ds->addDataset(
#    [ qw( 1 2 3 4 5 ) ],
#    [ qw( 1 3 5.9 3 0 ) ],
#);
$ds->addDataset(
    [ qw( 1 5  ) ],
    [ qw( 0 1 ) ],
);

# Setup axis
my $axis    = Chart::Magick::Axis::None->new( {
    width   => 400,
    height  => 400,
} );
$axis->im->Set('magick', 'SVG');


$axis->set( {
    margin          => 10,

    font            => '/usr/share/fonts/truetype/dustin/PenguinAttack.ttf',
    fontSize        => 15,
    fontColor       => 'black',

    # This overrides the default color set by fontColor.
    titleColor      => 'purple',
    title           => 'Gauge',

    background      => 'xc:grey40',
    chartBackground => 'xc:#ffffff70',
} );

# Setup chart
my $chart   = Chart::Magick::Chart::Gauge->new( { clockwise => 1, scaleRadius => 50, needleType => 'compass' } );
$chart->setData( $ds );

$axis->addChart( $chart );

# Set labels for the axis ticks
$axis->addLabels( { 1 => 'jan', 2 => 'feb', 3 => 'mrt', 4 => 'apr da\'s nou ook niet echt een hele lange naam toch?', 5 => 'eeennnn hele lange maand naam zoals bijvoorbeld zoiets als mei of misschien ook nog wel iets anders zeg maar' } );
$axis->draw;

dd $axis->get;
dd $axis->plotOption;


# Write graph

print "===", $axis->im->Set('format', 'gif');
$axis->im->Write('gauge.png');

#$axis->im->DumpStack;

