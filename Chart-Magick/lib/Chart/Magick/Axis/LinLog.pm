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

    my ($minX, $maxX, $minY, $maxY) = map { $_->[0] } $self->getDataRange;

    $self->set('xStart', $minX); #floor $self->transformX( $minX ) );
    $self->set('xStop',  $maxX); #ceil  $self->transformX( $maxX ) );
    

    $minY = int( $minY  );
    $maxY = int( $maxY  );
    $self->set('yStart', $minY - 5 + abs( $minY ) % 5 );
    $self->set('yStop',  $maxY + 5 - abs( $maxY ) % 5 );

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

    return $logx;
}

1;

