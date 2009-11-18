package Chart::Magick::Axis::Polar;

use strict;

use base qw{ Chart::Magick::Axis::Lin };
use constant pi => 3.141528;


#--------------------------------------------------------------------

=head2 plotAxes ( )

See Chart::Magick::Axis::Lin::plotAxes.

=cut

sub plotAxes {
    my $self = shift;

    my $maxX = $self->get('xStop');
    my $maxY = $self->get('yStop');

    # Main axes
    $self->im->Draw(
        primitive   => 'Path',
        stroke      => $self->get('axisColor'),
        points      =>
                 " M " . $self->toPx( [ 0            ], [ $maxY ] ) 
               . " L " . $self->toPx( [ $maxX * 0.50 ], [ $maxY ] )
               . " M " . $self->toPx( [ $maxX * 0.25 ], [ $maxY ] )
               . " L " . $self->toPx( [ $maxX * 0.75 ], [ $maxY ] ), 
        fill        => 'none',
    );
}
    
#--------------------------------------------------------------------

=head2 plotBox ( )

See Chart::Magick::Axis::Lin::plotBox.

=cut

sub plotBox {
    my $self = shift;

    $self->im->Draw(
        primitive   => 'Circle',
        stroke      => $self->get('boxColor'),
        points      => $self->toPx( [ 0 ], [ 0 ] ) . " " . $self->toPx( [ 0 ], [ $self->get('yStop') ] ),
        fill        => 'none',
    );
}

#--------------------------------------------------------------------

=head2 plotRulers ( )

See Chart::Magick::Axis::Lin::plotRulers.

=cut

sub plotRulers {
    my $self = shift;
   
    my $maxX = $self->get('xStop');
    my $maxY = $self->get('yStop');
    
    for ( 0 .. 7 ) {
        $self->im->Draw(
            primitive   => 'Path',
            stroke      => $self->get('xRulerColor'),
            points      => 
                  " M " . $self->toPx( [ 0              ], [ 0      ] )
                . " L " . $self->toPx( [ $maxX * $_ / 8 ], [ $maxY  ] ),
            fill        => 'none',

        );
    }

    for ( @{ $self->getYTicks } ) {
        next unless $_ > 0 && $_ <= $maxY;

        $self->im->Draw(
            primitive   => 'Circle',
            stroke      => $self->get('yRulerColor'),
            points      => 
                  $self->toPx( [ 0 ], [ 0   ] )
                . " " . $self->toPx( [ 0 ], [ $_  ] ),
            fill        => 'none',
            antialias   => 'true',
        );
    }
}

#--------------------------------------------------------------------

=head2 plotTicks ( )

See Chart::Magick::Axis::Lin::plotTicks.

=cut

sub plotTicks {
    my $self = shift;
    
    my $maxX = $self->get('xStop');
    my $maxY = $self->get('yStop');
    
    my $tickFrom = $maxY - $self->get('xTickInset')  / $self->plotOption('yPxPerUnit') ;
    my $tickTo   = $maxY + $self->get('xTickOutset') / $self->plotOption('yPxPerUnit') ;

    for ( 0 .. 7 ) {
        $self->im->Draw(
            primitive   => 'Path',
            stroke      => $self->get('xTickColor'),
            points      => 
                  " M " . $self->toPx( [ $maxX * $_ / 8 ], [ $tickFrom ] )
                . " L " . $self->toPx( [ $maxX * $_ / 8 ], [ $tickTo   ] ),
            fill        => 'none',

        );
    }
}


=head2 preprocessData ()

See Chart::Magick::Axis::preprocessData.

=cut

sub preprocessData {
    my $self = shift;

    $self->SUPER::preprocessData;
    
    my ($minX, $maxX, $minY, $maxY) = map { $_->[0] } $self->getDataRange;

    
    $self->{ _xPerDegree } = 2 * pi / $maxX;
    $self->{ _yRange     } = $maxY;
    $self->plotOption( yPxPerUnit => $self->getChartHeight / 2 / $maxY );
}

=head2 project ( coord, value )

See Chart::Magick::Axis::project.

=cut

sub project {
    my $self    = shift;
    my $coord   = shift;
    my $value   = shift;

    my $angle   = $coord->[0] * $self->{ _xPerDegree };
    my $centerX = $self->plotOption( 'chartAnchorX' ) + $self->getChartWidth  / 2;
    my $centerY = $self->plotOption( 'chartAnchorY' ) + $self->getChartHeight / 2;
    my $scale   = $self->plotOption( 'yPxPerUnit' );

    return (
        $centerX + $scale * $value->[0] * cos $angle,
        $centerY - $scale * $value->[0] * sin $angle,
    );
}

1;

