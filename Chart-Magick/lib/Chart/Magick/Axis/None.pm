package Chart::Magick::Axis::None;

use strict;

use base qw{ Chart::Magick::Axis };

=head2 getChartHeight ( )

See Chart::Magick::Axis::getChartHeight.

=cut

sub getChartHeight {
    my $self = shift;

    return $self->plotOption( 'axisHeight' );
}

=head2 getChartWidth ( )

See Chart::Magick::Axis::getChartWidth.

=cut

sub getChartWidth {
    my $self = shift;

    return $self->plotOption( 'axisWidth' );
}

=head2 getCoordDimension ( )

See Chart::Magick::Axis::getCoordDimension.

=cut

sub getCoordDimension {
    return 0;
}

=head2 getValueDimension ( )

See Chart::Magick::Axis::getValueDimension

=cut

sub getValueDimension {
    return 0;
}

=head2 project ( )

See Chart::Magick::Axis::project.

=cut

sub project {
    my $self = shift;

    return ($_[0]->[0], $_[1]->[0]);
}

1;

