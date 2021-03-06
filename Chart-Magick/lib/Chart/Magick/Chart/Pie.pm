package Chart::Magick::Chart::Pie;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use Chart::Magick::Types;

use Math::Trig;         # exports pi
use List::Util          qw{ min };

has canvas => (
    is      => 'rw',
);

has slices => (
    is      => 'rw',
    default => sub { [] },
);

extends 'Chart::Magick::Chart';

=head1 NAME

Package WebGUI::Image::Graph::Pie

=head1 DESCRIPTION

Package to create pie charts, both 2d and 3d.

=head1 SYNOPSIS

Pie charts have a top height, bottom height which are the amounts of pixels the
top and bottom rise above and below the z = 0 plane respectively. These
properties can be used to create stepping effect.

Also xeplosion and scaling of individual pie slices is possible. Labels can be
connected via sticks and aligned to top, bottom and center of the pie.

The package automatically desides whether to draw in 2d or 3d mode based on the
angle by which the pie is tilted.

=head1 PROPERTIES

Pie defines the following properties:

=over 4

=item bottomHeight

Defaults to 0.

=item explosionLength

Defaults to 0.

=item explosionWidth

Defaults to 0.

=item labelPosition

Defaults to 'top'.

=item labelOffset

Defaults to 10.

=item pieMode

Defaults to 'normal'.

=item radius

Defaults to 100.

=item scaleFactor

Defaults to 1.

=item startAngle

Defaults to 0.

=item shadedSides

Defaults to 1.

=item stickColor

Defaults to '#333333'.

=item stickLength

Defaults to 0.

=item stickOffset

Defaults to 0.

=item tiltAngle

Defaults to 55.

=item topHeight

Defaults to 20.

=back

=cut

has bottomHeight => (
	is		=> 'rw',
	default => 0,
    isa     => 'PositiveOrZeroInt',
);
has explosionLength => (
	is		=> 'rw',
	default => 0,
    isa     => 'PositiveOrZeroInt',
);
has explosionWidth => (
	is		=> 'rw',
	default => 0,
    isa     => 'PositiveOrZeroInt',
);
has labelPosition => (
	is		=> 'rw',
	default => 'top',
    isa     => enum([ qw{ top middle bottom } ]),
);
has labelOffset => (
	is		=> 'rw',
	default => 10,
    isa     => 'PositiveOrZeroInt',
);
has pieMode => (
	is		=> 'rw',
	default => 'normal',
    isa     => enum([ qw{ normal stepped } ]),
);
has radius => (
	is		=> 'rw',
	default => 100,
    isa     => 'PositiveOrZeroInt',
);
has scaleFactor => (
	is		=> 'rw',
	default => 1,
    isa     => 'Num',
);
has startAngle => (
	is		=> 'rw',
	default => 0,
    isa     => 'Num',
);
has shadedSides => (
	is		=> 'rw',
	default => 1,
    isa     => 'Bool',
);
has stickColor => (
	is		=> 'rw',
	default => '#333333',
    isa     => 'MagickColor',
);
has stickLength => (
	is		=> 'rw',
	default => 0,
    isa     => 'Int',
);
has stickOffset => (
	is		=> 'rw',
	default => 0,
    isa     => 'Int',
);
has tiltAngle => (
	is		=> 'rw',
	default => 55,
    isa     => 'Int',
);
has topHeight => (
	is		=> 'rw',
	default => 20,
    isa     => 'Int',
);

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 _mod2pi ( angle )

Returns the angle modulo 2*pi.

=head3 angle

The angle you want the modulo of.

=cut

sub _mod2pi {
    my $angle = shift;

    if ($angle < 0) {
        return 2*pi + $angle - 2*pi*int($angle/(2*pi));
    } else {
        return $angle - 2*pi*int($angle/(2*pi));
    }
}

#-------------------------------------------------------------------

=head2 addSlice ( properties ) 

Adds a slice definition to the pie.

=head3 properties

Hashref containing the slice definition. The following properties can be passed:

=over 4

=item percentage

The percentage of the slice. May be a value between 0 and 1.

=item color

A Chart::Magick::Color object.

=item label

The text label that is drawn along with the slice.

=back

=cut

sub addSlice {
    my $self        = shift;
    my $properties  = shift;
    my $slices      = $self->slices;

    my $percentage  = $properties->{percentage};
    # Work around a bug in imagemagick where an A path with the same start and end point will segfault.
    if ($percentage == 1) {
        $percentage = 0.999999999;
    }

    my $sliceStart  =
          scalar @{ $slices }       ? $slices->[ -1 ]->{ stopAngle }
        : $self->startAngle         ? 2 * pi * $self->startAngle / 360
        : 0
        ;

    my $angle       = _mod2pi( 2 * pi * $percentage         );
    my $startAngle  = _mod2pi( $sliceStart                  );
    my $stopAngle   = _mod2pi( $startAngle + $angle         );
    my $avgAngle    = _mod2pi( $startAngle + $angle  / 2    );

    my $color       = $properties->{color};
    my $fillColor   = $color->getFillColor;
    my $strokeColor = $color->getStrokeColor;
    my $sideColor   = $self->shadedSides
                    ? $color->darken->getFillColor
                    : $fillColor
                    ;

    my $explosionRadius =
          $self->explosionLength                     ? $self->explosionLength
        : $self->explosionWidth && sin( $angle / 2 ) ? $self->explosionWidth / sin( $angle  / 2 )
        : 0;

    push @{ $slices }, {
        # color properties
        fillColor       => $fillColor,
        strokeColor     => $strokeColor,
        bottomColor     => $fillColor,
        topColor        => $fillColor,
        startPlaneColor => $sideColor,
        stopPlaneColor  => $sideColor,
        rimColor        => $sideColor,

        # geometric properties
        topHeight       => $self->topHeight    * sin( 2 * pi * $self->tiltAngle / 360 ),
        bottomHeight    => $self->bottomHeight * sin( 2 * pi * $self->tiltAngle / 360 ),
        explosionRadius => $explosionRadius,
        widthReduction  => $explosionRadius * sin( $angle / 2 ),
        scaleFactor     => ($self->scaleFactor - 1) * $percentage + 1,

        # keep the slice number for debugging properties
        sliceNr         => scalar @{ $slices },
        label           => $properties->{ label },
        percentage      => $percentage,

        # angles
        startAngle      => $startAngle,
        angle           => $angle,
        avgAngle        => $avgAngle,
        stopAngle       => $stopAngle,
    };

    return;
}

#--------------------------------------------------------------------

=head2 getDefaultAxisClass ( )

See Chart::Magick::Chart::getDefaultAxisClass.

Bar's default axis class is Chart::Magick::Axis::Lin.

=cut

sub getDefaultAxisClass {
    return 'Chart::Magick::Axis::None';
}

#--------------------------------------------------------------------

=head2 getIntersect ( radius, alpha, x0, y0 )

Returns the point at which a line through x0,y0 and angle alpha intersects an ellipse cenred at 0,0.

=cut

sub getIntersect {
    my $self    = shift;
    my $radius  = shift;
    my $angle   = shift;
    my $x0      = shift;
    my $y0      = shift;

    my $m   = -sin( $angle ) / cos( $angle );

    my $m2  = $m * $m;
    my $h   = sprintf( '%.6f', ( cos(2 * pi * $self->tiltAngle / 360) ) ** 2 );
    $h = 0.00001 if $h == 0.0;
    my $x02 = $x0 * $x0;
    my $y02 = $y0 * $y0;
    my $r2  = $radius * $radius;

    my $a = $m2 + $h;
    my $b = 2 * $m * ( $y0 - $m * $x0 );
    my $c = $x02 * $m2 - 2 * $x0 * $y0 * $m + $y02 - $r2 * $h;

    my $sgn_x   = ( $angle > 0.5 * pi && $angle < 1.5 * pi ) ? -1 : 1;

    my $x   = ($angle == 0.5 * pi || $angle == 1.5 * pi )
          ? $x0
          : (-$b + $sgn_x * sqrt( ($b*$b) - 4 * $a * $c ) ) / ( 2 * $a )
          ;

    my $y   = ( $x - $x0 ) * $m + $y0;
    
    return ( $x, $y );
}

#--------------------------------------------------------------------

=head2 getSymbolDef ( )

See Chart::Magick::Chart::getSymbolDef.

=cut

sub getSymbolDef {
    my $self    = shift;
    my $ds      = shift;

    return {
        block   => $self->markers->[ $ds ],
    };
}

#-------------------------------------------------------------------

=head2 calcCoordinates ( slice )

Calcs the coordinates of the corners of the given pie slice.

=head3 slice

Hashref containing the information that defines the slice. Must be formatted
like the slices built by addSlice.

=cut

sub calcCoordinates {
    my $self    = shift;
    my $slice   = shift;

    my( $width, $height )   = $self->getPieDimensions( $slice->{ scaleFactor } );

    my ( $tipX, $tipY )     = (
         $slice->{explosionRadius} * cos( $slice->{avgAngle} ),
         - $height / $width * $slice->{explosionRadius} * sin( $slice->{avgAngle} ),
    );

    my ( $startX, $startY ) = $self->project(
        map { [$_] } $self->getIntersect( $self->radius, $slice->{ startAngle }, $tipX, $tipY ) 
    );
    my ( $endX, $endY )     = $self->project(
        map { [$_] } $self->getIntersect( $self->radius, $slice->{ stopAngle }, $tipX, $tipY )
    );
    ( $tipX, $tipY )        = $self->project( [ $tipX ], [ $tipY ] );

    my %coords = (
        %{ $slice },
        tip         => { x   => $tipX,      y => $tipY      },
        startCorner => { x   => $startX,    y => $startY    },
        endCorner   => { x   => $endX,      y => $endY      },
        width       => $width,
        height      => $height,
    );

#    @{ $coords{ tip         }}{ 'x', 'y' } = ( $tipX, $tipY        );  #$self->project( $tipX, $tipY );
#    @{ $coords{ startCorner }}{ 'x', 'y' } = ( $startX, $startY    );  #$self->project( $startX, $startY );
#    @{ $coords{ endCorner   }}{ 'x', 'y' } = ( $endX, $endY        );  #$self->project( $endX, $endY );

    return \%coords;
}

#--------------------------------------------------------------------

=head2 splitSlice

Splits a slice definition in two or three slice defs if necessary, so that each new slice never crosses the
'x-axis' being the line between angle 0 and angle pi.

Returns an array of sub slices.

=head3 slice

Hashref containing the definition of the slice that might need splitting.

=cut

sub splitSlice {
    my $self    = shift;
    my %slice   = %{ shift || {} };

    my ( $start, $stop, $angle ) = @slice{ qw( startAngle stopAngle angle ) };

    my @parts       = ();
    my $noLeft      = 0;

    # slice crosses the left intersect (pi)
    if ( $start < pi && $start + $angle > pi ) {
        my $partAngle = pi - $start;

        push @parts, $self->calcCoordinates( {
            %slice,
            angle           => $partAngle,
            startAngle      => $start,
            stopAngle       => pi,
            noLeft          => 0,
            noRight         => 1,
        } );

        $noLeft = 1;
        $angle  -= $partAngle;
        $start  = pi;
    }

    # slice crosses the right intersect (2*pi)
    if ( $start >= pi && $start + $angle > 2 * pi ) {
        my $partAngle   = 2 * pi - $start;

        push @parts, $self->calcCoordinates( {
            %slice,
            angle           => $partAngle,
            startAngle      => $start,
            stopAngle       => 2 * pi,
            noLeft          => $noLeft,
            noRight         => 1,
        } );

        $noLeft = 1;
        $angle  -= $partAngle;
        $start  = 0;
    }

    push @parts, $self->calcCoordinates( {
        %slice,
        angle       => $angle,
        startAngle  => $start,
        stopAngle   => $stop,
        noLeft      => $noLeft,
        noRight     => 0,
    } );

    return @parts;
}


#-------------------------------------------------------------------

=head2 plot ( )

See Chart::Magick::Chart::plot.

=cut

sub plot {
    my $self    = shift;
    my $canvas  = shift;
    my $axis    = $self->axis;

    $self->canvas( $canvas );

    $self->processDataset;

    # Draw slices in the correct order or you'll get an MC Escher.
    my @slices = map { $self->calcCoordinates( $_ ) } @{ $self->slices };

    # First draw the bottom planes and the labels behind the chart.
    foreach my $slice (@slices) {
        # Draw bottom
        $self->drawBottom( $slice );

        if ( $slice->{avgAngle} > 0 && $slice->{avgAngle} <= pi ) {
            $self->drawLabel( $slice );
        }
    }

    # Secondly draw the sides, which only 3d pies have
    if ($self->tiltAngle != 0) {
        my @parts =
            sort    sortSlices                          # sort slice parts in drawing order
            map     { $self->splitSlice( $_ ) }         # split slices crossing the horizontal axis
            @slices;

        foreach my $slice (@parts) {
            my $leftVisible  = ( $slice->{startAngle} <= 0.5 * pi || $slice->{startAngle} >= 1.5 * pi );
            my $rightVisible = ( $slice->{stopAngle}  >= 0.5 * pi && $slice->{stopAngle}  <= 1.5 * pi );

            my @order =
                   $leftVisible &&  $rightVisible   ? qw{ drawRim           drawRightSide   drawLeftSide    }
                :  $leftVisible && !$rightVisible   ? qw{ drawRightSide     drawRim         drawLeftSide    }
                : !$leftVisible &&  $rightVisible   ? qw{ drawLeftSide      drawRim         drawRightSide   }
                :                                     qw{ drawLeftSide      drawRightSide   drawRim         }
                ;

            for my $method ( @order ) {
                $self->$method( $slice );
            }
        }
    }

    # Finally draw the top planes of each slice and the labels that are in front of the chart.
    foreach my $slice (@slices) {
        $self->drawTop( $slice ) if $self->tiltAngle != 0;

        if ( $slice->{avgAngle} > pi ) {
            $self->drawLabel( $slice );
        }
    }

    return;
}

#-------------------------------------------------------------------

=head2 drawBottom ( slice )

Draws the bottom of the given pie slice.

=head3 slice

A slice hashref. See addSlice for more information.

=cut

sub drawBottom {
    my $self    = shift;
    my $slice   = shift;

    $self->drawPieSlice($slice, -1 * $slice->{bottomHeight}, $slice->{bottomColor});

    return;
}

#-------------------------------------------------------------------

=head2 drawLabel ( slice )

Draws the label including stick if needed for the given pie slice.

=head3 slice

A slice properties hashref.

=cut

sub drawLabel {
    my $self    = shift;
    my $slice   = shift;

    my $tiltScale   = cos( 2 * pi * $self->tiltAngle / 360 );
    my $angle       = $slice->{avgAngle};
    my $radius      = $self->radius;

    my $startRadius = $radius * $slice->{ scaleFactor } + $self->stickOffset;
    my $stopRadius  = $startRadius + $self->stickLength;

    my ( $startPointX, $startPointY ) = $self->project( 
        [  $startRadius * cos $angle                ], 
        [ -$startRadius * $tiltScale * sin $angle   ], 
    );
    my ( $endPointX, $endPointY     ) = $self->project(
        [  $stopRadius  * cos $angle                ],
        [ -$stopRadius  * $tiltScale * sin $angle   ],
    );

    if ($self->tiltAngle) {
        my $position     = $self->labelPosition;
        my $labelOffsetY =
              $position eq 'top'        ? $slice->{topHeight}
            : $position eq 'bottom'     ? $slice->{bottomHeight}
            :                           ( $slice->{topHeight} - $slice->{bottomHeight} ) / 2;

        $startPointY    -= $labelOffsetY;
        $endPointY      -= $labelOffsetY;
    }

    # Draw the stick
    if ($self->stickLength){
        $self->canvas->Draw(
            primitive   => 'Path',
            stroke      => $self->stickColor,
            strokewidth => 3,
            points      =>
                " M $startPointX,$startPointY ".
                " L $endPointX,$endPointY ",
            fill        => 'none',
        );
    }

    # Process the textlabel
    my $horizontalAlign
        = $angle > 0.5 * pi && $angle < 1.5 * pi    ? 'right'
        : $angle < 1.5 * pi || $angle > 1.5 * pi    ? 'left'
        :                                             'center'
        ;

    my $verticalAlign
        = $angle < pi   ? 'bottom'
        : $angle > pi   ? 'top'
        :                 'center'
        ;

    my $anchorX
        = $horizontalAlign eq 'right'
        ? $endPointX - $self->labelOffset
        : $endPointX + $self->labelOffset
        ;

    my $text = $slice->{label} || sprintf('%.1f', $slice->{percentage}*100).' %';

    my $maxWidth = $anchorX;
    $maxWidth = $self->axis->width - $anchorX if ($slice->{avgAngle} > 1.5 * pi || $slice->{avgAngle} < 0.5 * pi);

    $self->canvas->text(
        text            => $text,
        halign          => $horizontalAlign,
        align           => ucfirst $horizontalAlign,
        valign          => $verticalAlign,
        x               => $anchorX,
        y               => $endPointY,
        font            => $self->axis->labelFont,
        pointsize       => $self->axis->labelFontSize,
        fill            => $self->axis->labelColor,
        wrapWidth       => $maxWidth,
    );

    return;
}

#-------------------------------------------------------------------

=head2 drawLeftSide ( slice )

Draws the side connected to the startpoint of the slice.

=head3 slice

A slice properties hashref.

=cut

sub drawLeftSide {
    my $self    = shift;
    my $slice   = shift;

    $self->drawSide( $slice ) unless $slice->{ noLeft };

    return;
}

#-------------------------------------------------------------------

=head2 drawPieSlice ( slice, offset, fillColor )

Draws a pie slice shape, ie. the bottom or top of a slice.

=head3 slice

A slice properties hashref.

=head3 offset

The offset in pixels for the y-direction. This is used to create the thickness
of the pie.

=head3 fillColor

The color with which the slice should be filled.

=cut

sub drawPieSlice {
    my $self        = shift;
    my $slice       = shift;
    my $offset      = shift || 0;
    my $fillColor   = shift;

    my ( $width, $height ) = @{ $slice }{ qw( width height ) };

    my $tipX    = $slice->{tip}->{x};
    my $tipY    = $slice->{tip}->{y} - $offset;
    my $fromX   = $slice->{startCorner}->{x};
    my $fromY   = $slice->{startCorner}->{y} - $offset;

    # Construct path for slice
    my $path = " M $tipX,$tipY L $fromX,$fromY ";

    # We need to draw to top and bottom slices in parts as well, for two reasons: First to prevent the rims from
    # drawing with a different curvature than the top/bottom parts (probably due to rounding errors. 2) To prevent
    # Image magick from segfaulting when a slice of 100% is being drawn.
    foreach my $part ( $self->splitSlice( $slice ) ) {
        my $toX     = $part->{endCorner}->{x};
        my $toY     = $part->{endCorner}->{y} - $offset;

        $path .= " A $width,$height 0 0,0 $toX,$toY ";
    }

    $path .= 'Z';

    $self->canvas->Draw(
        primitive   => 'Path',
        stroke      => $slice->{strokeColor},
        points      => $path,
        fill        => $fillColor,
    );

    return;
}

#-------------------------------------------------------------------

=head2 drawRightSide ( slice )

Draws the side connected to the endpoint of the slice.

=head3 slice

A slice properties hashref.

=cut

sub drawRightSide {
    my $self = shift;
    my $slice = shift;

    $self->drawSide( $slice, 'endCorner', $slice->{stopPlaneColor} ) unless ( $slice->{ noRight } );

    return;
}

#-------------------------------------------------------------------

=head2 drawRim ( slice )

Draws the rim of the slice.

=head3 slice

A slice properties hashref.

=cut

sub drawRim {
    my $self = shift;
    my $slice = shift;

    my %startSideTop = (
        x   => $slice->{startCorner}->{x},
        y   => $slice->{startCorner}->{y} - $slice->{topHeight}
    );
    my %startSideBottom = (
        x   => $slice->{startCorner}->{x},
        y   => $slice->{startCorner}->{y} + $slice->{bottomHeight}
    );
    my %endSideTop = (
        x   => $slice->{endCorner}->{x},
        y   => $slice->{endCorner}->{y} - $slice->{topHeight}
    );
    my %endSideBottom = (
        x   => $slice->{endCorner}->{x},
        y   => $slice->{endCorner}->{y} + $slice->{bottomHeight}
    );

    my ( $pieWidth, $pieHeight ) = @{ $slice }{ qw( width height ) };

    # Draw curvature
    $self->canvas->Draw(
        primitive       => 'Path',
        stroke          => $slice->{strokeColor},
        points      =>
            " M $startSideBottom{x},$startSideBottom{y} ".
            " A $pieWidth,$pieHeight 0 0,0 $endSideBottom{x},$endSideBottom{y} ".
            " L $endSideTop{x}, $endSideTop{y} ".
            " A $pieWidth,$pieHeight 0 0,1 $startSideTop{x},$startSideTop{y}".
            " Z",
        fill        => $slice->{rimColor},
    );

    return;
}

#-------------------------------------------------------------------

=head2 drawSide ( slice, [ cornerName ], [ fillColor ] )

Draws the sides connecting the rim and tip of a pie slice.

=head3 slice

A slice properties hashref.

=head3 cornerName

Specifies which side you want to draw, identified by the name of the corner that
attaches it to the rim. Can be either 'startCorner' or 'endCorner'. If ommitted
it will default to 'startCorner'.

=head3 fillColor

The color with which the side should be filled. If not passed the color for the
'startCorner' side will be defaulted to.

=cut

sub drawSide {
    my (%tipTop, %tipBottom, %rimTop, %rimBottom);
    my $self = shift;
    my $slice = shift;
    my $cornerName = shift || 'startCorner';
    my $color = shift || $slice->{startPlaneColor};

    %tipTop = (
        x   => $slice->{tip}->{x},
        y   => $slice->{tip}->{y} - $slice->{topHeight}
    );
    %tipBottom = (
        x   => $slice->{tip}->{x},
        y   => $slice->{tip}->{y} + $slice->{bottomHeight}
    );
    %rimTop = (
        x   => $slice->{$cornerName}->{x},
        y   => $slice->{$cornerName}->{y} - $slice->{topHeight}
    );
    %rimBottom = (
        x   => $slice->{$cornerName}->{x},
        y   => $slice->{$cornerName}->{y} + $slice->{bottomHeight}
    );

    $self->canvas->Draw(
        primitive   => 'Path',
        stroke      => $slice->{strokeColor},
        points      =>
            " M $tipBottom{x},$tipBottom{y} ".
            " L $rimBottom{x},$rimBottom{y} ".
            " L $rimTop{x},$rimTop{y} ".
            " L $tipTop{x},$tipTop{y} ".
            " Z ",
        fill        => $color,
    );

    return;
}

#-------------------------------------------------------------------

=head2 drawTop ( slice )

Draws the top of the given pie slice.

=head3 slice

A slice hashref. See addSlice for more information.

=cut

sub drawTop {
    my $self = shift;
    my $slice = shift;

    $self->drawPieSlice($slice, $slice->{topHeight}, $slice->{topColor});

    return;
}

#-------------------------------------------------------------------

=head2 getPieDimensions ( scale )

Returns the width and height of the pie corrected for tilt angle.

=head3 scale

Optional factor by which the pie radius is scaled.

=cut

sub getPieDimensions {
    my $self    = shift;
    my $scale   = shift || 1;

    my $radius      = $self->radius * $scale;
    my $pieWidth    = $radius;
    my $pieHeight   = $radius * cos(2 * pi * $self->tiltAngle / 360);

    return ( $pieWidth, $pieHeight );
}

#-------------------------------------------------------------------

=head2 processDataset ( )

Takes the dataset and takes the necesarry steps for the pie to be drawn.

=cut

sub processDataset {
    my $self    = shift;

    my $tiltScale = cos( 2 * pi * $self->tiltAngle / 360 );
    my $stickSize = $self->stickLength + $self->stickOffset + $self->labelOffset + 10;

    my $diameter  = min ( 
        $self->getWidth  - 2 * $stickSize,
        ($self->getHeight - $tiltScale * 2 * $stickSize) / $tiltScale,
    );

    $self->radius( int( $diameter / 2 ) );

    my $total       = $self->dataset->datasetData->[0]->{ total }->[ 0 ] || 1;

    my $divisor     = $self->dataset->datasetData->[0]->{ coordCount }; # avoid division by zero
    my $stepsize    = ( $self->topHeight + $self->bottomHeight ) / $divisor;

    $self->slices( [] );

    for my $coord ( @{ $self->dataset->getCoords } ) {
        my $x = $coord->[0];
        my $y = $self->dataset->getDataPoint( $coord, 0 )->[0];

        # Skip undef or negative values
        next if !defined $y || $y < 0;

        $self->addSlice( {
            percentage  => $y / $total,
            label       => $self->axis->getLabels( 0, $x ) || $x,
            color       => $self->palette->getNextColor,
        } );

        $self->topHeight( $self->topHeight - $stepsize ) if $self->pieMode eq 'stepped';
    }

    return;
}

#-------------------------------------------------------------------

=head2 sortSlices

A sort routine for sorting the slices in drawing order. Must be run from within
the sort command.

=cut

sub sortSlices {
    my $self = shift;

    my $aStart = $a->{startAngle};
    my $aStop  = $a->{stopAngle};
    my $bStart = $b->{startAngle};
    my $bStop  = $b->{stopAngle};

    # If sliceA and sliceB are in different halfplanes sorting is easy...
    return -1 if ( $aStart  < pi && $bStart >= pi );
    return  1 if ( $aStart >= pi && $bStart < pi  );

    if ($aStart < pi) {
        return
              $aStop  <= 0.5 * pi && $bStop  <= 0.5 * pi    ? $bStart <=> $aStart   # A and B in quadrant I
            : $aStart >= 0.5 * pi && $bStart >= 0.5 * pi    ? $aStart <=> $bStart   # A and B in quadrant II
            : $aStart <  0.5 * pi && $aStop  >= 0.5 * pi    ? -1                    # A in quadrants I and II
            : 1
            ;
    } else {
        return
              $aStop  <= 1.5 * pi && $bStop  <= 1.5 * pi    ? $bStop  <=> $aStop    # A and B in quadrant III
            : $aStart >= 1.5 * pi && $bStart >= 1.5 * pi    ? $bStart <=> $aStart   # A and B in quadrant IV
            : $aStart <= 1.5 * pi && $aStop  >= 1.5 * pi    ? 1                     # A in both quadrants III and IV
            : -1                                                                    # B in both quadrants III and IV
            ;
    }

    return 0;
}

1;

