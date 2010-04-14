package Chart::Magick::Axis::Lin;

use strict;
use warnings;

use List::Util qw{ min max reduce };
use Text::Wrap;
use POSIX qw{ floor ceil };
use Carp;

use base qw{ Chart::Magick::Axis };

=head1 NAME

Chart::Magick::Axis::Lin - A 2d coordinates system with linear axes.

=head1 SYNOPSIS


=head1 DESCRIPTION

An Axis plugin for the Chart::Margick class of modules, providing a coordinate system for xy type graphs.

The following methods are available from this class:

=cut

#---------------------------------------------

=head2 applyLayoutHints ( hints )

Applies the provided layout hints if applicable. See L<Chart::Magick::Axis::applyLayoutHints> for more information.

=head3 hints

Hash ref containing the hints. Chart::Magick::Axis::Lin processes the following hints:

=over 4

=item coordPadding

=item valuePadding

=item tickWidth

=back

=cut

sub applyLayoutHints {
    my $self    = shift;
    my $hints   = shift;

    if ( exists $hints->{ coordPadding } ) {
        $self->set( 'xTickOffset', max( $self->get('xTickOffset'), $hints->{ coordPadding }->[0] * 2 ) );
    };

    if ( exists $hints->{ valuePadding } ) {
        $self->set( 'yTickOffset', max( $self->get('yTickOffset'), $hints->{ valuePadding }->[0] * 2 ) );
    };

    if ( exists $hints->{ tickWidth    } ) {
        $self->set( 'xTickWidth', $hints->{ tickWidth } ) ;
    };

    return;
}

#---------------------------------------------

=head2 definition ( )

Defines additional properties for this class in addition to those defined in Chart::Magick::Axis::definition:

=over 4

=item plotBox

If set to a true value a box will be drawn around the charting area. Defaults to 1.

=item boxColor

The color of the box around the charting area. Defaults to 'black'.

=item plotAxes

If set to a true value the axis ( x = 0 and y = 0 ) will be drawn. This property can be overriden on a per axis
base by the x- and yPlotAxis properties. Defaults to 1.

=item axisColor

The color in which the axes should be drawn. Overridable on a per axis base by the x- and yAxisColor properties.
Defaults to grey50.

=item ticksOutside

If set to a true value the ticks will be drawn on the border of the charting area, otherwise the ticks will be
drawn directly on the x and y axes, even when they are inside the drawing area. If an axis lies outside the range
of the chart, the ticks are always drawn on the border of the charting area.

=item tickColor

The color of the ticks. Overridable per axis with x- and yTickColor. Defaults to the color set by the boxColor
property.
        
=item subtickColor

The color of the subticks. Overridable per axis with the x- and ySubtickColor properties. Defaults to the color set
by the tickColor property.

=item plotRulers

If set to a true value rulers wil bee drawn at tick positions. Overridable per axis via the x- and yPlotRulers
properties. Defaults to 1.

=item rulerColor

The color of the rulers. Overridable with the x- and yRulerColor properties. Defaults to 'lightgrey',

=item expandRange

If set to a true value the x and y ranges will be adjusted such that both start and end on tick positions. This
option is overridable on a per axis basis through the x- and yExpandRange options.

=item minTickWidth

Defines the minimum number of pixels that ticks should be apart. Used for autoranging ticks. Defaults to 25.
        
=back

Additionally there are properties you can set on a per axis basis. Listed below are the properties that work on the
x axis. The y axis properties are named the same except that they start with a y instead of an x.

=over 4

=item xTickCount

Sets the number of ticks on the x axis. If set to undef this value will be autoranged, which is what you want in
general. Note that this property will be ignored if xTickWidth is given. Defaults to undef.

=item xTickWidth

The width between two x axis ticks in terms of x axis values, not pixels. If set to 0 or undef, this value will be
autoranged, which is what you want in most cases. If you want tick to be a multiple of some value, don't use this
option to do that but xLabelUnits instead. Defaults to 0.

=item xTickInset / xSubtickInset

The number of pixels a (sub)tick should extend into the chart. Defaults to 4 and 2 respectively.

=item xTickOutset / ySubtickInset

The number of pixels a (sub)tick should extend out of the chart. Defaults to 8 and 2 repectively.

=item xSubtickCount
        
TODO

=item xTicks

Array ref containtaing the values of the ticks on the x axis. If an empty array ref is passed these locations will
be auto generated. Defaults to an empty array ref. In virtually any case you'll want tick to be auto generated, and
change the way the auto generation works by adjusting xTickWidth or xLabelUnits.

=item xTickColor / xSubtickColor   => sub { $_[0]->get('subtickColor') },

The color in which (sub)ticks should be drawn. Defaults to the value given for tickColor and subtickColor
respectively.

=item xLabelFormat

A printf compatible string that formats the numerical value of the labels on the x axis. Defaults to '%s',
yLabelFormat defaults to '%.1f'.

=item xLabelUnits

The values of the ticks will be normalized (divided) by this value. Defaults to 1.

=item xTitleBorderOffset

The distance in pixels between the title of the x axis and the margin of the axis. Defaults to 0.

=item xTitleLabelOffset

The distance in pixels between the title of the x axis and its tick labels. Defaults to 10.

=item xLabelTickOffset

The distance in pixels between the the ticks of the x axis and their labels. Defaults to 3.

=item xPlotRulers

If set to a true value rulers will be drawn for x axis ticks. Defaults to the value of the plotRulers property.

=item xRulerColor

The color in which the x axis rulers should be drawn. Defaults to the color set by the rulerColor property.

=item xTitle

The title of the x axis. Defaults to '', ie. no title.

=item xTitleFont

The font in which the x axis title should be rendered. Defaults to the font set by the font property.

=item xTitleFontSize

The pointsize of the x axis title. Defaults to 1.5 time the default pointsize set by the fontSize property.

=item xTitleColor

The color of the x axis title. Defaults to the color set by the fontColor property.

#        xTitleAngle
#        xLabelAngle

=item xStart

The value of the start of the range covered by the x axis. If set to undef this value will be autoranged. Defaults
to undef.

=item xStop

The value of the end of the range covered by the x axis. If set to undef this value will be autoranged. Defaults
to undef.

=item xIncludeOrigin

If set to a true value the origin will always be included in the tha x axis range, otherwise automatic inclusion of
the origin into the x axis range depends on a number of conditions, see the extendRangeToOrigin method. Defaults to 0.

=item xNoAdjustRange

If set to a true value the range of the x axis will not be adjusted at all. Overrides xIncludeOrigin. Defaults to
0.

=item xExpandRange

If set to a true value the range of the x axis will be expanded such, that its boundaries conincide with a tick.
Defaults to the value of the expandRange property.

=item xTickOffset

Sets the number of units (in terms of x values, not pixels) that the actual chart should be indented wrt. the
bounding box of the chart. Note that the chart is indented on both sides and the indent per side is half the value
you give here. Defaults to 0.

=back

=cut

sub definition {
    my $self = shift;
    my %options = (
        minTickWidth    => 25,

        xTickOffset     => 0,

        xTickCount      => undef,
        xTickWidth      => 0,
        xTickInset      => 4,
        xTickOutset     => 8,

        xSubtickCount   => 0,
        xSubtickInset   => 2,
        xSubtickOutset  => 2,
        xTicks          => undef,
        xTickColor      => sub { $_[0]->get('tickColor') },
        xSubtickColor   => sub { $_[0]->get('subtickColor') },

        xLabelFormat    => '%s',
        xLabelFormatter => sub { 
            sub { 
                my $format = $_[0]->get('xLabelFormat') || '%s';
                return sprintf $format, $_[1] / $_[2];
            } 
        },
        xLabelUnits     => 1,

        xTitleBorderOffset  => 0,
        xTitleLabelOffset   => 10,
        xLabelTickOffset    => 3,

        plotRulers      => 1,
        rulerColor      => 'lightgrey',
        
        xPlotRulers     => sub { $_[0]->get('plotRulers') },
        xRulerColor     => sub { $_[0]->get('rulerColor') },
        xSubrulerColor  => sub { $_[0]->get('xRulerColor') },

        xTitle          => '',
        xTitleFont      => sub { $_[0]->get('font') },
        xTitleFontSize  => sub { int $_[0]->get('fontSize') * 1.5 },
        xTitleColor     => sub { $_[0]->get('fontColor') },
#        xTitleAngle
#        xLabelAngle
        xStart          => undef,
        xStop           => undef,

        xIncludeOrigin  => 0,
        xNoAdjustRange  => 1,

        yTickOffset     => 0,

        yTickCount      => undef,
        yTickWidth      => 0,
        yTickInset      => 3,
        yTickOutset     => 6,
        ySubtickCount   => 0,
        ySubtickInset   => 2,
        ySubtickOutset  => 2,
        yTicks          => undef,
        yTickColor      => sub { $_[0]->get('tickColor') },
        ySubtickColor   => sub { $_[0]->get('subtickColor') },
        
        yPlotRulers     => sub { $_[0]->get('plotRulers') },
        yRulerColor     => sub { $_[0]->get('rulerColor') },
        ySubrulerColor  => sub { $_[0]->get('yRulerColor') },
        yTitle          => '',
        yTitleFont      => sub { $_[0]->get('font') },
        yTitleFontSize  => sub { int $_[0]->get('fontSize') * 1.5 },
        yTitleColor     => sub { $_[0]->get('fontColor') },
#        yTitleAngle
#        yLabelAngle
        yStart          => undef,
        yStop           => undef,

        yIncludeOrigin  => 0,
        yNoAdjustRange  => 0,

        yLabelFormat    => '%.1f',
        yLabelFormatter => sub { 
            sub { 
                my $format = $_[0]->get('yLabelFormat') || '%s';
                return sprintf $format, $_[1] / $_[2] ;
            } 
        },
        yLabelUnits     => 1,

        yTitleBorderOffset  => 0,
        yTitleLabelOffset   => 10,
        yLabelTickOffset    => 3,

        plotAxes            => 1,
        axisColor           => 'grey50',
        ticksOutside        => 1,
        tickColor           => sub { $_[0]->get('boxColor') },
        subtickColor        => sub { $_[0]->get('tickColor') },

        expandRange         => 1,
        xExpandRange        => sub { $_[0]->get('expandRange') },
        yExpandRange        => sub { $_[0]->get('expandRange') },

        plotBox             => 1,
        boxColor            => 'black',
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

=head2 getCoordDimension ()

See Chart::Magick::Axis::getCoordDimension.

=cut

sub getCoordDimension {
    return 1;
}

#---------------------------------------------

=head2 getDataRange ( )

See L<Chart::Magick::Axis::getDataRange>.

This method overrides the data range given by the superclass with the xStart, xStop, yStart and yStop properties is
those are set.

=cut

sub getDataRange {
    my $self = shift;

    my @overrides   = map { $self->get( $_ ) } qw{ xStart xStop yStart yStop };
    my @values      = $self->SUPER::getDataRange;

    return (
        defined $overrides[0] ? [ $overrides[0] ] : $values[0],
        defined $overrides[1] ? [ $overrides[1] ] : $values[1],
        defined $overrides[2] ? [ $overrides[2] ] : $values[2],
        defined $overrides[3] ? [ $overrides[3] ] : $values[3],
    );
}

#---------------------------------------------

=head2 getValueDimension ()

See Chart::Magick::Axis::getValueDimension.

=cut

sub getValueDimension {
    return 1;
}

#---------------------------------------------

=head2 getTickLabel ( value, [index] )

Returns the tick label belonging to the passed value for the axis identified by index. If no such label exists the
value will be normalized and formatted according to the values of the xLabelUnits and xLabelFormat properties
respectively, and then returned.

=head3 value

The value for which to get the tick label.

=head3 index

The index of the axis for which to get a tick. 0 = x, 1 = y. Defaults to 0.

=cut

sub getTickLabel {
    my $self    = shift;
    my $value   = shift;
    my $index   = shift || 0;

    my $units       = $self->get( $index ? 'yLabelUnits'     : 'xLabelUnits'     ) || 1;
    my $formatter   = $self->get( $index ? 'yLabelFormatter' : 'xLabelFormatter' ) || croak "No label formatter";

    my $label   =     
           $self->getLabels( $index, $value )
        || $formatter->( $self, $value, $units );

    return $label;
}

#---------------------------------------------

=head2 optimizeMargins ( )

Iteratively tries to get the optimal sizes for margin and graph widths and heights.

=cut
#TODO: More pod.
sub optimizeMargins {
    my ( $self, @params ) = @_;

    #my $baseWidth   = $self->plotOption( 'axisWidth' )  - $self->plotOption( 'axisMarginLeft' ) - $self->plotOption( 'axisMarginRight'  );
    #my $baseHeight  = $self->plotOption( 'axisHeight' ) - $self->plotOption( 'axisMarginTop'  ) - $self->plotOption( 'axisMarginBottom' );
    my $baseWidth           = $self->plotOption( 'chartWidth'   );
    my $baseHeight          = $self->plotOption( 'chartHeight'  );
    my $yLabelWidth         = 0;
    my $xLabelHeight        = 0;
    my $prevXLabelHeight    = 0;
    my $prevYLabelWidth     = 0;

    my $ready;
    while ( !$ready ) {
        my ($minX, $maxX, $minY, $maxY) = @params;

        # Calc current chart dimensions
        my $chartWidth  = floor( $baseWidth  - $yLabelWidth );
        my $chartHeight = floor( $baseHeight - $xLabelHeight );

        # Calc tick width
        my $xTickWidth = 
            $self->get('xTickWidth') || 
            $self->calcTickWidth( 
                $minX, $maxX, $chartWidth, $self->get('xTickCount'), $self->get('xLabelUnits') 
            );
        my $yTickWidth = 
            $self->get('yTickWidth') ||
            $self->calcTickWidth( 
                $minY, $maxY, $chartHeight, $self->get('yTickCount'), $self->get('yLabelUnits') 
            );

        # Adjust the chart ranges so that they align with the 0 axes if desired.
        if ( $self->get('yExpandRange') ) {
            $minY = floor( $minY / $yTickWidth ) * $yTickWidth;
            $maxY = ceil ( $maxY / $yTickWidth ) * $yTickWidth;
        }
        if ( $self->get('xExpandRange') ) {
            $minX = floor( $minX / $xTickWidth ) * $xTickWidth;
            $maxX = ceil ( $maxX / $xTickWidth ) * $xTickWidth;
        }   

        # Get ticks
        my @xLabels = map { $self->getTickLabel( $_, 0 ) } @{ $self->generateTicks( $minX, $maxX, $xTickWidth ) };
        my @yLabels = map { $self->getTickLabel( $_, 1 ) } @{ $self->generateTicks( $minY, $maxY, $yTickWidth ) };

        my $xUnits      = ( $self->transformX( $maxX ) - $self->transformX( $minX ) ) || 1;
        my $xAddUnit    = $self->get('xTickOffset') * $xTickWidth;
        my $xPxPerUnit  = $chartWidth / ( $xUnits + $xAddUnit );

        my $yUnits      = ( $self->transformY( $maxY ) - $self->transformY( $minY ) ) || 1;
        my $yAddUnit    = $self->get('yTickOffset') * $yTickWidth;
        my $yPxPerUnit  = $chartHeight / ( $yUnits + $yAddUnit );

        # Calc max label lengths
        $xLabelHeight   = ceil max map { int $self->getLabelDimensions( $_, $xTickWidth * $xPxPerUnit )->[1] } @xLabels; 
        $yLabelWidth    = ceil max map { int $self->getLabelDimensions( $_ )->[0]                            } @yLabels;
    
        # If labels are printed inside the graph then only count the part that lies outside of the chart area.
        unless ( $self->get('ticksOutside') ) {
            if ( $minY < 0 ) {
                $xLabelHeight = ceil max 0, $self->transformY( $minY ) * $yPxPerUnit - $xLabelHeight;
            }
            if ( $minX < 0 ) {
               $yLabelWidth  = ceil max 0, $self->transformY( $minX ) * $xPxPerUnit - $yLabelWidth;
            }
        }

        if ( $prevXLabelHeight == $xLabelHeight && $prevYLabelWidth == $yLabelWidth ) {
            $ready = 1;
            $self->set( 
                xTickWidth  => $xTickWidth,
                yTickWidth  => $yTickWidth,
            );
            # axisMarginLeft and bottom need to be set first.
            $self->plotOption(
                axisMarginLeft  => $self->plotOption( 'axisMarginLeft' ) + $yLabelWidth,
                axisMarginBottom=> $self->plotOption( 'axisMarginBottom' ) + $yLabelWidth, 
            ); 
            $self->plotOption( 
                chartWidth      => $chartWidth,
                chartHeight     => $chartHeight,
                xPxPerUnit      => $xPxPerUnit,
                xTickOffset     => $xAddUnit / 2,
                yPxPerUnit      => $yPxPerUnit,
                yTickOffset     => $yAddUnit / 2,
                chartAnchorX    => $self->get('marginLeft') + $self->plotOption('axisMarginLeft'),
                chartAnchorY    => $self->get('marginTop' ) + $self->plotOption('axisMarginTop' ), 
            );

            return ($minX, $maxX, $minY, $maxY);
        }

        $prevXLabelHeight = $xLabelHeight;
        $prevYLabelWidth = $yLabelWidth;
    }

    return;
}



#---------------------------------------------

=head2 calcBaseMargins ( )

Calcs and sets the base margins of the axis.

=cut

sub calcBaseMargins {
    my $self = shift;

    # calc axisMarginLeft
    my $yTitleWidth = length $self->get('yTitle') == 0
                    ? 0
                    : ( $self->im->QueryFontMetrics(
                            text        => $self->get('yTitle'),
                            font        => $self->get('yTitleFont'),
                            pointsize   => $self->get('yTitleFontSize'),
                            rotate      => -90,
                        ))[5]
                    ;

    my $axisMarginLeft  = 
        $self->get('yTitleBorderOffset') + $self->get('yTitleLabelOffset') 
        + $self->get('yLabelTickOffset') + $self->get('yTickOutset') 
        + $yTitleWidth;
    
    $self->plotOption( 
        axisMarginLeft  => $axisMarginLeft,
        yTitleWidth     => $yTitleWidth,
    );

    #------------------------------------
    # calc axisMarginBottom
    my $xTitleHeight    = length $self->get('xTitle') == 0
                        ? 0
                        : ( $self->im->QueryFontMetrics(
                                text        => $self->get('xTitle'),
                                font        => $self->get('xTitleFont'),
                                pointsize   => $self->get('xTitleFontSize'),
                          ))[5]
                        ;

    my $axisMarginBottom = 
        $self->get('xTitleBorderOffset') + $self->get('xTitleLabelOffset') 
        + $self->get('xLabelTickOffset') + $self->get('xTickOutset') 
        + $xTitleHeight;

    $self->plotOption( 
        axisMarginBottom    => $axisMarginBottom,
        xTitleHeight        => $xTitleHeight,
    );

    #-------------------------------------
    # calc axisMarginRight
    $self->plotOption( axisMarginRight => 0 );

    # calc axisMarginTop
    $self->plotOption( axisMarginTop => 0 );

    my $baseWidth   = $self->plotOption( 'axisWidth' )  - $self->plotOption( 'axisMarginLeft' ) - $self->plotOption( 'axisMarginRight'  );
    my $baseHeight  = $self->plotOption( 'axisHeight' ) - $self->plotOption( 'axisMarginTop'  ) - $self->plotOption( 'axisMarginBottom' );
    $self->plotOption(
        chartWidth  => $baseWidth,
        chartHeight => $baseHeight,
    );

    return;
}

#---------------------------------------------

=head2 generateTicks ( from, to, width )

Generates tick locations spaced at a certain width. Ticks will be generated in such a way that they are aligned with
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
    my $width   = shift || 1;

    # Figure out the first tick so that the ticks will align with zero.
    my $firstTick = floor( $from / $width ) * $width;

    # This is actually actual (number_of_ticks - 1), but below we count from 0 (.. $tickCount), so for our purposes it is
    # the correct amount.
    my $tickCount = ceil( ( $to - $firstTick ) / $width );

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

#--------------------------------------------------------------------

=head2 adjustXRange ()

Adjusts the range of the x axis. Invokes extendRangeToOrigin if necessary.

=cut

sub adjustXRange {
    my $self    = shift;
    my $min     = shift;
    my $max     = shift;

    return ( $min, $max ) if $self->get('xNoAdjustRange') && !$self->get('xIncludeOrigin');

    return $self->extendRangeToOrigin( $min, $max, $self->get('xIncludeOrigin') );
}

#--------------------------------------------------------------------

=head2 adjustYRange ()

Adjusts the range of the x axis. Invokes extendRangeToOrigin if necessary.

=cut

sub adjustYRange {
    my $self    = shift;
    my $min     = shift;
    my $max     = shift;

    return ( $min, $max ) if $self->get('yNoAdjustRange') && !$self->get('yIncludeOrigin');

    return $self->extendRangeToOrigin( $min, $max, $self->get('yIncludeOrigin') );
}

#--------------------------------------------------------------------

=head2 extendRangeToOrigin ( min, max, override )

Adjusts the passed range in such way that the origin (ie. 0) is included in it. The origin is only included if one
of the following criteria is met:

=over 4

=item * 
    
    The override parameter is true

=item *

    The range has zero length (ie. the minimum of the range is equal to its maximum).

=item *

    The range is large compared to its distance to the origin.

=back

=head3 min
    
The minimum of the range.

=head3 max

The maximum of the range.

=head3 override

If set to a true value the origin will allways be included in the range.

=cut

sub extendRangeToOrigin {
    my $self        = shift;
    my $min         = shift;
    my $max         = shift;
    my $override    = shift;

    # The treshold variable is used to determine when the 0 axis should be include in the chart
    my $treshold = 0.4;
    
    # Does the axis have to be included?
    if ( ($max > 0 &&  $min > 0) || ($max < 0 && $max < 0) ) {
        # dataset does not cross axis.
        if ( 
            $override
            || $min == $max
            || abs( ( $max - $min ) / $min ) > $treshold 
        ) {
            $min = 0 if $min > 0;
            $max = 0 if $max < 0;
        }
    }

    # Handle case when y equal zero for all coords. 
    $max = 1 if ($min == 0 && $max == 0);

    return ($min, $max );
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

    ($minX, $maxX) = $self->adjustXRange( $minX, $maxX );
    ($minY, $maxY) = $self->adjustYRange( $minY, $maxY );

    # Determine the space occupied by margin stuff like labels and the like. This als sets the chart width and
    # height in terms of pixels that can be used to draw charts on.
    $self->calcBaseMargins;

    ($minX, $maxX, $minY, $maxY) = $self->optimizeMargins( $minX, $maxX, $minY, $maxY );

    # Store the calulated values in the object and generate the tick locations based on the tick width.
    $self->set( 
        yStop       => $maxY,
        yStart      => $minY,
        xStop       => $maxX,
        xStart      => $minX,
    );
    unless ( defined $self->get('yTicks') ) {
        $self->set( yTicks => $self->generateTicks( $minY, $maxY, $self->get( 'yTickWidth' ) ) );
    }
    unless ( defined $self->get('xTicks') ) {
        $self->set( xTicks => $self->generateTicks( $minX, $maxX, $self->get( 'xTickWidth' ) ) );
    }

    no strict 'refs';
    my $xppu = $self->plotOption('xPxPerUnit');
    *{ __PACKAGE__ . '::getPxPerXUnit' } = sub { return $xppu };

    my $yppu = $self->plotOption('yPxPerUnit');
    *{ __PACKAGE__ . '::getPxPerYUnit' } = sub { return $yppu };
    use strict 'refs';

    $self->plotOption( 
        yChartStop  => $maxY + $self->plotOption('yTickOffset'),
        yChartStart => $minY - $self->plotOption('yTickOffset'),
        xChartStop  => $maxX + $self->plotOption('xTickOffset'),
        xChartStart => $minX - $self->plotOption('xTickOffset'),

#        chartAnchorX => $self->get('marginLeft') + $self->plotOption('axisMarginLeft'),
#        chartAnchorY => $self->get('marginTop' ) + $self->plotOption('axisMarginTop' ), 
    );

    # Precalc toPx offsets.
    $self->plotOption( 'xPxOffset'  => 
          $self->plotOption('chartAnchorX') 
        + $self->plotOption('xTickOffset') * $self->getPxPerXUnit
        - $self->transformX( $self->get('xStart') ) * $self->getPxPerXUnit
    );
    $self->plotOption( 'yPxOffset'  => 
        $self->plotOption('chartAnchorY') 
        + $self->getChartHeight 
        - $self->plotOption('yTickOffset') * $self->getPxPerYUnit
        + $self->transformY( $self->get('yStart') ) * $self->getPxPerYUnit
    );

    no strict 'refs';
    my $xpo = $self->plotOption( 'xPxOffset' );
    *{ __PACKAGE__ . "::toPxX" } = sub {
        return int( $xpo + $_[0]->transformX( $_[1] ) * $xppu );
    };
    my $ypo = $self->plotOption( 'yPxOffset' );
    *{ __PACKAGE__ . "::toPxX" } = sub {
        return int( $ypo - $_[0]->transformY( $_[1] ) * $yppu );
    };
    use strict 'refs';

    return;
}

#---------------------------------------------

=head2 getXTicks ( ) 

Returns the locations of the ticks on the x axis in chart x coordinates.

=cut

sub getXTicks {
    my $self = shift;
   
    return [ @{ $self->get('xTicks') || [] } ];
}

#---------------------------------------------

=head2 generateSubticks ( ticks, count )

Returns an array ref containing the locations of subticks for a given series of tick locations and a number of
subtick per tick interval.

=head3 ticks

Array ref containing the values of the ticks between which the subticks should be placed. The tick values should be
ordered.

=head3 count

The number of subtick intervals per tick interval.

=cut

sub generateSubticks {
    my $self    = shift;
    my $ticks   = shift || [];
    my $count   = int( shift || 0 );

    return [] unless @{ $ticks };
    return [] if     $count <= 1;

    my @subticks;
    for my $i ( 1 .. scalar( @{ $ticks } ) -1 ) {
        my $j = $i - 1;
        my $prev  = $ticks->[ $j ];
        my $this  = $ticks->[ $i ];
        my $width = ($this - $prev) / $count;

        push @subticks, map { $prev + $_ * $width } ( 1 .. $count - 1 );
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
   
    return [ @{ $self->get('yTicks') || []  } ];
}

#---------------------------------------------

=head2 getYSubticks ( )

Returns an array ref containing the locations of the subticks on the y axis in chart y coordinates.

=cut

sub getYSubticks {
    my $self = shift;

    return $self->generateSubticks( $self->getYTicks, $self->get('ySubtickCount') );
}

sub coordInRange {
    my $self    = shift;
    my $coord  = shift;

    return 
           $coord->[ 0 ] >= $self->get('xStart') 
        && $coord->[ 0 ] <= $self->get('xStop');
}

sub valueInRange {
    my $self = shift;
    my $value = shift;

    return 
        && $value->[ 0 ] >= $self->get('yStart')
        && $value->[ 0 ] <= $self->get('yStop');

}

#---------------------------------------------

=head2 plotAxes ( )

Draws the axes.

You'll probably never need to call this method manually.

=cut

sub plotAxes {
    my $self    = shift;
    my $path    = q{};

    # Does the chart range include the x-axis?
    if ( $self->get('yStart') * $self->get('yStop') <= 0 ) {
        $path .= 
              " M " . $self->toPx( [ $self->plotOption( 'xChartStart' ) ], [ 0 ] )
            . " L " . $self->toPx( [ $self->plotOption( 'xChartStop'  ) ], [ 0 ] );
    }
    # Does the chart range include the y-axis?
    if ( $self->get('xStart') * $self->get('xStop') <= 0 ) {
        $path .= 
              " M " . $self->toPx( [ 0 ], [ $self->plotOption( 'yChartStart' ) ] )
            . " L " . $self->toPx( [ 0 ], [ $self->plotOption( 'yChartStop'  ) ] );
    }

    return unless $path;

    $self->im->Draw(
        primitive   => 'Path',
        stroke      => $self->get('axisColor'),
        points      => $path,
        fill        => 'none',
    );

    return;
}

#---------------------------------------------

=head2 plotAxisTitles ( )

Plots the titles of the x and y axis.

=cut

sub plotAxisTitles {
    my $self = shift;

    # X label
    $self->im->text(
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
    $self->im->text(
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

    return;
}

#---------------------------------------------

=head2 plotBox ( )

Plots the box or frame around the chartin area.

=cut

sub plotBox {
    my $self = shift;

    my ($x1, $y1) = $self->project( [ $self->plotOption('xChartStart') ], [ $self->plotOption('yChartStop')  ] );
    my ($x2, $y2) = $self->project( [ $self->plotOption('xChartStop' ) ], [ $self->plotOption('yChartStart') ] );

    # Main axes
    $self->im->Draw(
        primitive   => 'Path',
        stroke      => $self->get('boxColor'),
        points      =>
               " M $x1,$y1 L $x2,$y1 L $x2,$y2 L $x1,$y2 Z ",
        fill        => 'none',
    );

    return;
}

#---------------------------------------------

=head2 drawRuler ( position, isX, color )

Draws a ruler.

=head3 position

The location of the ruler (ie. x coordinate for vertical and y coordinate for horizontal rulers.

=head3 isX

Boolean indicating whether the ruler belongs to the x-axis ( ie. if the ruler is vertical )

=head3 color

Color of the ruler. Pass in a format that Image::Magick understands.

=cut

sub drawRuler {
    my $self    = shift;
    my $tick    = shift;
    my $isX     = shift;
    my $color   = shift;

    my ($from, $to);
    if ($isX) {
        $from   = $self->toPx( [ $tick ], [ $self->plotOption('yChartStart') ] );
        $to     = $self->toPx( [ $tick ], [ $self->plotOption('yChartStop')  ] );
    }
    else {
        $from   = $self->toPx( [ $self->plotOption('xChartStart') ], [ $tick ] );
        $to     = $self->toPx( [ $self->plotOption('xChartStop')  ], [ $tick ] );
    }

    $self->im->Draw(
        primitive   => 'Path',
        stroke      => $color || $self->get('rulerColor'),
        points      => "M $from L $to",
        fill        => 'none',
    );

    return;
}

#---------------------------------------------

=head2 plotRulers ( )

Draws the rulers.

You'll probably never need to call this method manually.

=cut

sub plotRulers {
    my $self = shift;

    my $minY = $self->get('yStart');
    my $maxY = $self->get('yStop');

    if ( $self->get('yPlotRulers') ) {
        for my $tick ( @{ $self->getYSubticks } ) {
            next if $tick < $minY || $tick > $maxY;

            $self->drawRuler( $tick, 0, $self->get('ySubrulerColor') );
        }
        for my $tick ( @{ $self->getYTicks } ) {
            next if $tick < $minY || $tick > $maxY;

            $self->drawRuler( $tick, 0, $self->get('yRulerColor') );
        }
    }

    my $minX = $self->get('xStart');
    my $maxX = $self->get('xStop');

    if ( $self->get('xPlotRulers') ) {
        for my $tick ( @{ $self->getXSubticks } ) {
            next if $tick < $minX || $tick > $maxX;

            $self->drawRuler( $tick, 1, $self->get('xSubrulerColor') );
        }
        for my $tick ( @{ $self->getXTicks } ) {
            next if $tick < $minX || $tick > $maxX;

            $self->drawRuler( $tick, 1, $self->get('xRulerColor') );
        }
    }

    return;
}


#--------------------------------------------------------------------

=head2 drawTick ( args )

Plots a tick.

=head3 args

Hashref containing the properties to draw this tick. The following properties are available:

=over 4

=item x

    The location of the tick base for x ticks. This should be in chart coordinates, not pixels.

=item y

    The location of the tick base for y ticks. This should be in chart coordinates, not pixels.

=item subtick

    If set to a true value the tick will be drawn as a subtick.

=back

=cut

sub drawTick {
    my $self    = shift;
    my $args    = shift;

    my $isX     = exists $args->{ x };
    my $tick    = $isX ? $args->{ x } : $args->{ y };

    my $name    = $isX ? 'x' : 'y';
    $name      .= $args->{ subtick } ? 'Subtick' : 'Tick';

    my $inset   = $self->get( $name . 'Inset'  ); # / $scale;
    my $outset  = $self->get( $name . 'Outset' ); # / $scale;

    my ( $x1, $y1, $x2, $y2 );
    if ( $isX ) {
        my $base    = ( $self->get('ticksOutside') || $self->get('yStop') < 0 || $self->get('yStart') > 0 ) ? $self->plotOption('yChartStart') : 0;
        my ($x, $y) = $self->project( [ $tick ], [ $base ] );
        ($x1, $y1, $x2, $y2) = ( $x, $y + $outset, $x, $y - $inset );
    }
    else {
        my $base    = ( $self->get('ticksOutside') || $self->get('xStop') < 0 || $self->get('xStart') > 0 ) ? $self->plotOption('xChartStart') : 0;
        my ($x, $y) = $self->project( [ $base ], [ $tick ] );
        ($x1, $y1, $x2, $y2) = ( $x - $outset, $y, $x + $inset, $y );
    }    
 
    $self->im->Draw(
        primitive   => 'Path',
        stroke      => $self->get( $name . 'Color' ),
        points      => "M $x1,$y1 L $x2,$y2 ",
        fill        => 'none',
    );

    return if $args->{ subtick };

    $self->im->text(
        text        => $self->getTickLabel( $tick, $isX ? 0 : 1 ),
        halign      => $args->{ halign } || $isX ? 'center' : 'right',
        valign      => $args->{ valign } || $isX ? 'top'    : 'center',
        align       => $args->{ align  } || $isX ? 'Center' : 'Right',
        font        => $self->get('labelFont'),
        pointsize   => $self->get('labelFontSize'),
        style       => 'Normal',
        fill        => $self->get('labelColor'),
        x           => $isX ? $x1 : $x1 - $self->get('yLabelTickOffset'),
        y           => $isX ? $y1 + $self->get('xLabelTickOffset') : $y1,
        wrapWidth   => $args->{ wrap },
    );

    return;
}

#---------------------------------------------

=head2 plotTicks ( )

Draws the ticks and subticks.

You'll probably never need to call this method manually.

=cut

sub plotTicks {
    my $self = shift;

    my $minY = $self->get('yStart');
    my $maxY = $self->get('yStop');

    # Y Ticks
    foreach my $tick ( @{ $self->getYTicks } ) {
        next if $tick < $minY || $tick > $maxY;

        $self->drawTick( { y => $tick } );
    }

    foreach my $tick ( @{ $self->getYSubticks } ) {
        next if $tick < $minY || $tick > $maxY;

        $self->drawTick( { y => $tick, subtick => 1 } );
    }

    my $minX = $self->get('xStart');
    my $maxX = $self->get('xStop');

    # X main ticks
    my $wrap = $self->get('xTickWidth') * $self->plotOption( 'xPxPerUnit' );
    foreach my $tick ( @{ $self->getXTicks } ) {
        next if $tick < $minX || $tick > $maxX;

        $self->drawTick( { x => $tick, wrap => $wrap } );
    }

    # X sub ticks
    foreach my $tick ( @{ $self->getXSubticks } ) {
        next if $tick < $minX || $tick > $maxX;
        
        $self->drawTick( { x => $tick, subtick => 1 } );
    }

    return;
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
    $self->plotAxes if $self->get('plotAxes');
    $self->plotTicks;
    $self->plotBox if $self->get('plotBox'); 

    return;
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

    $self->plotAxisTitles;

    return;
}

#---------------------------------------------

=head2 getPxPerXUnit ( )

Returns the number of pixels in a single unit in x coordinates. In this module this returns the number of pixel per
1 x.

=cut

sub getPxPerXUnit {
    my $self = shift;

    return $self->plotOption( 'xPxPerUnit' );
}

#---------------------------------------------

=head2 getPxPerYUnit ( )

Returns the number of pixels in a single unit in y coordinates. In this module this returns the number of pixel per
1 y.

=cut

sub getPxPerYUnit {
    my $self = shift;

    return $self->plotOption( 'yPxPerUnit' );
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

    return $x;
}

#---------------------------------------------

=head2 transformY ( y )

Transforms the given y value to the y units used by the coordinate system of this axis and returns the transformed coordinate.

=head3 y

The value to be transformed.

=cut

sub transformY {
    my $self    = shift;
    my $y       = shift;

    return $y;
}

#---------------------------------------------

=head2 toPxX ( x )

Transform an x coordinate to pixel coordinates.

=cut

sub toPxX {
    my $self        = shift;
    my $coord       = shift;

    my $x = $self->plotOption( 'xPxOffset' )
        + $self->transformX( $coord ) * $self->getPxPerXUnit;

    return int $x;
}

#---------------------------------------------

=head2 toPxY ( y )

Transform an y coordinate to pixel coordinates.

=cut

sub toPxY {
    my $self    = shift;
    my $coord   = shift;

    my $y = $self->plotOption( 'yPxOffset' )
        - $self->transformY( $coord ) * $self->getPxPerYUnit;

    return int $y;
}

#--------------------------------------------------------------------

=head2 project ( coord, value )

See Chart::Magick::Axis::project. The Lin Axis plugin only takes into account the first elements of both the coord
and value arrayrefs.

=cut

sub project {
    my $self    = shift;
    my $coord   = shift;
    my $value   = shift;

    return ( 
        $self->toPxX( $coord->[0] ), 
        $self->toPxY( $value->[0] ) 
    );
}


1;

