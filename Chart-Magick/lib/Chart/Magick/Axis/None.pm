package Chart::Magick::Axis::None;

use strict;

use base qw{ Chart::Magick::Axis };

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
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;

    my $offsetX = $self->get('marginLeft') + $self->getChartWidth / 2;
    my $offsetY = $self->get('marginTop')  + $self->getChartHeight / 2;

    return ( int( $x->[0] + $offsetX ), int( $y->[0] + $offsetY ) );
}

1;

