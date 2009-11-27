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
my $dsx2 = [ map { pi / $pxCount * 8 * $_      } ( -$pxCount / 16 .. $pxCount / 16 ) ];
my $dsy2 = [ map { 10*cos( $_ ) - 5 + cos( 20*$_ )       }  @{ $dsx2 } ];

# Timekeeping
my $time = [ gettimeofday ];

# Create chart and add datasets to it
my $chart = Chart::Magick::Chart::Line->new();
$chart->addDataset( $dsx, $dsy,   'marker2' );
$chart->addDataset( $dsx2, $dsy2, 'gooey.png', 20 ); 

# Create coordinate system
my $axis = Chart::Magick::Axis::Lin->new( {
    width           => 1000,
    height          => 600,

    # Set default font and size
    font            => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
    fontSize        => 12,

    # Override font for title
    titleFont       => '/usr/share/fonts/truetype/dustin/PenguinAttack.ttf',
    titleColor      => 'purple',
    
    # Set the titles
    title           => 'Gooey Attack!',
    xTitle          => 'Prediction',
    yTitle          => 'Outcome',

    # Normalize the x ticks to pi, and set a custom tick width. 
    xLabelUnits     => pi,
    xTickWidth      => pi / 4,

    # Custom format the x labels
    xLabelFormat    => '%.1fπ',

    xTickOffset     => 1,
} );

# Add the chart to the coordinate system
$axis->addChart( $chart );
$axis->legend->set( location => 'bottom' );

# Render it
$axis->draw;

# And write it to disk
$axis->im->Write('out.png');

# More timekeeping
my $runtime = tv_interval( $time );

print "___>$runtime<___\n";
print $chart->dataset->memUsage;
#print join "\n" , $canvas->im->QueryFont;
