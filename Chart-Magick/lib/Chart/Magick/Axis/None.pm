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

    my $offsetX = $self->get('marginLeft');
    my $offsetY = $self->get('marginTop');

    return ( $x->[0] + $offsetX, $y->[0] + $offsetY );
}

1;

