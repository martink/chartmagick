use strict;

use Chart::Magick::Axis::LinLog;
use Chart::Magick::Chart::Line;
use Chart::Magick::Data;

use Image::Magick;
use Data::Dumper;

use constant pi => 3.14159265358979;

# Dataset
my $ds = Chart::Magick::Data->new;
$ds->addDataset(
    [ qw( 50 210 520 800 1200 ) ],
    [ qw( 0.5 5 1 4 2 ) ],
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
    xTitle          => '# Zonkers',
    yTitle          => 'Revenue',
} );
$axis->addChart( $chart );
$axis->draw;

# Write
$axis->im->Write('out.png');
