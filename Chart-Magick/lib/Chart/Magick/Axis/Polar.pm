package Chart::Magick::Axis::Polar;

use strict;
use warnings;

use Carp;
use POSIX qw{ ceil };
use List::Util qw{ max min };
use Math::Trig;

use base qw{ Chart::Magick::Axis::Lin };

=head2 rad2rad

Math::Trig doesn't export its rad2rad function. So we get it here.

=cut

*rad2rad = *Math::Trig::rad2rad;

=head2 optimizeMargins ( )

See L<Chart::Magick::Axis::Lin::optimizeMargins>.

=cut

sub optimizeMargins { 
    my ( $self, $minX, $maxX, $minY, $maxY ) = @_;

    $minX = 0;  # alway start at 0.
    
    my $baseWidth   = $self->getChartWidth; 
    my $baseHeight  = $self->getChartHeight;
    my $baseRadius  = 0.5 * min( $baseWidth, $baseHeight );

    my $xTickWidth = $self->get('xTickWidth') || ( $maxX - $minX ) / ( $self->get('xTickCount') || 8 );
    my $xTickCount = ( $maxX - $minX ) / $xTickWidth;
    $self->set( xTicks => [ map { $minX + $_ * $xTickWidth } ( 0 .. $xTickCount - 1 ) ] );

    my $yTickWidth = $self->get('yTickWidth')
        || $self->calcTickWidth( $minY, $maxY, $baseRadius, $self->get('yTickCount'), $self->get('yLabelUnits') );

    my @xLabels = map { $self->getTickLabel( $_, 0 ) } @{ $self->generateTicks( $minX, $maxX, $xTickWidth ) };
    
    my $xLabelHeight    = ceil max map { int $self->getLabelDimensions( $_ )->[1] } @xLabels; 
    my $yLabelWidth     = ceil max map { int $self->getLabelDimensions( $_ )->[0] } @xLabels;

    my $chartWidth  = $baseWidth  - ( $yLabelWidth + $self->get('xTickOutset') + $self->get('xLabelTickOffset')) * 2;
    my $chartHeight = $baseHeight - ( $xLabelHeight + $self->get('xTickOutset') + $self->get('xLabelTickOffset')) * 2;

    $self->plotOption(
        chartWidth      => $baseWidth,
        chartHeight     => $baseHeight,
        xPxPerUnit      => 2 * pi / $maxX,
        yPxPerUnit      => ( 0.5 * $chartHeight ) / ($maxY - $minY),
        xTickOffset     => 0,
        yTickOffset     => 0,
        centerX         => $self->plotOption( 'chartAnchorX' ) + $baseWidth / 2,
        centerY         => $self->plotOption( 'chartAnchorY' ) + $baseHeight / 2,
    );
    $self->set(
        xTickWidth      => $xTickWidth,
        yTickWidth      => $yTickWidth,
    );

    return ( $minX, $maxX, $minY, $maxY );
};

#--------------------------------------------------------------------

=head2 definition ( )

See Chart::Magick::Axis::Lin::definition.

Changes default for xExpandRange to 0.

=cut

sub definition {
    my $self = shift;

    my %def = (
        xExpandRange    => 0,
        xTickCount      => 8,
        xRange          => undef,
    );

    return { %{ $self->SUPER::definition }, %def };
}

#--------------------------------------------------------------------

=head2 coordInRange

See Chart::Magick::Axis::coordInRange. Always returns 1.

=cut

sub coordInRange {
    return 1;
}

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
    
    for my $tick ( @{ $self->getXTicks } ) {
        next unless $tick < $maxX;

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => $self->get('xRulerColor'),
            points      => 
                  " M " . $self->toPx( [ 0      ], [ 0      ] )
                . " L " . $self->toPx( [ $tick  ], [ $maxY  ] ),
            fill        => 'none',
        );
    }

    for my $tick ( @{ $self->getYTicks } ) {
        next unless $tick > 0 && $tick <= $maxY;

        $self->im->Draw(
            primitive   => 'Circle',
            stroke      => $self->get('yRulerColor'),
            points      => 
                        $self->toPx( [ 0 ], [ 0     ] )
                . " " . $self->toPx( [ 0 ], [ $tick ] ),
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

    for my $tick ( @{ $self->getXTicks } ) {
        next unless $tick < $maxX;

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => $self->get('xTickColor'),
            points      => 
                  " M " . $self->toPx( [ $tick ], [ $tickFrom ] )
                . " L " . $self->toPx( [ $tick ], [ $tickTo   ] ),
            fill        => 'none',

        );

        my $angle    = $tick * $self->getPxPerXUnit;
        my $rotAngle = rad2rad( $angle + 0.5 * pi );

        my $halign = 
              $rotAngle > 0  && $rotAngle < pi      ? 'left'
            : $rotAngle > pi && $rotAngle < 2 * pi  ? 'right'
            :                                         'center'
            ;

        my $valign = 
              $angle    > 0  && $angle    < pi      ? 'bottom'
            : $angle    > pi && $angle    < 2 * pi  ? 'top'
            :                                         'center'
            ; 

        my ($x, $y) = $self->project( [ $tick ], [ $tickTo + $self->get('xLabelTickOffset') / $self->plotOption('yPxPerUnit')   ] );

        $self->im->text(
            text        => $self->getTickLabel( $tick, 0 ),
            halign      => $halign, 
            valign      => $valign,
            font        => $self->get('labelFont'),
            pointsize   => $self->get('labelFontSize'),
            style       => 'Normal',
            fill        => $self->get('labelColor'),
            x           => $x,
            y           => $y,
        );
    }

    foreach my $tick ( @{ $self->getYTicks } ) {
        my ($x, $y) = $self->project( [ 0 ], [ $tick ] );

        $self->im->text(
            text        => $self->getTickLabel( $tick, 1 ),
            halign      => 'center', 
            valign      => 'top',
            font        => $self->get('labelFont'),
            pointsize   => $self->get('labelFontSize'),
            style       => 'Normal',
            fill        => $self->get('labelColor'),
            x           => $x,
            y           => $y + $self->get('yLabelTickOffset'),
        );
    }
}

#--------------------------------------------------------------------

=head2 preprocessData ()

See Chart::Magick::Axis::preprocessData.

=cut

sub preprocessData {
    my $self = shift;

    $self->SUPER::preprocessData;
}

#--------------------------------------------------------------------

=head2 project ( coord, value )

See Chart::Magick::Axis::project.

=cut

sub project {
    my $self    = shift;
    my $coord   = shift;
    my $value   = shift;

    my $angle   = $coord->[0] * $self->getPxPerXUnit;
    my $centerX = $self->plotOption( 'centerX' );
    my $centerY = $self->plotOption( 'centerY' );
    my $scale   = $self->plotOption( 'yPxPerUnit' );

    return (
        $centerX + $scale * $value->[0] * cos $angle,
        $centerY - $scale * $value->[0] * sin $angle,
    );
}

1;

