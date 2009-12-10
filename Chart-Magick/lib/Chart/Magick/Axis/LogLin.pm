package Chart::Magick::Axis::LogLin;

use strict;
use warnings;

use base qw{ Chart::Magick::Axis::Log };

=head1 NAME

Chart::Magick::Axis::LogLin - A logarithmic coordinate system for the Chart::Magick class of modules.

=head1 SYNOPSIS

=head1 DESCRIPTION

The following methods are available from this class:

=cut

#--------------------------------------------------------------------

=head2 adjustXRangeToOrigin ( )

See Chart::Magick::Axis::Lin::adjustXRangeToOrigin.

=cut

sub adjustXRangeToOrigin {
    my $self = shift;

    return $self->Chart::Magick::Axis::Lin::adjustXRangeToOrigin( @_ );
}

#--------------------------------------------------------------------

=head2 draw ( )

Draws the graph. See Chart::Magick::Axis for documentation.

=cut

sub draw {
    my $self = shift;

    $self->set( 
        xExpandRange    => 0,
    );
    
    return $self->SUPER::draw( @_ );
}

#--------------------------------------------------------------------

=head2 getXTicks ( )

See Chart::Magick::Axis::getXTicks.

=cut

sub getXTicks {
    my $self = shift;
    
    return $self->Chart::Magick::Axis::Lin::getXTicks( @_ );
}

#--------------------------------------------------------------------

=head2 transformX ( y )

See Chart::Magick::Axis::transformX.

=cut

sub transformX {
    my $self = shift;

    return $self->Chart::Magick::Axis::Lin::transformX( @_ );
}

1;

