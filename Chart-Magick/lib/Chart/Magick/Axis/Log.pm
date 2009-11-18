package Chart::Magick::Axis::Log;

use strict;

use POSIX qw{ floor ceil };
use Carp;

use base qw{ Chart::Magick::Axis::Lin };

=head1 NAME

Chart::Magick::Axis::Log - A logarithmic coordinate system for the Chart::Magick class of modules.

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
    return @_;
}

#--------------------------------------------------------------------

=head2 adjustYRangeToOrigin ( )

See Chart::Magick::Axis::Lin::adjustYRangeToOrigin.

=cut

sub adjustYRangeToOrigin {
    my $self = shift;
    return @_;
}

#--------------------------------------------------------------------

=head2 definition ( )

See Chart::Magick::Axis::Lin::definition.

In addition to properties available in Chart::Magick::Axis::Lin, this class provides the following properties:

=head3 xExpandRange
=head3 yExpandRange

When set to true, the range of the x resp y axis will be expanded so that it will start and end on a power of 10. Defaults
to true.

=cut

sub definition {
    my $self = shift;

    my %definition = (
        xExpandRange    => 1,
        yExpandRange    => 1,
    );

    return { %{ $self->SUPER::definition }, %definition };
}

#--------------------------------------------------------------------

=head2 draw ( )

Draws the graph. See Chart::Magick::Axis for documentation.

=cut

sub draw {
    my $self = shift;

    # Ticks in linlog are always aligned with the axes, so prevent the super class from over adjusting.
    $self->set( 
        xAlignAxesWithTicks     => 0,
        yAlignAxesWithTicks     => 0,
    );
    
    $self->SUPER::draw( @_ );
}

#--------------------------------------------------------------------

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

    croak "generateLogTicks only accepts positive from and to values" unless $from > 0;
    croak "generateLogTicks requires that to >= from" if $to < $from;

    my $fromOrder   = floor $self->logTransform( $from );
    my $toOrder     = ceil  $self->logTransform( $to   );

    my @ticks       = map { 10**$_ } ( $fromOrder .. $toOrder );

    return \@ticks;
}

#--------------------------------------------------------------------

=head2 getDataRange ( )

See Chart::Magick::Axis::getDataRange.

=cut

sub getDataRange {
    my $self = shift;

    my ($minX, $maxX, $minY, $maxY) = $self->SUPER::getDataRange( @_ );

    my $expandX = $self->get('xExpandRange');
    my $expandY = $self->get('yExpandRange');
    return (
        $expandX ? [ 10 ** ( floor $self->transformX( $minX->[0] ) ) ] : $minX,
        $expandX ? [ 10 ** ( ceil  $self->transformX( $maxX->[0] ) ) ] : $maxX,
        $expandY ? [ 10 ** ( floor $self->transformY( $minY->[0] ) ) ] : $minY,
        $expandY ? [ 10 ** ( ceil  $self->transformY( $maxY->[0] ) ) ] : $maxY,
    );
}

#--------------------------------------------------------------------

=head2 getXTicks ( )

See Chart::Magick::Axis::getXTicks.

=cut

sub getXTicks {
    my $self = shift;

    return $self->generateLogTicks( $self->get('xStart'), $self->get('xStop') );
}

#--------------------------------------------------------------------

=head2 getYTicks ( )

See Chart::Magick::Axis::getYTicks.

=cut

sub getYTicks {
    my $self = shift;

    return $self->generateLogTicks( $self->get('yStart'), $self->get('yStop') );
}

#--------------------------------------------------------------------

=head2 logTransform ( value, base )

Returns the base n logarithm of value. Defaults to base 10. Output is formatted to have 5 decimals.

=head3 value

The value to take the logarithm of. Values must be larger than 0. If an invalid value ( <= 0 ) is passed undef will
be returned.

=head3 base

The base of the logarithm. Defaults to 10.

=cut

sub logTransform {
    my $self    = shift;
    my $value   = shift || 0;
    my $base    = shift || 10;

    return if ( $value <= 0 );

    # The sprintf's below are necessary to prevent precision errors:
    # For instance log( 0.1 ) / log( 10 ) returns -0.99999999999999977795539507496869191527366638183594 which ceil
    # will round to -0 while this should obviously be -1.
    return sprintf '%.5f', log( $value ) / log( $base );
}

#--------------------------------------------------------------------

=head2 transformX ( x )

Returns the value of x transformed to a logarithmic coordinate system.

=cut

sub transformX {
    my $self    = shift;
    my $x       = shift;
    
    my $logx    = $self->logTransform( $x );
    return $logx if defined $logx;

    my $start = $self->get('xStart');
    carp "Cannot transform x value $x to a logarithmic scale. Using $start instead!";

    return $self->logTransform( $start ) || return 0;
}

#--------------------------------------------------------------------

=head2 transformY ( y )

Returns the value of y transformed to a logarithmic coordinate system.

=cut

sub transformY {
    my $self    = shift;
    my $y       = shift;
    
    my $logy    = $self->logTransform( $y );
    return $logy if defined $logy;

    my $start = $self->get('yStart');
    carp "Cannot transform y value $y to a logarithmic scale. Using $start instead!";

    return $self->logTransform( $start ) || return 0;
}

1;

