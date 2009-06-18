use strict;

use Chart::Magick::Axis::Lin;
use Chart::Magick::Axis::LinLog;
use Chart::Magick::Chart::Line;
use Chart::Magick::Chart::Bar;
use Chart::Magick::Chart::Pie;
use Chart::Magick;
use Image::Magick;
use Data::Dumper;

my @ds1 = (
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 1 3 6 3 2 ) ],
);
my @ds2 = (
    [ qw( 1 10 100 1000 10000 ) ],
    [ qw( 5 2 -1 8 3 ) ],
);
my @ds3 = (
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 7 -4 6 1 9 ) ],
);
my @ds4 = (
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 0.5 5 1 4 2 ) ],
);

use constant pi => 3.14159265358979;

my $pxCount = 1000;
my $dsx = [ map { pi / $pxCount * $_          } (0..$pxCount) ];
my $dsy = [ map { 1.1 + sin( 50*$_ ) + sin( 61*$_ )   } @{ $dsx } ];
my @ds5 = (
    $dsx,
    $dsy,
);
    

# Set up chart objects
my $pieChart = Chart::Magick::Chart::Pie->new();
$pieChart->dataset->addDataset( @ds1 );
$pieChart->set('tiltAngle', 80);
$pieChart->set('stickLength', 30);

my $barChart = Chart::Magick::Chart::Bar->new( );
$barChart->dataset->addDataset( @ds1 );
$barChart->dataset->addDataset( @ds3 );
$barChart->dataset->addDataset( @ds4 );
$barChart->set('barWidth',     10);
$barChart->set('barSpacing',   3);
#$barChart->set('drawMode',     'stacked');

my $logChart = Chart::Magick::Chart::Line->new( );
$logChart->dataset->addDataset( @ds2 );

my $lineChart = Chart::Magick::Chart::Line->new();
$lineChart->dataset->addDataset( @ds4 );
$lineChart->dataset->addDataset( @ds3 );

my $lineChart1 = Chart::Magick::Chart::Line->new();
$lineChart1->dataset->addDataset( @ds5 );

my $canvas = Chart::Magick->new( 800, 600 );
$canvas->matrix( 2, 2, { 1 => 'Chart::Magick::Axis::LinLog', 3 => 'Chart::Magick::Axis' } );

# First chart
my $axis = $canvas->getAxis( 0 );
$axis->addChart( $lineChart1 );
$axis->set('xSubtickCount', 0);
$axis->set('title', 'Bars');
my $config = $axis->get;
$axis->set('xLabelUnits', pi);

# Second chart
$axis = $canvas->getAxis( 1 );
$axis->addChart( $logChart );
$axis->set('ySubtickCount', 2);
$axis->set('title', 'Logarithmic plot');

# Third chart
$axis = $canvas->getAxis( 2 );
$axis->addChart( $barChart );
$axis->addChart( $lineChart );
$axis->set('xTickOffset', 1);
#$axis->set('title', 'Multiple chart types on one axis');
$axis->set( $config );

# Fourth chart
$axis = $canvas->getAxis( 3 );
$axis->addChart( $pieChart );
$axis->addLabels( { 1 => 'aaa', 2 => 'bbb', 3 => 'ccc', 4 => 'ddd', 5 => 'eee' } );
$axis->set('xSubtickCount', 0);
$axis->set('yChartOffset', 40);
$axis->set('xChartOffset', 40);
$axis->set('title', 'Pie!');

#$canvas->addAxis( $axis, 100, 100 );
$canvas->draw;


#for (1..10) {
#    my $fx = 0;
#    my $tx = 400;
#    my $y = 20;#*$_;
#    $axis->im->Draw(
#        'primitive'     => 'Path',
#        'stroke'        => 'red',
##        'stroke-pattern' => [10,2],
#        'stroke-dashoffset' => '1',
#        'stroke-dasharray'  => ['10','5','4'],
#        'points'        => "M $fx,$y L $tx,$y",
#    );
#}

$canvas->im->Write('canvas.png');

print $barChart->dataset->dumpData;

#print join "\n" , $canvas->im->QueryFont;
