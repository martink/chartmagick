package Chart::Magick::Axis::Polar;

use strict;
use warnings;

use Carp;
use POSIX qw{ ceil };
use List::Util qw{ max };
use Math::Trig;

use base qw{ Chart::Magick::Axis::Lin };


sub rad2rad {
    return Math::Trig::rad2rad( shift );
}


sub optimizeMargins { 
    my ( $self, $minX, $maxX, $minY, $maxY ) = @_;

    $self->SUPER::optimizeMargins( $minX, $maxX, $minY, $maxY );

    my $xTickWidth = $self->get('xTickWidth') || ( $minX - $maxX ) / 8;
    my @xLabels = map { $self->getTickLabel( $_, 0 ) } @{ $self->generateTicks( $minX, $maxX, $xTickWidth ) };
    
    my $xLabelHeight    = ceil max map { int $self->getLabelDimensions( $_ )->[1] } @xLabels; 
    my $yLabelWidth     = ceil max map { int $self->getLabelDimensions( $_ )->[0] } @xLabels;
    my $baseWidth       = $self->plotOption( 'axisWidth' )  - $self->plotOption( 'axisMarginLeft' ) - $self->plotOption( 'axisMarginRight'  );
    my $baseHeight      = $self->plotOption( 'axisHeight' ) - $self->plotOption( 'axisMarginTop'  ) - $self->plotOption( 'axisMarginBottom' );

    my $chartWidth  = $baseWidth  - ( $yLabelWidth + $self->get('xTickOutset') + $self->get('xLabelTickOffset')) * 2;
    my $chartHeight = $baseHeight - ( $xLabelHeight + $self->get('xTickOutset') + $self->get('xLabelTickOffset')) * 2;

    $self->plotOption(
        chartWidth  => $chartWidth,
        chartHeight => $chartHeight,
        xPxPerUnit  => 2 * pi / $maxX,
        yPxPerUnit  => ( 0.5 * $chartHeight ) / ($maxY - $minY),
        xTickOffset => 0,
        yTickOffset => 0,
        chartAnchorX => $self->plotOption( 'axisMarginLeft' ) + ( $yLabelWidth + $self->get('xTickOutset') + $self->get('xLabelTickOffset')),
        chartAnchorY => $self->plotOption( 'axisMarginTop'  ) + ( $xLabelHeight+ $self->get('xTickOutset') + $self->get('xLabelTickOffset')),
    );
print "[[", $self->plotOption( 'chartAnchorY' ), "]]\n";

    return ( $minX, $maxX, $minY, $maxY );
};


sub definition {
    my $self = shift;

    my %def = (
        xExpandRange    => 0,
    );

    return { %{ $self->SUPER::definition }, %def };
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
print "box\n";

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
print "rulers\n";   

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

print "bbb\n";
    for ( @{ $self->getYTicks } ) {
print "$_\n";

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
print "ticks\n";

    my $maxX = $self->get('xStop');
    my $maxY = $self->get('yStop');
    
    my $tickFrom = $maxY - $self->get('xTickInset')  / $self->plotOption('yPxPerUnit') ;
    my $tickTo   = $maxY + $self->get('xTickOutset') / $self->plotOption('yPxPerUnit') ;

    for my $tick ( @{ $self->getXTicks } ) { #( 0 .. 7 ) {
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
        my $valign = 'center';

        my ($x, $y) = $self->project( [ $tick ], [ $tickTo + $self->get('xLabelTickOffset') / $self->plotOption('yPxPerUnit')   ] );


        $self->text(
            text        => $self->getTickLabel( $tick, 0 ),
            halign      => $halign, 
            valign      => $valign,
            align       => lcfirst $halign,
            font        => $self->get('labelFont'),
            pointsize   => $self->get('labelFontSize'),
            style       => 'Normal',
            fill        => $self->get('labelColor'),
            x           => $x,
            y           => $y,
        );
    }

    
}


=head2 preprocessData ()

See Chart::Magick::Axis::preprocessData.

=cut

sub preprocessData {
    my $self = shift;

    $self->SUPER::preprocessData;
    
#    my ($minX, $maxX, $minY, $maxY) = map { $_->[0] } $self->getDataRange;
#print "[$minX, $maxX, $minY, $maxY]\n";
    
#    $self->{ _xPerDegree } = 2 * pi / $maxX;
#    $self->{ _yRange     } = $maxY;
#    $self->plotOption( yPxPerUnit => $self->getChartHeight / 2 / $maxY );
}

=head2 project ( coord, value )

See Chart::Magick::Axis::project.

=cut

sub project {
    my $self    = shift;
    my $coord   = shift;
    my $value   = shift;

    my $angle   = $coord->[0] * $self->getPxPerXUnit;
    my $centerX = $self->plotOption( 'chartAnchorX' ) + $self->getChartWidth  / 2;
    my $centerY = $self->plotOption( 'chartAnchorY' ) + $self->getChartHeight / 2;
    my $scale   = $self->plotOption( 'yPxPerUnit' );

print $self->plotOption( 'chartAnchorY' ) ," ", $self->getChartHeight, "\n";

    return (
        $centerX + $scale * $value->[0] * cos $angle,
        $centerY - $scale * $value->[0] * sin $angle,
    );
}

1;

