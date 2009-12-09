use strict;

use Chart::Magick::Axis::Lin;
use Chart::Magick::Chart::Stick;

use Math::Trig;
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );


my $cnt = 100;

my (@dsx, @dsy);
# Generate dataset 1
my @dsx = ( 0 .. 100 );
my @dsy = map { sin( pi / 16 * $_ ) } @dsx;

my @dsy2 = map { rand(1) } @dsx;


# Timekeeping
my $time = [ gettimeofday ];

# Create chart and add datasets to it
my $chart = Chart::Magick::Chart::Stick->new();
$chart->addDataset( \@dsx, \@dsy2, 'Octopode scale', 'circle', 6 ); 
$chart->addDataset( \@dsx, \@dsy,   'Transordinary wobble scale', 'square', 6 );

# Create coordinate system
my $axis = Chart::Magick::Axis::Lin->new( {
    width           => 1000,
    height          => 600,
} );

# Add the chart to the coordinate system
$axis->addChart( $chart );

# Render it
$axis->draw;

# And write it to disk
$axis->im->Write('stick.png');

# More timekeeping
my $runtime = tv_interval( $time );

print "___>$runtime<___\n";
print $chart->dataset->memUsage;
#print join "\n" , $canvas->im->QueryFont;
