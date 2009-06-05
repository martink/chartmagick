use strict;

use Chart::Magick::Axis::Lin;
use Chart::Magick::Axis::LinLog;
use Chart::Magick::Chart::Line;
#use Chart::Magick::Chart::Bar;
#use Chart::Magick::Chart::Pie;
use Chart::Magick;
use Image::Magick;
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );

use constant pi => 3.14159265358979;

my $time = [ gettimeofday ];
my $pxCount = 1000;
my $dsx = [ map { pi / $pxCount * $_          } (0..$pxCount) ];
my $dsy = [ map { 1.1 + sin( 50*$_ ) + sin( 61*$_ )   } @{ $dsx } ];

my $axis    = Chart::Magick::Axis::Lin->new( {
    width   => 1000,
    height  => 600,
} );
$axis->set('xSubtickCount', 0);
$axis->set('xLabelUnits', pi);
$axis->set('xTickWidth', pi / 4);


my $chart2  = Chart::Magick::Chart::Line->new();
$chart2->dataset->addDataset( $dsx, $dsy );
#$chart2->set('plotMarkers', 1);
#print $chart2->dataset->dumpData;


$axis->addChart( $chart2 );
$axis->draw;

#print Dumper( $axis->get );
#print Dumper( $axis->{_plotOptions} );


#for (0 .. 1000/20) {
#    my $x = 50 * $_;
#    $axis->im->Draw(
#        primitive   => 'Line',
#        points      => "$x,0,$x,50",
#        stroke      => 'magenta',
#    );
#}

$axis->im->Write('out.png');

my $runtime = tv_interval( $time );

print "___>$runtime<___\n";
#print join "\n" , $canvas->im->QueryFont;
