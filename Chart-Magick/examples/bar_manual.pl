use strict;

use Chart::Magick::Axis::Lin;
use Chart::Magick::Chart::Bar;

# Create some datasets
my $dsx     = [ 1 .. 5 ];
my $dsy     = [ map { 4  + rand 2 } @$dsx   ];
my $dsy2    = [ map { $_ + rand 1 } @$dsy   ];
my $dsy3    = [ map { 10 - $_     } @$dsy2  ];

# Instanciate and setup linear coordinate system.
my $axis    = Chart::Magick::Axis::Lin->new( {
    width   => 600,
    height  => 300
} );

$axis->legend->set( {
    backgroundColor => 'none',
    position        => 'bottom center',
} );

# Instanciate and setup Bar chart.
my $bar     = Chart::Magick::Chart::Bar->new;
$bar->addDataset( $dsx, $dsy,  'Random prognosis'       );
$bar->addDataset( $dsx, $dsy2, 'Adjusted prognosis'     );
$bar->addDataset( $dsx, $dsy3, 'Projected deficiency'   );

$axis->addLabels(
    { 1 => 'q1 2009', 2 => 'q2 2009', 3 => 'q3 2009', 4 => 'q4 2009', 5 => '2010' },
);

# Add chart to axis
$axis->addChart( $bar );

# Draw the entire thing;
$axis->draw;

# Write image to disk.
$axis->im->Write( 'bar_manual.png' );

