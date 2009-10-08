package Chart::Magick::Axis::Lin;

use strict;

use base qw{ Chart::Magick::Axis };
use List::Util qw{ min max reduce };
use Text::Wrap;
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
        minTickWidth    => 25,

        xAxisLocation   => undef,
        xTickOffset     => 0,

        xTickCount      => undef,
        xTickWidth      => 0,
        xTickInset      => 4,
        xTickOutset     => 8,

        xSubtickCount   => 0,
        xSubtickInset   => 2,
        xSubtickOutset  => 2,
        xTicks          => [ ],

        xLabelFormat    => '%s',
        xLabelUnits     => 1,

        xTitleBorderOffset  => 0,
        xTitleLabelOffset   => 10,
        xLabelTickOffset    => 3,

#        xDrawRulers
        xTitle          => '',
        xTitleFont      => sub { $_[0]->get('font') },
        xTitleFontSize  => sub { int $_[0]->get('fontSize') * 1.5 },
        xTitleColor     => sub { $_[0]->get('fontColor') },
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

        yTitle          => '',
        yTitleFont      => sub { $_[0]->get('font') },
        yTitleFontSize  => sub { int $_[0]->get('fontSize') * 1.5 },
        yTitleColor     => sub { $_[0]->get('fontColor') },
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
=head2 getChartWidth ( )

Returns the width of charts on the Axis in pixels.

=cut

sub getChartWidth { 
    my $self = shift;

    return $self->plotOption( 'chartWidth' );
}

#---------------------------------------------
#TODO: move to superclass?
=head2 getChartHeight ( )

Returns the height of charts on the Axis in pixels.

=cut

sub getChartHeight {
    my $self = shift;

    return $self->plotOption( 'chartHeight' );
}

#---------------------------------------------
sub getCoordDimension {
    return 1;
}

#---------------------------------------------
sub getValueDimension {
    return 1;
}


sub getXTickLabel {
    my $self    = shift;
    my $value   = shift;

    my $label   =     
        $self->getLabels( 0, $value )
        || sprintf( $self->get('xLabelFormat'), $value / $self->get('xLabelUnits') );

    return $label;
}

sub getYTickLabel {
    my $self    = shift;
    my $value   = shift;

    my $label   =     
        $self->getLabels( 1, $value )
        || sprintf( $self->get('yLabelFormat'), $value / $self->get('yLabelUnits') );

    return $label;
}

sub optimizeMargins {
    my $self = shift;

    my $baseWidth   = $self->plotOption( 'axisWidth' )  - $self->plotOption( 'axisMarginLeft' ) - $self->plotOption( 'axisMarginRight'  );
    my $baseHeight  = $self->plotOption( 'axisHeight' ) - $self->plotOption( 'axisMarginTop'  ) - $self->plotOption( 'axisMarginBottom' );
    my $yLabelWidth = 0;
    my $xLabelWidth = 0;
    my $prevXLabelWidth = 0;
    my $prevYLabelWidth = 0;

    my $ready;
    while ( !$ready ) {
        my ($minX, $maxX, $minY, $maxY) = @_;

        # Calc current chart dimensions
        my $chartWidth  = $baseWidth  - $yLabelWidth;
        my $chartHeight = $baseHeight - $xLabelWidth;

        # Calc tick width
        my $xTickWidth = 
            $self->calcTickWidth( 
                $minX, $maxX, $chartWidth, $self->get('xTickCount'), $self->get('xLabelUnits') 
            );
        my $yTickWidth = 
            $self->calcTickWidth( 
                $minY, $maxY, $chartHeight, $self->get('yTickCount'), $self->get('yLabelUnits') 
            );

        # Adjust the chart ranges so that they align with the 0 axes if desired.
        if ( $self->get('alignAxesWithTicks') ) {
            $minY = floor( $minY / $yTickWidth ) * $yTickWidth;
            $maxY = ceil ( $maxY / $yTickWidth ) * $yTickWidth;
            $minX = floor( $minX / $xTickWidth ) * $xTickWidth;
            $maxX = ceil ( $maxX / $xTickWidth ) * $xTickWidth;
        }   

        # Get ticks
        my @xLabels = map { $self->getXTickLabel( $_ ) } @{ $self->generateTicks( $minX, $maxX, $xTickWidth ) };
        my @yLabels = map { $self->getYTickLabel( $_ ) } @{ $self->generateTicks( $minY, $maxY, $yTickWidth ) };

        my $xUnits      = ( $self->transformX( $maxX ) - $self->transformX( $minX ) ) || 1;
        my $xAddUnit    = $self->get('xTickOffset');
        my $xPxPerUnit  = $chartWidth / ( $xUnits + $xAddUnit );
        my $yPxPerUnit  = $chartHeight / ( $maxY - $minY );

#        # Determine the pixel location of (0,0) within the canvas.
#        my $originX     = $self->plotOption( 'axisMarginLeft' ) + $self->get( 'marginLeft' );           # left border of axis
#        $originX       -= $self->get( 'xStart' ) * $self->getPxPerXUnit if $self->get( 'xStart' ) < 0;  # x position origin
#        my $originY     = $self->plotOption( 'axisMarginTop'  ) + $self->get( 'marginTop'  );           # bottom border of axis
#        $originY       += $self->get( 'yStop' )  * $self->getPxPerYUnit;                                # 
        # Determine the pixel location of (0,0) within the canvas.
        my $originX     = $self->plotOption( 'axisMarginLeft' ) + $self->get( 'marginLeft' );           # left border of axis
        $originX       -= $minX * $xPxPerUnit if $minX < 0;  # x position origin
        my $originY     = $self->plotOption( 'axisMarginTop'  ) + $self->get( 'marginTop'  );           # bottom border of axis
        $originY       += $maxY * $yPxPerUnit;                                                          # 

        my $chartAnchorX = $self->get('marginLeft') + $self->plotOption('axisMarginLeft');
        my $chartAnchorY = $self->get('marginTop' ) + $self->plotOption('axisMarginTop' );

        $self->plotOption( originX      => $originX );
        $self->plotOption( originY      => $originY );
        $self->plotOption( chartAnchorX => $self->get('marginLeft') + $self->plotOption('axisMarginLeft') );
        $self->plotOption( chartAnchorY => $self->get('marginTop' ) + $self->plotOption('axisMarginTop' ) );

        # Calc max label lengths
        $xLabelWidth = ceil max map { int $self->getLabelDimensions( $_, $xTickWidth * $xPxPerUnit )->[1] } @xLabels; 
        $yLabelWidth = ceil max map { int $self->getLabelDimensions( $_ )->[1] } @yLabels;
    
        # Adjust label sizes to
        unless ( $self->get('axesOutside') ) {
            $xLabelWidth = ceil max 0, $xLabelWidth - ( $chartAnchorY + $chartHeight - $originY );
        }

        if ( $prevXLabelWidth == $xLabelWidth && $prevYLabelWidth == $yLabelWidth ) {
            $ready = 1;
            $self->set( 
                xTickWidth  => $xTickWidth,
                yTickWidth  => $yTickWidth,
            );
            $self->plotOption( 
                chartWidth      => $chartWidth,
                chartHeight     => $chartHeight,
                xPxPerUnit      => $xPxPerUnit,
                xTickOffset     => $xAddUnit / 2 * $xPxPerUnit,
                yPxPerUnit      => $yPxPerUnit,
                axisMarginLeft  => $self->plotOption( 'axisMarginLeft' ) + $yLabelWidth,
                axisMarginBottom=> $self->plotOption( 'axisMarginBottom' ) + $yLabelWidth, 
            );

            return ($minX, $maxX, $minY, $maxY);
        }

        $prevXLabelWidth = $xLabelWidth;
        $prevYLabelWidth = $yLabelWidth;
    }
}



sub getLabelDimensions {
    my $self        = shift;
    my $label       = shift;
    my $wrapWidth   = shift;

    my %properties = (
        text        => $label,
        font        => $self->get('labelFont'),
        pointsize   => $self->get('labelFontSize'),
    );

    my ($w, $h) = ( $self->im->QueryFontMetrics( %properties ) )[4,5];
    
    if ( $wrapWidth && $w > $wrapWidth ) {
        # This is not guaranteed to work in every case, but it'll do for now.
        local $Text::Wrap::columns = int( $wrapWidth / $w * length $label );
        $properties{ text } = join qq{\n}, wrap( q{}, q{}, $label );

        ($w, $h) = ( $self->im->QueryMultilineFontMetrics( %properties ) )[4,5];
    }

    return [ $w, $h ];
}


#### TODO: Dit anders noemen...
#---------------------------------------------

=head2 calcBaseMargins ( )

Calcs and sets the base margins of the axis.

=cut

sub calcBaseMargins {
    my $self = shift;

    # calc axisMarginLeft
    my $yTitleWidth = ($self->im->QueryFontMetrics(
        text        => $self->get('yTitle'),
        font        => $self->get('yTitleFont'),
        pointsize   => $self->get('yTitleFontSize'),
        rotate      => -90,
    ))[5];
    $self->plotOption( yTitleWidth => $yTitleWidth      );

    my $axisMarginLeft  = 
        $self->get('yTitleBorderOffset') + $self->get('yTitleLabelOffset') 
        + $self->get('yLabelTickOffset') + $self->get('yTickOutset') 
        + $yTitleWidth;
    
    $self->plotOption( axisMarginLeft => $axisMarginLeft   );

    #------------------------------------
    # calc axisMarginBottom
    my $xTitleHeight = $self->get('xTitle') 
        ? ($self->im->QueryFontMetrics(
                text        => $self->get('xTitle'),
                font        => $self->get('xTitleFont'),
                pointsize   => $self->get('xTitleFontSize'),
          ) )[5]
        : 0
        ;
    $self->plotOption( xTitleHeight => $xTitleHeight );
    my $axisMarginBottom = 
        $self->get('xTitleBorderOffset') + $self->get('xTitleLabelOffset') 
        + $self->get('xLabelTickOffset') + $self->get('xTickOutset') 
        + $xTitleHeight;

    $self->plotOption( axisMarginBottom  => $axisMarginBottom );

    #-------------------------------------
    # calc axisMarginRight
    $self->plotOption( axisMarginRight => 0 );

    # calc axisMarginTop
    $self->plotOption( axisMarginTop => 0 );
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

=head2 calcTickWidth ( from, to, [ count ] )

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
    my $pxRange = shift;
    my $count   = shift;
    my $unit    = shift || 1;

    $from   /= $unit;
    $to     /= $unit;

    if (defined $count) {
        return ($to - $from) if $count <= 1;
        return ($to - $from) / ($count - 1);
    }

    # Make sure we always have a range to draw a graph on.
    my $range       = $to - $from || $to || 1;

    # The tick width is initially calculated to a power of 10. The order of the power is chosen to be one less than
    # the order of the range.
    # The 0.6 is a factor used to influence rounding. Use 0.5 for arithmetic rounding.
    my $order       = int( log( $range ) / log( 10 ) + 0.6 );
    my $tickWidth   = 10 ** ( $order - 1 );

    # To prevent ticks from being to close to each other, we first calc the approximate tick width in pixels...
    my $approxPxPerTick = $pxRange / $range * $tickWidth;

    # ... and then check that width against the minTickWidth treshold. Continue to expand the tick width with
    # base10-aligned factors until we have something suitable.
    for my $expand ( 1, 1.25, 2, 2.5, 5, 10, 20, 50, 100, 1000 ) {
        return $tickWidth * $expand * $unit if ($approxPxPerTick * $expand) > $self->get('minTickWidth');
    }

    return $tickWidth * $unit;
}

#---------------------------------------------

=head2 preprocessData ( )

Does the calculations and data massaging required for rendering the graph.

You'll probably never need to call this method manually.

=cut

sub preprocessData {
    my $self = shift;

    $self->SUPER::preprocessData;

    # Get the extreme values of the data, so we can determine what values the axis should at leat span.
    my ($minX, $maxX, $minY, $maxY) = map { $_->[0] } $self->getDataRange;

    # The treshold variable is used to determine when the y=0 axis should be include in the chart
    my $treshold = 0.4;
    
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

    # Handle case when y equal zero for all coords. 
    $maxY = 1 if ($minY == 0 && $maxY == 0);

    # Determine the space occupied by margin stuff like labels and the like. This als sets the chart width and
    # height in terms of pixels that can be used to draw charts on.
    $self->calcBaseMargins;

    ($minX, $maxX, $minY, $maxY) = $self->optimizeMargins( $minX, $maxX, $minY, $maxY );

    # Store the calulated values in the object and generate the tick locations based on the tick width.
    $self->set( 'yStop',    $maxY );
    $self->set( 'yStart',   $minY );
    $self->set( 'yTicks',   $self->generateTicks( $minY, $maxY, $self->get( 'yTickWidth' ) ) );

    $self->set( 'xStop',    $maxX );
    $self->set( 'xStart',   $minX );
    $self->set( 'xTicks',   $self->generateTicks( $minX, $maxX, $self->get( 'xTickWidth' ) ) );

    # Determine the pixel location of (0,0) within the canvas.
    my $originX     = $self->plotOption( 'axisMarginLeft' ) + $self->get( 'marginLeft' );           # left border of axis
    $originX       -= $self->get( 'xStart' ) * $self->getPxPerXUnit if $self->get( 'xStart' ) < 0;  # x position origin
    my $originY     = $self->plotOption( 'axisMarginTop'  ) + $self->get( 'marginTop'  );           # bottom border of axis
    $originY       += $self->get( 'yStop' )  * $self->getPxPerYUnit;                                # 

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

    my ( $xStart, $xStop, $yStart, $yStop ) = ( 
        $self->get('xStart'), $self->get('xStop'), $self->get('yStart'), $self->get('yStop') 
    );

    my $xFrom   = int $self->plotOption('chartAnchorX');
    my $xTo     = $xFrom + $self->getChartWidth;
    my $yFrom   = int $self->plotOption('chartAnchorY');
    my $yTo     = $yFrom + $self->getChartHeight;
    my $xYPos   = $yStart * $yStop <= 0     ? $self->toPxY( 0 )
                : $yStart > 0               ? $yFrom
                :                             $yTo;
    my $yXPos   = $xStart * $yStop <= 0     ? $self->toPxX( 0 )
                : $xStart > 0               ? $xFrom 
                :                             $xTo;

    # Main axes
    $self->im->Draw(
        primitive   => 'Path',
        stroke      => 'black', #$self->getAxisColor,
        points      =>
               " M $xFrom,$xYPos L $xTo,$xYPos "
             . " M $yXPos,$yFrom L $yXPos,$yTo ",
        fill        => 'none',
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
        my $x   = int $self->toPxX( $tick );
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

    my $xOffset = $ticksOutside ? int $self->plotOption('chartAnchorX') : int $self->plotOption('originX');
    my $yOffset = $ticksOutside ? int $self->plotOption('chartAnchorY') + $self->plotOption('chartHeight') : int $self->plotOption('originY');

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

        my $x       = $outset - $self->get('yLabelTickOffset');

        my $value   = sprintf( $self->get('yLabelFormat'), $tick / $self->get('yLabelUnits') );
        $self->text(
            text        => $self->getLabels( 1, $value ) || $value,     #sprintf( $self->get('yLabelFormat'), $tick / $self->get('yLabelUnits') ),
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
        my $x = int $self->toPxX( $tick );

        my $inset   = $yOffset - $self->get('xTickInset');
        my $outset  = $yOffset + $self->get('xTickOutset');

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => 'black',
            points      => " M $x,$outset L $x,$inset ",
            fill        => 'none',
        );

        my $y = $outset + $self->get('xLabelTickOffset');
        my $value = sprintf( $self->get('xLabelFormat'), $tick / $self->get('xLabelUnits') );
        $self->textWrap(
            text        => $self->getLabels( 0, $value ) || $value,
            font        => $self->get('labelFont'),
            halign      => 'center',
            valign      => 'top',
            align       => 'Center',
            pointsize   => $self->get('labelFontSize'),
            style       => 'Normal',
            fill        => $self->get('labelColor'),
            x           => $x,
            y           => $y,
            wrapWidth   => $self->get('xTickWidth') * $self->plotOption( 'xPxPerUnit' ),
        );
    }

    # X sub ticks
    foreach my $tick ( @{ $self->getXSubticks } ) {
        my $x = int $self->toPxX( $tick );

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
    return $_[1];
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

#---------------------------------------------

=head2 toPxX ( x )

Transform an x coordinate to pixel coordinates.

=cut

sub toPxX {
    my $self    = shift;
    my $coord   = shift;

    my $x = 
          $self->plotOption('chartAnchorX') 
        + $self->plotOption('xTickOffset') 
        + $self->transformX( $coord                 ) * $self->getPxPerXUnit
        - $self->transformX( $self->get('xStart')   ) * $self->getPxPerXUnit;

    return int $x;
}

#---------------------------------------------

=head2 toPxY ( y )

Transform an y coordinate to pixel coordinates.

=cut

sub toPxY {
    my $self    = shift;
    my $coord   = shift;

    my $y = 
          $self->plotOption('chartAnchorY') 
        + $self->getChartHeight 
        - $self->transformY( $coord                 ) * $self->getPxPerYUnit
        + $self->transformY( $self->get('yStart')   ) * $self->getPxPerYUnit;

    return int $y;
}


=head2 project ( x, y )

Projects a coord/value pair onto the canvas and returns the x/y pixel values of the projection.

=cut

sub project {
    my $self    = shift;
    my $coords  = shift;
    my $values  = shift;

    return ( 
        $self->toPxX( $coords->[0] ), 
        $self->toPxY( $values->[0] ) 
    );
}


1;

