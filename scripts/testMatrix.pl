use strict;

use Chart::Magick::Chart::Line;
use Chart::Magick::Chart::Bar;
use Chart::Magick::Chart::Pie;
use Chart::Magick::Chart::Gauge;
use Chart::Magick;
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );

#my @ds1 = (
#    [ qw( 1 2 3 4 5 ) ],
#    [ qw( 1 3 6 3 2 ) ],
#);
my @ds1 = (
    [ qw( 1 2 3 4  ) ],
    [ qw( 1 1 3 1  ) ],
);
my @ds2 = (
    [ qw( 1 10 100 1000 9003 ) ],
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

my $pxCount = 100;
my $dsx = [ map { pi / $pxCount * $_  - 0.5 * pi      } (0..$pxCount) ];
my $dsx = [ map { pi / $pxCount * $_                  } (-$pxCount/2..$pxCount/2) ];
my $dsy = [ map { 1.1 + sin( 50*$_ ) + sin( 61*$_ )   } @{ $dsx } ];
my @ds5 = (
    $dsx,
    $dsy,
);



# Timekeeping
my $time = [ gettimeofday ];


my $matrix = Chart::Magick->matrix( 800, 750, [
    [ 'Lin' ],
    [ 'Lin', 'LinLog' ],
    [ 'None', 'None' ],
] );


# Set up chart objects
my $pieChart = Chart::Magick::Chart::Pie->new();
$pieChart->dataset->addDataset( @ds1 );
$pieChart->set(
    tiltAngle   => 70,
    startAngle  => -60,
    stickLength => 10,
    #tiltAngle   => 20,
    explosionLength=> 5,
    explosionWidth => 3,
    radius      => 90
);

my $gauge = Chart::Magick::Chart::Gauge->new();
$gauge->dataset->addDataset( @ds1 );


my $barChart = Chart::Magick::Chart::Bar->new( );
$barChart->addDataset( @ds1, '2008' );
$barChart->addDataset( @ds3, '2009' );
$barChart->addDataset( @ds4, '2010' );
$barChart->set(
    barWidth    => 10,
#    barSpacing  => 3,
    drawMode    => 'stacked',
);

my $logChart = Chart::Magick::Chart::Line->new( );
$logChart->dataset->addDataset( @ds2 );

my $lineChart = Chart::Magick::Chart::Line->new();
$lineChart->dataset->addDataset( @ds4 );
$lineChart->dataset->addDataset( @ds3 );

my $lineChart1 = Chart::Magick::Chart::Line->new();
$lineChart1->dataset->addDataset( @ds5 );

my $config = {
    margin          => 15,
};

# First chart
my $axis = $matrix->getAxis( 0, 0 );
$axis->addChart( $lineChart1 );
$axis->set( $config );
$axis->set(
    xSubtickCount   => 1, 
    title           => '1.1 + sin 50Θ + sin 61Θ',
    font            => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
    xLabelUnits     => pi,
    xLabelFormat    => '%.1fπ',
    xTitle          => 'Θ [rad]',
    yTitle          => 'power [W]',
    yLabelFormat    => '%.2f',
);




# Third chart
$axis = $matrix->getAxis( 1, 0 );
$axis->addChart( $barChart );
#$axis->addChart( $lineChart );
$axis->set( $config );
#$axis->set('xTickOffset', 1);
#$axis->set('xSubtickCount', 0);
$axis->set('xTitle', 'klazam!' );
$axis->addLabels( { 1 => 'q1', 2 => 'q2', 3 => 'q3', 4 => 'q4', 5 => 'overall' }, 1 );
$axis->legend->set( position => 'top center' );

# Second chart
$matrix->setWeight( 1, 1, 2 );
$axis = $matrix->getAxis( 1, 1 );
$axis->addChart( $logChart );
$axis->set( $config );
#$axis->set('ySubtickCount', 2);
$axis->set('title', 'Logarithmic plot');
$axis->addLabels( { 1 => 'q1', 2 => 'q2', 3 => 'q3', 4 => 'q4ehuewh euqwhdiwhd uheuhu', 5 => 'overall' }, 1 );

# Fourth chart
$axis = $matrix->getAxis( 2, 0 );
$axis->addChart( $pieChart );
$axis->addLabels( { 1 => 'aaa', 2 => 'bbb', 3 => 'ccc', 4 => 'ddd', 5 => 'eee' } );
$axis->set(
    title       =>  'Pie!',
    );

$axis = $matrix->getAxis( 2, 1 );
$axis->addChart( $gauge );
$axis->addLabels( { 1 => 'aaa', 2 => 'bbb', 3 => 'ccc', 4 => 'ddd', 5 => 'eee' } );
$axis->set('title', 'Gauge');


$matrix->draw;

# More timekeeping
my $runtime1 = tv_interval( $time );

$matrix->im->Write('matrix.png');

# More timekeeping
my $runtime = tv_interval( $time );

print "___>$runtime1<___\n";
print "___>$runtime<___\n";

