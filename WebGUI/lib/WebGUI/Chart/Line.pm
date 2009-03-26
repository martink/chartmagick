package WebGUI::Chart::Line;

use strict;

use Tie::IxHash;
use Chart::Magick::Chart::Line;

use base qw{ WebGUI::Chart::ChartMagickLin };

#---------------------------------------------------------------------
sub definition {
    my $class       = shift;
    my $session     = shift || die "Line: no session passed";
    my $definition  = shift || [];

    tie my %chartOptions, 'Tie::IxHash', (
        drawMarkers => {
            fieldType   => 'yesNo',
            label       => 'Draw markers at vertices?',
            hoverHelp   => '',
        },
    );

    my %properties = (
        name        => 'Line chart',
        properties  => \%chartOptions,
        className   => 'WebGUI::Chart::Line',
        chartClass  => 'Chart::Magick::Chart::Line',
    );
    push @{ $definition }, \%properties;

    return $class->SUPER::definition( $session, $definition );
};


1;

