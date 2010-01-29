use strict;

use Chart::Magick;
use Math::Trig;
use Time::HiRes qw( gettimeofday tv_interval );

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

#use constant pi => 3.14159265358979;

my $pxCount = 100;
my $dsx = [ map { pi / $pxCount * $_                  } (-$pxCount/2..$pxCount/2) ];
my $dsy = [ map { 1.1 + sin( 50*$_ ) + sin( 61*$_ )   } @{ $dsx } ];
my @ds5 = ( $dsx, $dsy );










# Set up chart objects
my $pieChart = Chart::Magick->pie(
    data    => [ 
        [ @ds1 ],
    ],
    chart   => {
        tiltAngle   => 70,
        startAngle  => -60,
        stickLength => 10,
        #tiltAngle   => 20,
        explosionLength=> 5,
        explosionWidth => 3,
        radius      => 90,
    },
);

my $gauge = Chart::Magick->gauge(
    data    => [ 
        [ @ds1 ],
    ],
);

my $barChart = Chart::Magick->bar(
    data    => [
        [ @ds1, '2008' ],
        [ @ds3, '2009' ],
        [ @ds4, '2010' ],
    ],
    chart   => {
        barWidth    => 10,
        drawMode    => 'stacked',
    },
    axis    => {
        xTitle      => 'Period',
    },
    legend  => {
        position    => 'top center',
    },
    labels  => [
        { 1 => 'q1', 2 => 'q2', 3 => 'q3', 4 => 'q4', 5 => 'overall' },
    ],
);

my $logChart = Chart::Magick->line(
    axisType    => 'LinLog',
    data        => [
        [ @ds2 ],
    ],
);

my $lineChart = Chart::Magick->line(
    data    => [
        [ @ds4 ],
        [ @ds3 ],
    ],
);

my $lineChart1 = Chart::Magick->line(
    data    => [
        [ @ds5 ],
    ],
    axis    => { 
        margin          => 15,
        xSubtickCount   => 1, 
        title           => '1.1 + sin 50Θ + sin 61Θ',
        font            => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
        xLabelUnits     => pi,
        xLabelFormat    => '%.1fπ',
        xTitle          => 'Θ [rad]',
        yTitle          => 'power [W]',
        yLabelFormat    => '%.2f',
    },
);

my $matrix = Chart::Magick->matrix( 800, 750, [
    [ $lineChart1           ],
    [ $barChart, $logChart  ],
    [ $pieChart, $gauge     ],
] );

$matrix->draw;
$matrix->write( 'm1.png' );

$matrix->setWeight( 1, 1, 2 );      # stretch the logchart
$matrix->draw( 1 );
$matrix->write( 'm2.png' );

exit;

## Fourth chart
#$axis = $matrix->getAxis( 2, 0 );
#$axis->addChart( $pieChart );
#$axis->addLabels( { 1 => 'aaa', 2 => 'bbb', 3 => 'ccc', 4 => 'ddd', 5 => 'eee' } );
#$axis->set(
#    title       =>  'Pie!',
#    );
#
#$axis = $matrix->getAxis( 2, 1 );
#$axis->addChart( $gauge );
#$axis->addLabels( { 1 => 'aaa', 2 => 'bbb', 3 => 'ccc', 4 => 'ddd', 5 => 'eee' } );
#$axis->set('title', 'Gauge');
#

$matrix->draw;
$matrix->write('matrix.png');
