use strict;

use Chart::Magick;

# fetch data from dataset file
open my $dataset, "dataset.txt" || die "cannot open dataset.txt";

my @data;
while ( my $line = <$dataset> ) {
    next unless $line =~ m{^ \d\d:\d\d:\d\d [^a-z]+ $}xmsi;

    push @data, [ split /\s+/, $line ];
}

close $dataset;

# fetch coords and values from dataset
my @coords = map { hms_to_sec( $_->[0] ) } @data;
my @values = map { $_->[3]               } @data;


# setup chart;
my $chart = Chart::Magick->line(
    width   => 1000,
    height  => 500,
    data    => [
        [ \@coords, \@values ]
    ],
    axis    => {
        xLabelUnits     => 3600,
        xSubtickCount   => 4,
        rulerColor      => 'grey70',
        xSubrulerColor  => 'grey90',
    }
);

$chart->write('line_simple_dataset.png');

#----------------------------------------
sub hms_to_sec {
    my ($h, $m, $s ) = split /:/, shift;

    return $h * 3600 + $m * 60 + $s;
}

