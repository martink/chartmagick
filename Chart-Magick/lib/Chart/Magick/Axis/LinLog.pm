package Chart::Magick::Axis::LinLog;

use strict;

use base qw{ Chart::Magick::Axis::Log };

=head1 NAME

Chart::Magick::Axis::LinLog - A logarithmic coordinate system for the Chart::Magick class of modules.

=head1 SYNOPSIS

=head1 DESCRIPTION

The following methods are available from this class:

=cut

#--------------------------------------------------------------------

sub adjustYRangeToOrigin {
    my $self = shift;

    return $self->Chart::Magick::Axis::Lin::adjustYRangeToOrigin( @_ );
}

#--------------------------------------------------------------------

=head2 draw ( )

Draws the graph. See Chart::Magick::Axis for documentation.

=cut

sub draw {
    my $self = shift;

    $self->set( 
        yExpandRange    => 0,
    );
    
    $self->SUPER::draw( @_ );
}

#--------------------------------------------------------------------

=head2 getYTicks ( )

See Chart::Magick::Axis::getXTicks.

=cut

sub getYTicks {
    my $self = shift;
    
    return $self->Chart::Magick::Axis::Lin::getYTicks( @_ );
}

#--------------------------------------------------------------------

=head2 transformY ( y )

See Chart::Magick::Axis::transformY.

=cut

sub transformY {
    my $self = shift;

    return $self->Chart::Magick::Axis::Lin::transformY( @_ );
}

1;

