package Chart::Magick::Axis::None;

use strict;

use base qw{ Chart::Magick::Axis };

sub getChartHeight {
    my $self = shift;

    return $self->plotOption( 'axisHeight' );
}

sub getChartWidth {
    my $self = shift;

    return $self->plotOption( 'axisWidth' );
}

sub getCoordDimension {
    return 0;
}

sub getValueDimension {
    return 0;
}

sub project {
    my $self = shift;

    return ($_[0]->[0], $_[1]->[0]);
}

1;

