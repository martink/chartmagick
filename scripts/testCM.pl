use strict;

use Chart::Magick::Axis::Polar;
use Chart::Magick::Axis::Lin;
use Chart::Magick::Axis::LinLog;
use Chart::Magick::Chart::Line;
use Chart::Magick::Chart::Bar;
#use Chart::Magick::Chart::Pie;
use Chart::Magick;
use Image::Magick;
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );

use constant pi => 3.14159265358979;

my $pxCount = 1000;
my $dsx = [ map { pi / $pxCount * $_          } (-$pxCount/2 .. $pxCount/2) ];
my $dsy = [ map { sin( 50*$_ ) + sin( 61*$_ )   } @{ $dsx } ];


my $chart2  = Chart::Magick::Chart::Line->new();
$chart2->dataset->addDataset( $dsx, $dsy );


$dsx = [ map { pi / $pxCount * 16 * $_      } ( -$pxCount / 32 .. $pxCount / 32 ) ];
$dsy = [ map { $_ * pi + sin( 10*$_ )              }  @{ $dsx } ];
    
$chart2->dataset->addDataset( $dsx, $dsy ); 

my $time = [ gettimeofday ];
my $axis = Chart::Magick::Axis::Lin->new( {
    width           => 1000,
    height          => 600,
    xSubtickCount   => 0,
    xLabelUnits     => pi,
    xTickWidth      => pi / 4
} );
$axis->addChart( $chart2 );
$axis->draw;

$axis->im->Write('out.png');

my $runtime = tv_interval( $time );

print "___>$runtime<___\n";
print $chart2->dataset->memUsage;
#print join "\n" , $canvas->im->QueryFont;
