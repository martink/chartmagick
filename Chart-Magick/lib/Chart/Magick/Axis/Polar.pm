package Chart::Magick::Axis::Polar;

use strict;

use base qw{ Chart::Magick::Axis::Lin };
use constant pi => 3.141528;

sub plotLast {

}

sub preprocessData {
    my $self = shift;
$self->SUPER::preprocessData;
    my ($minX, $maxX, $minY, $maxY) = map { $_->[0] } $self->getDataRange;

    $self->{ _xPerDegree } = 2 * pi / $maxX;
    $self->{ _yRange     } = $maxY;
}

sub project {
    my $self    = shift;
    my $coord   = shift;
    my $value   = shift;

    my $angle   = $coord->[0] * $self->{ _xPerDegree };
    my $centerX = $self->plotOption( 'chartAnchorX' ) + $self->getChartWidth  / 2;
    my $centerY = $self->plotOption( 'chartAnchorY' ) + $self->getChartHeight / 2;


    return (
        $centerX + 100 * $value->[0] * cos $angle,
        $centerY - 100 * $value->[0] * sin $angle,
    );
}

1;

