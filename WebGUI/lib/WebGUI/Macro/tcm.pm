package WebGUI::Macro::tcm;

use strict;
use WebGUI::Chart::Line;
use Data::Dumper;

sub process {
    my $session = shift;

    my $x = [ 1, 2, 6, 9];
    my $y = [ 3, 5, -2, 10];

    my $chart = WebGUI::Chart::Line->new( $session );
    return Dumper( $chart->session );

}

1;

