use strict;

use Chart::Magick::Axis::LogLin;
use Chart::Magick::Axis::LinLog;

use Chart::Magick::Chart::Line;
use Chart::Magick::Data;

use Image::Magick;
use Data::Dumper;

use constant pi => 3.14159265358979;

# Dataset
my $ds = Chart::Magick::Data->new;
$ds->addDataset(
#    [ qw( 48 210 520 800 1200 ) ],
    [ qw( 0.003 0.02 0.03 0.05 0.1 )],
    [ qw( 0.5 4.3 1 4 2 ) ],
);
#$ds->addDataset(
#    [ map { 0.1 * $_        } ( 1 .. 1000 ) ],
#    [ map { sqrt 0.1 * $_   } ( 1 .. 1000 ) ],
#);

# Chart
my $chart   = Chart::Magick::Chart::Line->new( );
$chart->setData( $ds );

# Axis
my $axis    = Chart::Magick::Axis::LinLog->new( {
    width           => 1000,
    height          => 600,
    title           => 'Logarithmic plot',
    xSubtickCount   => 9,
    ySubtickCount   => 9,
    xStart          => 0.04,
    xStop           => 0.678,
    yStart          => -1.54,
    yStop           => 4.89,
    xTitle          => '# Zonkers',
    yTitle          => 'Revenue',
   # xTickOffset     => 1,
   # yTickOffset     => 1,
    xExpandRange    => 0,
    yExpandRange    => 0,
} );
$axis->addChart( $chart );
$axis->draw;

# Write
$axis->im->Write('out.png');
