use strict;

use Chart::Magick::Axis::Lin;
use Chart::Magick::Chart::Scatter;

use Math::Trig;
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );


my $cnt = 1000;

my (@dsx, @dsy, @dsx2, @dsy2);
# Generate datasets
for ( 1 .. $cnt ) {
    my $r = rand( 10 );
    my $t = rand() * 2 * pi;

    push @dsx, $r * cos( $t );
    push @dsy, $r * sin( $t );

    push @dsx2, ( 19 - $r ) * cos $t;
    push @dsy2, ( 19 - $r ) * sin $t;
}

# Timekeeping
my $time = [ gettimeofday ];

# Create chart and add datasets to it
my $chart = Chart::Magick::Chart::Scatter->new();
$chart->addDataset( \@dsx, \@dsy,   'Transordinary wobble scale', 'square', 6 );
$chart->addDataset( \@dsx2, \@dsy2, 'Octopode scale', 'gooey.png', 10 ); 

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

#    drawLegend      => 0,
#    xStart          => -100,
#    yStart          => -100,
#    xStop           => 100,
#    yStop           => 100,

    xTickOffset     => 1,
    yTickOffset     => 1,
} );

# Add the chart to the coordinate system
$axis->addChart( $chart );
#$axis->legend->set( location => 'bottom' );

# Render it
$axis->draw;

# And write it to disk
$axis->im->Write('scatter.png');

# More timekeeping
my $runtime = tv_interval( $time );

print "___>$runtime<___\n";
print $chart->dataset->memUsage;
#print join "\n" , $canvas->im->QueryFont;
