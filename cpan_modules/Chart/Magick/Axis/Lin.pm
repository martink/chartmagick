package Chart::Magick::Axis::Lin;

use strict;

use base qw{ Chart::Magick::Axis };
use List::Util qw{ min max reduce };
use POSIX qw{ floor ceil };

=head1 NAME

Chart::Magick::Axis::Lin - A 2d coordinates system with linear axes.

=head1 SYNOPSIS


=head1 DESCRIPTION

An Axis plugin for the Chart::Margick class of modules, providing a coordinate system for xy type graphs.

The following methods are available from this class:

=cut

#---------------------------------------------

=head2 definition ( )

Defines additional properties for this class:

=cut

sub definition {
    my $self = shift;
    my %options = (
        xAxisLocation   => undef,
        xTickOffset     => 0,

        xTickCount      => undef,
        xTickWidth      => 0,
        xTickInset      => 4,
        xTickOutset     => 8,

        xSubtickCount   => 10,
        xSubtickInset   => 2,
        xSubtickOutset  => 2,
        xTicks          => [ ],

        xLabelFormat    => '%s',
        xLabelUnits     => 1,

        xTitleBorderOffset  => 0,
        xTitleLabelOffset   => 10,
        xLabelTickOffset    => 3,

#        xDrawRulers
        xTitle          => 'x-title',
        xTitleColor     => 'green',
        xTitleFont      => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
        xTitleFontSize  => 15,
#        xTitleAngle
#        xLabelAngle
        xStart          => 1,
        xStop           => 5,

        centerChart     => 0,
        yTickCount      => undef,
        yTickWidth      => 0,
        yTickInset      => 3,
        yTickOutset     => 6,
        ySubtickCount   => 0,
        ySubtickInset   => 2,
        ySubtickOutset  => 2,
        yTicks          => [ ],
#        yDrawRulers

        yTitle          => 'y-label-label-label',
        yTitleColor     => 'green',
        yTitleFont      => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
        yTitleFontSize  => 10,
#        yTitleAngle
#        yLabelAngle
        yStart          => 1,
        yStop           => 5,

        yIncludeOrigin  => 0,

        yLabelFormat    => '%.1f',
        yLabelUnits     => 1,

        yTitleBorderOffset  => 0,
        yTitleLabelOffset   => 10,
        yLabelTickOffset    => 3,

#        axisColor
        axesOutside         => 1,
        alignAxesWithTicks  => 1,
    );

    return { %{ $self->SUPER::definition }, %options };
}

#---------------------------------------------
#TODO: move to superclass?
=getChartWidth ( )

Returns the width of charts on the Axis in pixels.

=cut

sub getChartWidth { 
    my $self = shift;

    return $self->plotOption( 'chartWidth' );
}

#---------------------------------------------
#TODO: move to superclass?
=getChartHeight ( )

Returns the height of charts on the Axis in pixels.

=cut

sub getChartHeight {
    my $self = shift;

    return $self->plotOption( 'chartHeight' );
}

#### TODO: Dit anders noemen...
#---------------------------------------------

=head2 autoRangeMargins ( )

=cut

sub autoRangeMargins {
    my $self = shift;
   
    my $yTicks = $self->getYTicks;

    # Find the label with the most characters
    my $yMaxLabel = reduce { length($b) < length($a) ? $a : $b } @{ $yTicks };

    my ($yLabelWidth, $labelHeight) = ($self->im->QueryFontMetrics(
        text        => $yMaxLabel,
        font        => $self->get('labelFont'),
        pointsize   => $self->get('labelFontSize'),
    ))[4,5];

    my $yTitleWidth = ($self->im->QueryFontMetrics(
        text        => $self->get('yTitle'),
        font        => $self->get('yTitleFont'),
        pointsize   => $self->get('yTitleFontSize'),
        rotate      => -90,
    ))[5];

    my $axisMarginRight = 0;
    my $axisMarginLeft  = 
        $self->get('yTitleBorderOffset') + $self->get('yTitleLabelOffset') 
        + $self->get('yLabelTickOffset') + $self->get('yTickOutset') 
        + $yTitleWidth + $yLabelWidth;

    $self->plotOption( yLabelWidth     => $yLabelWidth      );
    $self->plotOption( yTitleWidth     => $yTitleWidth      );
    $self->plotOption( axisMarginRight => 0                 );
    $self->plotOption( axisMarginLeft  => $axisMarginLeft   );
    $self->plotOption( chartWidth      => 
        $self->plotOption( 'axisWidth' ) - $axisMarginLeft - $axisMarginRight
    );
    
    my $xTitleHeight = ($self->im->QueryFontMetrics(
        text        => $self->get('xTitle'),
        font        => $self->get('xTitleFont'),
        pointsize   => $self->get('xTitleFontSize'),
        rotate      => 0,
    ))[5];

    my $axisMarginTop       = 0;
    my $axisMarginBottom    = $xTitleHeight + $labelHeight + $self->get('xTickOutset') + 2 + 5;
    $self->plotOption( axisMarginTop    => $axisMarginTop );
    $self->plotOption( axisMarginBottom => $axisMarginBottom );
    $self->plotOption( chartHeight      =>
        $self->plotOption( 'axisHeight' ) - $axisMarginTop - $axisMarginBottom
    );
}

#---------------------------------------------

=head2 generateTicks ( from, to, width )

Generates tick locations spaced at a certain width. Tick will be generated in such a way that they are aligned with
value zero. This could lead to from and to values that are different from those passed as arguments.

=head3 from

The highest value at which ticks can start.

=head3 to

The lowest value at which the ticks can stop.

=head3 width

The spacing between two subsequent ticks.

=cut

sub generateTicks {
    my $self    = shift;
    my $from    = shift;
    my $to      = shift;
    my $width   = shift;

    # Figure out the first tick so that the ticks will align with zero.
    my $firstTick = int( $from / $width ) * $width;

    # This is actually actual (number_of_ticks - 1), but below we start counting at 0, so for our purposes it is
    # the correct amount.
    my $tickCount = int( ( $to - $firstTick ) / $width );

    # generate the ticks
    my $ticks   = [ map { $_ * $width + $firstTick } ( 0 .. $tickCount ) ];

    return $ticks;
}

#---------------------------------------------

=head2 calcTckWidth ( from, to, [ count ] )

Returns the tick spacing for a given number of ticks within a given interval. If the number of ticks is omitted the
tick spacing will be calculated in such way that the tick spacing is of an order less that the range of the
interval.

=head3 from

The lower bound of the interval.

=head3 to

The upper bound of the interval.

=head3 count

Optional. Desired number of ticks within the interval.

=cut 

sub calcTickWidth {
    my $self    = shift;
    my $from    = shift;
    my $to      = shift;
    my $count   = shift;

    if (defined $count) {
        return ($to - $from) if $count <= 1;
        return ($to - $from) / ($count - 1);
    }

    my $range       = $to - $from || $to || 1;
    # The 0.6 is a factor used to influence rounding. Use 0.5 for arithmetic rounding.
    my $order       = int( log( $range ) / log(10) + 0.6 );
    my $tickWidth   = 10 ** ( $order - 1 );

    return $tickWidth;
}

#---------------------------------------------

=head2 preprocessData ( )

Does the calculations and data massaging required for rendering the graph.

You'll probably never need to call this method manually.

=cut

sub preprocessData {
    my $self = shift;

    $self->SUPER::preprocessData;

    # Autoranging
    my ($minX, $maxX, $minY, $maxY) = $self->getExtremeValues;
    #$minX=0;

    # y stuff

    # The treshold variable is used to determine when the y=0 axis should be include in teh chart
    my $treshold = 0.1;
    
    # Figure out whether we want to let the y axis include 0.
    if ( ($maxX > 0 &&  $minY > 0) || ($maxX < 0 && $maxY < 0) ) {
        # dataset does not cross x axis.
        if ( 
            $self->get('yIncludeOrigin') 
            || $minY == $maxY
            || abs( ( $maxY - $minY ) / $minY ) > $treshold 
        ) {
            $minY   = 0 if $minY > 0;
            $maxY   = 0 if $maxY < 0;
        }
    }

    $maxY = 1 if ($minY == 0 && $maxY == 0);
###############################
    my $yTickWidth = $self->get('yTickWidth') || $self->calcTickWidth( $minY, $maxY, $self->get('yTickCount') );
    my $xTickWidth = $self->get('xTickWidth') || $self->calcTickWidth( $minX, $maxX, $self->get('xTickCount') );

    if ( $self->get('alignAxesWithTicks') ) {
        $minY = floor( $minY / $yTickWidth ) * $yTickWidth;
        $maxY = ceil ( $maxY / $yTickWidth ) * $yTickWidth;
        $minX = floor( $minX / $xTickWidth ) * $xTickWidth;
        $maxX = ceil ( $maxX / $xTickWidth ) * $xTickWidth;
    }

    $self->set( 'yStop',    $maxY );
    $self->set( 'yStart',   $minY );
    $self->set( 'yTicks',   $self->generateTicks( $minY, $maxY, $yTickWidth ) );

    $self->set( 'xStop',    $maxX );
    $self->set( 'xStart',   $minX );
    $self->set( 'xTicks',   $self->generateTicks( $minX, $maxX, $xTickWidth ) );

###############################

    $self->autoRangeMargins;
    # Calculate the pixels per unit in the y axis.
    my $yPxPerUnit = $self->plotOption( 'chartHeight' ) / ( $maxY - $minY );
    $self->plotOption( yPxPerUnit => $yPxPerUnit );

    # Calculate the pixels per unit on the x axis.
    my $xDataWidth  = ( $self->transformX( $maxX ) - $self->transformX( $minX ) ) || 1;
    my $indent      = $self->get('xTickOffset'); #* $xTickWidth;
    my $xPxPerUnit  = ($self->plotOption( 'chartWidth' ) - 2 * $indent) / $xDataWidth ;
    $self->plotOption( xPxPerUnit   => $xPxPerUnit );
    $self->plotOption( xTickOffset  => $indent );#* $xPxPerUnit);

    # Determine to location of (0,0)
    my $originX     = $self->plotOption( 'axisMarginLeft' ) + $self->get( 'marginLeft' );
    $originX       -= $self->get( 'xStart' ) * $self->getPxPerXUnit if $self->get( 'xStart' ) < 0;
    my $originY     = $self->plotOption( 'axisMarginTop'  ) + $self->get( 'marginTop'  );
    $originY       += $self->get( 'yStop' )  * $self->getPxPerYUnit;

    $self->plotOption( originX      => $originX );
    $self->plotOption( originY      => $originY );
    $self->plotOption( chartAnchorX => $self->get('marginLeft') + $self->plotOption('axisMarginLeft') );
    $self->plotOption( chartAnchorY => $self->get('marginTop' ) + $self->plotOption('axisMarginTop' ) );
}

#---------------------------------------------

=head2 getXTicks ( ) 

Returns the locations of the ticks on the x axis in chart x coordinates.

=cut

sub getXTicks {
    my $self = shift;
   
    return $self->get('xTicks');
}

#---------------------------------------------

=head2 generateSubTicks ( ticks, count )

Returns an array ref containing the locations of subticks for a given series of tick locations and a number of
subtick per tick interval.

=head3 ticks

Array ref containing the values of the ticks between which the subticks should be placed. The tick values should be
ordered.

=head3 count

The number of subtick per tick interval.

=cut

sub generateSubticks {
    my $self    = shift;
    my $ticks   = shift || [];
    my $count   = shift;

    return [] unless $count;

    return [] unless @{ $ticks };

    my @subticks;
    for my $i ( 1 .. scalar( @{ $ticks } ) -1 ) {
        my $j = $i - 1;
        my $prev  = $ticks->[ $j ];
        my $this  = $ticks->[ $i ];
        my $width = ($this - $prev) / $count;

        push @subticks, map { $prev + $_ * $width } (0 .. $count - 1 );
    }

    return \@subticks;
}

#---------------------------------------------

=head2 getXSubticks ( )

Returns an array ref containing the locations of the subticks on the x axis in chart x coordinates.

=cut

sub getXSubticks {
    my $self = shift;

    return $self->generateSubticks( $self->getXTicks, $self->get('xSubtickCount') );
}

#---------------------------------------------

=head2 getYTicks ( )

Returns an array ref containing the locations of the ticks on the y axis in chart y coordinates.

=cut

sub getYTicks {
    my $self = shift;
   
    return $self->get('yTicks');
}

#---------------------------------------------

=head2 getYSubticks ( )

Returns an array ref containing the locations of the subticks on the y axis in chart y coordinates.

=cut

sub getYSubticks {
    my $self = shift;

    return $self->generateSubticks( $self->getYTicks, $self->get('ySubtickCount') );
}

#---------------------------------------------

=head2 plotAxes ( )

Draws the axes.

You'll probably never need to call this method manually.

=cut

sub plotAxes {
    my $self = shift;
    
    my $ticksOutside = $self->get('axesOutside');
    
    my $xStart  = int $self->plotOption('chartAnchorX'); #int $self->toPxX( $ticksOutside ? $self->get('xStart') : 0 );
    my $xStop   = $xStart + $self->getChartWidth; 
    my $yStart  = int $self->plotOption('chartAnchorY'); #int $self->toPxY( $ticksOutside ? $self->get('yStart') : 0 );
    my $yStop   = $yStart + $self->getChartHeight;

    # Main axes
    $self->im->Draw(
        primitive   => 'Path',
        stroke      => 'black', #$self->getAxisColor,
        points      =>
              " M $xStart,$yStop L $xStart,$yStart "
            . " M $xStop,$yStop L $xStart,$yStop ",
        fill        => 'none',
        gravity     => 'Center',
    );

    # X label
    $self->text(
        text        => $self->get('xTitle'),
        font        => $self->get('xTitleFont'),
        pointsize   => $self->get('xTitleFontSize'),
        fill        => $self->get('xTitleColor'),
        halign      => 'center',
        valign      => 'bottom',
        x           => $self->getChartWidth / 2 + $self->get('marginLeft') + $self->plotOption('axisMarginLeft'), 
        y           => $self->get('height') - $self->get('marginBottom') - $self->get('xTitleBorderOffset'),
        rotate      => 0,
    );

    # Y label
    $self->text(
        text        => $self->get('yTitle'),
        font        => $self->get('yTitleFont'),
        pointsize   => $self->get('yTitleFontSize'),
        fill        => $self->get('yTitleColor'),
        halign      => 'center',
        valign      => 'top',
        x           => $self->get('marginLeft') + $self->get('yTitleBorderOffset'),
        y           => $self->getChartHeight / 2 + $self->get('marginTop') + $self->plotOption('axisMarginTop'),
        rotate      => -90,
    );

}

#---------------------------------------------

=head2 plotRulers ( )

Draws the rulers.

You'll probably never need to call this method manually.

=cut

sub plotRulers {
    my $self = shift;

    for my $tick ( @{ $self->getYTicks }, @{ $self->getYSubticks } ) {
        my $y   = int $self->toPxY( $tick );
        my $x1  = $self->plotOption('chartAnchorX'); #int $self->toPxX( $self->get( 'xStart' ) );
        my $x2  = $x1 + $self->plotOption('chartWidth'); #int $self->toPxX( $self->get( 'xStop'  ) );

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => 'lightgrey',
            points      => " M $x1,$y L $x2,$y ",
            fill        => 'none',
        );
        
    }

    for my $tick ( @{ $self->getXTicks }, @{ $self->getXSubticks } ) {
        my $x   = int $self->toPxX( $tick ); # + $self->plotOption( 'xTickOffset' );
        my $y1  = int $self->toPxY( $self->get('yStop' ) );
        my $y2  = int $self->toPxY( $self->get('yStart') );

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => 'lightgrey',
            points      => " M $x,$y1 L $x,$y2 ",
            fill        => 'none',
        );
     }
}

#---------------------------------------------

=head2 plotTicks ( )

Draws the ticks and subticks.

You'll probably never need to call this method manually.

=cut

sub plotTicks {
    my $self = shift;

    my $ticksOutside = $self->get('axesOutside');

    my $xOffset = $ticksOutside ? $self->plotOption('chartAnchorX') : int $self->toPxX( 0 );
    my $yOffset = int $self->toPxY( $ticksOutside ? $self->get('yStart') : 0 );

    # Y Ticks
    foreach my $tick ( @{ $self->getYTicks } ) {
        my $y       = int $self->toPxY( $tick );
        my $inset   = $xOffset + $self->get('yTickInset');
        my $outset  = $xOffset - $self->get('yTickOutset');

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => 'black',
            points      => " M $outset,$y L $inset,$y ",
            fill        => 'none',
        );

        my $x = $outset - $self->get('yLabelTickOffset');

        $self->text(
            text        =>  sprintf( $self->get('yLabelFormat'), $tick / $self->get('yLabelUnits') ),
            halign      => 'right',
            valign      => 'center',
            align       => 'Right',
            font        => $self->get('labelFont'),
            pointsize   => $self->get('labelFontSize'),
            style       => 'Normal',
            fill        => $self->get('labelColor'),
            x           => $x,
            y           => $y,
        );
    }

    foreach my $tick ( @{ $self->getYSubticks } ) {
        my $y       = int $self->toPxY( $tick );
        my $inset   = $xOffset + $self->get('ySubtickInset');
        my $outset  = $xOffset - $self->get('ySubtickOutset');

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => 'black',
            points      => " M $outset,$y L $inset,$y ",
            fill        => 'none',
        );
    }


    # X main ticks
    foreach my $tick ( @{ $self->getXTicks } ) {
        my $x = int $self->toPxX( $tick ); # + $self->plotOption( 'xTickOffset' );

        my $inset   = $yOffset - $self->get('xTickInset');
        my $outset  = $yOffset + $self->get('xTickOutset');

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => 'black',
            points      => " M $x,$outset L $x,$inset ",
            fill        => 'none',
        );

        my $y = $outset + $self->get('xLabelTickOffset');
        $self->text(
            text        => sprintf( $self->get('xLabelFormat'), $tick / $self->get('xLabelUnits') ),
            font        => $self->get('labelFont'),
            halign      => 'center',
            valign      => 'top',
            align       => 'Center',
            pointsize   => $self->get('labelFontSize'),
            style       => 'Normal',
            fill        => $self->get('labelColor'),
            x           => $x,
            y           => $y,
        );
    }

    # X sub ticks
    foreach my $tick ( @{ $self->getXSubticks } ) {
        my $x = int $self->toPxX( $tick ); # + $self->plotOption( 'xTickOffset' );

        my $inset   = $yOffset - $self->get('xSubtickInset');
        my $outset  = $yOffset + $self->get('xSubtickOutset');

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => 'black',
            points      => " M $x,$outset L $x,$inset ",
            fill        => 'none',
        );
    }
}

#---------------------------------------------

=head2 plotFirst ( )

Makes sure that the rulers are drawn beneath the chat data.

See Chart::Magick::Axis for more info.

=cut

sub plotFirst {
    my $self = shift;

    $self->SUPER::plotFirst;

    $self->plotRulers;
}

#---------------------------------------------

=head2 plotLast ( )

Makes sure that axes and ticks are drawn on top of everything else.

See Chart::Magick::Axis for more info.

=cut

sub plotLast {
    my $self = shift;

    # Draw axis lines, ticks and labels
    
    $self->SUPER::plotLast;

    $self->plotTicks;
    $self->plotAxes;
}

# TODO: Remove type method?
#---------------------------------------------
sub type {
    return 'XY';
}

#---------------------------------------------

=head2 getExtremeValues ( )

Returns an array containing the minimum X, maximum X, minimum Y and maximum Y value of all the datasets included by
the charts put on this Axis object.

=cut

sub getExtremeValues {
    my $self = shift;
    my (@minX,@maxX,@minY,@maxY);
    foreach my $chart ( @{ $self->charts } ) {
        push @minX, $chart->dataset->globalData->{ minCoords }->[0];
        push @maxX, $chart->dataset->globalData->{ maxCoords }->[0];
        push @minY, $chart->dataset->globalData->{ minValue  };
        push @maxY, $chart->dataset->globalData->{ maxValue  };
    }

    return ( min( @minX ), max( @maxX ), min( @minY ), max( @maxY ) );
}

#---------------------------------------------

=head2 getPxPerXUnit ( )

Returns the number of pixels in a single unit in x coordinates. In this module this returns the number of pixel per
1 x.

=cut

sub getPxPerXUnit {
    my $self = shift;

    return $self->plotOption( 'xPxPerUnit' );

#    my $delta = $self->transformX( $self->get('xStop') ) - $self->transformX( $self->get('xStart') );
#    return $self->getChartWidth / $delta;
}

#---------------------------------------------

=head2 getPxPerYUnit ( )

Returns the number of pixels in a single unit in y coordinates. In this module this returns the number of pixel per
1 y.

=cut

sub getPxPerYUnit {
    my $self = shift;

    return $self->plotOption( 'yPxPerUnit' );

#   my $delta = $self->transformY( $self->get('yStop') ) - $self->transformY( $self->get('yStart') ) || 1;
#   return $self->getChartHeight / $delta;
}

#---------------------------------------------

=head2 transformX ( x )

Transforms the given x value to the units used by the coordinate system of this axis and returns the transformed coordinate.

=head3 x

The value to be transformed.

=cut

sub transformX {
    my $self    = shift;
    my $x       = shift;

    return $x - $self->get('xStart');
}

#---------------------------------------------

=head2 transformY ( y )

Transforms the given y value to the y units used by the coordinate system of this axis and returns the transformed coordinate.

=head3 y

The value to be transformed.

=cut

sub transformY {
    return $_[1];
}


# TODO: combine toPxX and toPxY so that polar coordinates are also viable.

#---------------------------------------------

=head2 toPxX ( x )

Transform an x coordinate to pixel coordinates.

=cut

sub toPxX {
    my $self    = shift;
    my $coord   = shift;

    my $x = $self->plotOption('originX') + $self->transformX( $coord ) * $self->getPxPerXUnit 
        + $self->plotOption('xTickOffset');

    return $x;
}

#---------------------------------------------

=head2 toPxY ( y )

Transform an y coordinate to pixel coordinates.

=cut

sub toPxY {
    my $self    = shift;
    my $coord   = shift;

    my $y = $self->plotOption('originY') - $self->transformY( $coord ) * $self->getPxPerYUnit;

    return $y;
}

1;

