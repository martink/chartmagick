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

my $ds = Chart::Magick::Data->new;

#$ds->addDataPoint( [ 0, 1, 2], [ 8, 9] );
#$ds->addDataPoint( [ 2, 3, 4], [ 9, 0] );
#$ds->addDataPoint( 1, 6 );
#$ds->addDataPoint( 3, 4 );

#$ds->addDataset(
#    [ qw( 1 2 3 4 5 ) ],
#    [ qw( 2 2 2 2 2 ) ],
#);

$ds->addDataset(
    [ qw( 1 2 3 4 5 ) ],
    [ qw( 1 3 5.9 3 2 ) ],
);
#$ds->addDataset(
#    [ qw( 1 10 100 1000 10000 ) ],
#    [ qw( 5 2 -1 8 3 ) ],
#);




$ds->addDataset(
    [ qw( 1 2 3 4 5 ) ],
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

    yTickWidth      => 2,
    axesOutside     => 0,
} );


#$axis->set('xChartOffset', 40);
#$axis->set('xLabelUnits', pi);

my $chart   = Chart::Magick::Chart::Bar->new( );
#$chart->addDataset( $ds1 );
#$chart->addDataset( $ds2 );
#$chart->addDataset( $ds3 );
#$chart->addDataset( $ds4 );
$chart->setData( $ds );
$chart->set('barWidth',     10);
$chart->set('barSpacing',   3);
#$chart->set('drawMode',     'cumulative');

$axis->addChart( $chart );
$axis->addLabels( { 1 => 'jan', 2 => 'feb', 3 => 'mrt', 4 => 'apr da\'s nou ook niet echt een hele lange naam toch?', 5 => 'eeennnn hele lange maand naam zoals bijvoorbeld zoiets als mei of misschien ook nog wel iets anders zeg maar' } );
$axis->draw;

#print Dumper( $axis->get );
#print Dumper( $axis->{_plotOptions} );

$axis->im->Write('out.png');

#print $ds->dumpData;

#print join "\n" , $canvas->im->QueryFont;
