package Chart::Magick::Axis::LinLog;

use strict;

use POSIX qw{ floor ceil };

use base qw{ Chart::Magick::Axis::Lin };

sub draw {
    my $self = shift;

    my ($minX, $maxX, $minY, $maxY) = $self->getExtremeValues;

    $self->set('xStart', $minX); #floor $self->transformX( $minX ) );
    $self->set('xStop',  $maxX); #ceil  $self->transformX( $maxX ) );
    

    $minY = int( $minY  );
    $maxY = int( $maxY  );
    $self->set('yStart', $minY - 5 + abs( $minY ) % 5 );
    $self->set('yStop',  $maxY + 5 - abs( $maxY ) % 5 );

    $self->SUPER::draw( @_ );
}

#---------------------------------------------
sub generateLogTicks {
    my $self        = shift;
    my $from        = shift;
    my $to          = shift;
    my $tickCount   = shift;

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
sub transformX {
    my $self    = shift;
    my $x       = shift;
    return 0 unless $x;
    my $logx = log( $x ) / log(10);

    return $logx;
}

#---------------------------------------------
sub transformY {
    my $self    = shift;
    my $y       = shift;

    return $y;
}

1;

