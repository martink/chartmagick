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


# Generate dataset 1
my $dsx = [ map { pi / $pxCount * $_          } (-$pxCount/2 .. $pxCount/2) ];
my $dsy = [ map { sin( 50*$_ ) + sin( 61*$_ ) } @{ $dsx } ];

# Generate dataset 2
my $dsx2 = [ map { pi / $pxCount * 16 * $_      } ( -$pxCount / 32 .. $pxCount / 32 ) ];
my $dsy2 = [ map { $_ * pi + sin( 10*$_ )       }  @{ $dsx2 } ];

# Timekeeping
my $time = [ gettimeofday ];

# Create chart and add datasets to it
my $chart = Chart::Magick::Chart::Line->new();
$chart->addData( $dsx, $dsy,   'marker2' );
$chart->addData( $dsx2, $dsy2, 'gooey.png', 15 ); 

# Create coordinate system
my $axis = Chart::Magick::Axis::Lin->new( {
    width           => 1000,
    height          => 600,
    xSubtickCount   => 0,
    xLabelUnits     => pi,
    xTickWidth      => pi / 4
} );

# Add the chart to the coordinate system
$axis->addChart( $chart );

# Render it
$axis->draw;

# And write it to disk
$axis->im->Write('out.png');

# More timekeeping
my $runtime = tv_interval( $time );

print "___>$runtime<___\n";
print $chart->dataset->memUsage;
#print join "\n" , $canvas->im->QueryFont;
