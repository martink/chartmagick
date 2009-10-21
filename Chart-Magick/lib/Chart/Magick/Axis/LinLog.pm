package Chart::Magick::Axis::LinLog;

use strict;

use POSIX qw{ floor ceil };

use base qw{ Chart::Magick::Axis::Lin };

=head1 NAME

Chart::Magick::Axis::LinLog - A lin-log coordinate system for the Chart::Magick class of modules.

=head1 SYNOPSIS

=head1 DESCRIPTION

The following methods are available from this class:

#---------------------------------------------

=head2 draw ( )

Draws the graph. See Chart::Magick::Axis for documentation.

=cut

sub draw {
    my $self = shift;

    # Ticks in linlog are always aligned with the axes, so prevent the super class from over adjusting.
    $self->set( 'xAlignAxesWithTicks', 0 );
    
    $self->SUPER::draw( @_ );
}

#---------------------------------------------

=head2 generateLogTicks ( from, to )

Generates ticks on a logarithmic scale that envelope the interval given by from and to.

=head3 from

The maximum value at which the ticks start.

=head3 to

The minimum value at which the ticks stop.

=cut

sub generateLogTicks {
    my $self        = shift;
    my $from        = shift;
    my $to          = shift;

    my $fromOrder   = floor $self->transformX($from);
    my $toOrder     = ceil  $self->transformX($to);

    my @ticks       = map { 10**$_ } ($fromOrder .. $toOrder);

    return \@ticks;
}

#---------------------------------------------

=head2 getDataRange ( )

See Chart::Magick::Axis::getDataRange.

=cut

sub getDataRange {
    my $self = shift;

    my ($minX, $maxX, $minY, $maxY) = $self->SUPER::getDataRange( @_ );

    return (
        [ 10 ** ( floor $self->transformX( $minX->[0] ) ) ],
        [ 10 ** ( ceil  $self->transformX( $maxX->[0] ) ) ],
        $minY,
        $maxY,
    );
}

#---------------------------------------------

=head2 getXTicks ( )

See Chart::Magick::Axis::getXTicks.

=cut

sub getXTicks {
    my $self = shift;

    return $self->generateLogTicks( $self->get('xStart'), $self->get('xStop') );
    # my @ticks = map { 10**$_ } (0..4);
    my $to      = log( $self->get('xStop') )/log(10);
    my $from    = $to - $self->get('xTickCount');
    
    my @ticks = map { 10**$_ } ( $from .. $to );
    return \@ticks;
}


#---------------------------------------------

=head2 transformX ( x )

Returns the value of x transformed to a logarithmic coordinate system.

=cut

sub transformX {
    my $self    = shift;
    my $x       = shift;

    return 0 unless $x;

    my $logx = log( $x ) / log(10);

    return $logx; #log( $self->get('xStart') ) / log(10);
}

1;

