package Chart::Magick::Chart::Gauge;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use Chart::Magick::Types;

use Math::Trig qw{ :pi deg2rad };
use List::Util qw{ min };

extends 'Chart::Magick::Chart';

#---------------------------------------------------------------------

=head2 properties

The following properties can be set:

=over 4

####TODO: Add these items.

=back

=cut

has paneColor => (
    is      => 'rw',
    default => '#888888',
    isa     => 'MagickColor',
);
has rimColor => (
    is      => 'rw',
    default => 'orange',
    isa     => 'MagickColor',
);
has scaleColor => (
    is      => 'rw',
    default => '#333333',
    isa     => 'MagickColor',
);
# conflicts with the drawScale method that draws the scale. We're currently not using this attribute anyway, so
# maybe delete it?
#has drawScale => (
#    is      => 'rw',
#    default => 1,
#);

#TODO: remove later!
has scaleStart => (
    is      => 'rw',
    default => 0,
    isa     => 'Num',
);
has scaleStop => (
    is      =>'rw',
    default => 10,
    isa     => 'Num',
);
        
has numberOfTicks => (
    is      =>'rw',
    default => 5,
    isa     => 'PositiveOrZeroInt',
);
has numberOfSubTicks => (
    is      =>'rw',
    default => 5,
    isa     => 'PositiveOrZeroInt',
);

has startAngle => (
    is      =>'rw',
    default => 45,
    isa     => 'Num',
);
has stopAngle => (
    is      =>'rw',
    default => 315,
    isa     => 'Num',
);
has clockwise => (
    is      =>'rw',
    default => 1,
    isa     => 'Bool',
);

has scaleRadius => (
    is      =>'rw',
    default => 80,
    isa     => 'PositiveOrZeroInt',
);
has labelSpacing => (
    is      =>'rw',
    default => 10,
    isa     => 'PositiveOrZeroInt',
);
has tickOutset => (
    is      =>'rw',
    default => 10,
    isa     => 'PositiveOrZeroInt',
);
has tickInset => (
    is      =>'rw',
    default => 5,
    isa     => 'PositiveOrZeroInt',
);
has subtickOutset => (
    is      =>'rw',
    default => 2,
    isa     => 'PositiveOrZeroInt',
);
has subtickInset => (
    is      =>'rw',
    default => 2,
    isa     => 'PositiveOrZeroInt',
);
has radius => (
    is      =>'rw',
    default => 100,
    isa     => 'PositiveOrZeroInt',
);
has rimMargin => (
    is      =>'rw',
    default => 10,
    isa     => 'PositiveOrZeroInt',
);
has rimWidth => (
    is      =>'rw',
    default => 10,
    isa     => 'PositiveOrZeroInt',
);
has minTickWidth => (
    is      =>'rw',
    default => 40,
    isa     => 'PositiveOrZeroInt',
);
has ticks => (
    is      =>'rw',
    default => sub { [] },
    isa     => 'ArrayRef',
);
has needleType => (
    is      =>'rw',
    default => 'fancy',
    isa     => enum([ qw{ simple fancy compass } ]), 
);

#---------------------------------------------------------------------

=head2 getNeedlePath ( name, size )

Returns the svg path for one of the predefined needle shapes scaled to size.

=head3 name

The name of the predefined path. You can choose from 'simple', 'compass' and 'fancy'.

=head3 size

The length of the needle in pixels.

=cut

sub getNeedlePath {
    my $self = shift;
    my $name = shift;
    my $size = shift|| 1;

    my %needles = (
        simple  => {
            length  => 1,
            shape   => 'l %f,%f',
            points  => [ 1, 0 ],
        },
        compass => {
            length  => 25,
            shape   =>   'm%f%f  l%f,%f  l%f,%f  l%f,%f Z',
            points  => [ 25, 0,  -25, 1,  -1,-1,   1,-1 ],
        },
        fancy => {
            length  => 100,
            shape   => 'm%f,%f l%f,%f l%f,%f a%f,%f 0 1,0 %f,%f l%f,%f Z',
            points  => [ 100, 0, -8, -2, -80, 0, 12, 12, 0, 4, 80, 0 ],
        }, 
    );

    my $needle  = $needles{$name};
    my $scale   = $size / $needle->{ length };
    my $path    = 'M0,0 ' . sprintf $needle->{ shape }, map { $scale * $_ } @{ $needle->{ points } };

    return $path;
}


#--------------------------------------------------------------------

=head2 drawBackPane ( canvas )

Draws the the backpane of the gauge on the passed canvas.

=cut

sub drawBackPane {
    my $self    = shift;
    my $canvas  = shift;

    my $radius = $self->radius;

    $canvas->Draw(
        primitive   => 'Circle',
        points      => $self->toPx( 0, 0 ) . ' ' . $self->toPx( 0, $radius ),
        fill        => $self->paneColor,
    );

    return;
}

#--------------------------------------------------------------------

=head2 drawLabels ( canvas )

Draws the tick labels on the provided canvas.

=cut

sub drawLabels {
    my $self    = shift;
    my $canvas  = shift;

    my $labelRadius = $self->scaleRadius - $self->tickInset - $self->labelSpacing;

    foreach my $tick ( $self->getTicks ) {
        my ($x, $y) = $self->project( $tick, $labelRadius );
        my ($xCenter, $yCenter) = $self->project( 0, 0 );

        my $halign
            = $x - $xCenter < -10   ? 'left'
            : $x - $xCenter >  10   ? 'right'
            :                         'center'
            ;

        my $valign
            = $halign eq 'center' && $y < $yCenter      ? 'top'
            : $halign eq 'center' && $y > $yCenter      ? 'bottom'
            :                                             'center'
            ;

        $canvas->text(
            text            => $tick,
            font            => $self->axis->labelFont,
            fill            => $self->axis->labelColor,
            style           => 'normal',
            pointsize       => $self->axis->labelFontSize,
            x               => $x,
            y               => $y,
            halign          => $halign, 
            valign          => $valign, 
        );
    }
}

#--------------------------------------------------------------------

=head2 drawNeedles ( canvas )

Draws the needles on the canvas.

=cut

sub drawNeedles {
    my $self    = shift;
    my $canvas  = shift;

    my $palette = $self->palette;

    my $needlePath = $self->getNeedlePath( $self->needleType, $self->scaleRadius );
    my ($x, $y) = $self->project( 0,0 );

    foreach my $coord ( @{ $self->dataset->getCoords( 0 ) } ) {
        my $color = $palette->getNextColor;

        # Calc (co)sine from angle for the affine rotation.
        my $angle   = deg2rad( $self->transform( $coord->[0] ) * ( $self->clockwise ? 1 : -1 ) );
        my $sin     = sin $angle;
        my $cos     = cos $angle;

        $canvas->Draw(
            primitive   => 'Path',
            points      => $needlePath,
            fill        => $color->getFillColor,
            stroke      => $color->getStrokeColor,
            strokewidth => 1,
            gravity     => 'Center',
            affine      => [ $cos, $sin, -$sin, $cos, $x, $y ], 
        );
    }
}

#--------------------------------------------------------------------

=head2 drawRim ( canvas ) 

Draws the gauge rim onto the canvas.

=cut

sub drawRim {
    my $self    = shift;
    my $canvas  = shift;

    my $radius  = $self->radius;

    $canvas->Draw(
        primitive   => 'Circle',
        points      => $self->toPx( 0, 0 ) . ' ' . $self->toPx( 0, $radius ),
        strokewidth => $self->rimWidth,
        stroke      => $self->rimColor,
        fill        => 'none',
    );
    $canvas->Draw(
        primitive   => 'Circle',
        points      => $self->toPx( 0, 0 ) . ' ' . $self->toPx( 0, $radius ),
        strokewidth => 1,
        stroke      => 'black',
        fill        => 'none',
    );

    return;

}

#--------------------------------------------------------------------

=head2 drawScale ( canvas ) 

Draws the scale (or the axis if you like) onto the canvas.

=cut

sub drawScale {
    my $self    = shift;
    my $canvas  = shift;

    my $radius  = $self->scaleRadius;

    #### PlotOption
    my $start   = $self->scaleStart;
    my $stop    = $self->scaleStop;

    # Draw the baseline of the scale.
    my $startCoord  = $self->toPx( $start, $radius );
    my $middleCoord = $self->toPx( ($stop - $start)/ 2, $radius );
    my $stopCoord   = $self->toPx( $stop, $radius );
    my $direction   = $self->clockwise ? '1' : '0';

    $canvas->Draw(
        primitive   => 'Path',
        points      => 
              "M$startCoord "
            . "A$radius,$radius 0 0,$direction $middleCoord "
            . "A$radius,$radius 0 0,$direction $stopCoord ",
        stroke      => $self->scaleColor,
        fill        => 'none',
    );

    $self->drawTicks( $canvas );
}

#--------------------------------------------------------------------

=head2 drawTicks ( canvas )

Draws the ticks onto the canvas.

=cut

sub drawTicks {
    my $self    = shift;
    my $canvas  = shift;

    my $radius  = $self->scaleRadius;

    # Ticks
    my $from    = $radius - $self->tickInset;
    my $to      = $radius + $self->tickOutset;
    my @ticks;

    foreach my $tick ( $self->getTicks ) {
        push @ticks, [ 
            $self->toPx( $tick, $from ), 
            $self->toPx( $tick, $to   ),
        ];
    }

    # Subticks
    $from   = $radius - $self->subtickInset;
    $to     = $radius + $self->subtickOutset;

    foreach my $subtick ( $self->getSubticks ) {
        push @ticks, [
            $self->toPx( $subtick, $from ),
            $self->toPx( $subtick, $to   ),
        ];
    }
        
    $canvas->Draw(
        primitive   => 'Path',
        points      => join( ' ', map { "M $_->[0] L $_->[1]" } @ticks ),
        stroke      => $self->scaleColor,
        fill        => 'none',
    );

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

=head2 getTicks

Returns an array containing the ticks for this gauge.

=cut

sub getTicks {
    my $self = shift;

    my $tickCount = $self->numberOfTicks;
    my $start     = $self->scaleStart;
    my $stop      = $self->scaleStop;
    my $tickWidth = ( $stop - $start ) / ( $tickCount - 1 );

    return map { $start + $_ * $tickWidth } ( 0 .. $tickCount - 1 );

}

#--------------------------------------------------------------------

=head2 getSubticks ( )

Returns an arrayref containing the subticks for this gauge.

=cut

sub getSubticks {
    return ();
}

#--------------------------------------------------------------------

=head2 getSymbolDef ( dataset )

See Chart::Magick::Chart::getSymBolDef.

=cut

sub getSymbolDef {
    my $self    = shift;
    my $ds      = shift;

    return  {
        block   => $self->colors->[ $ds ],
    }
}

#--------------------------------------------------------------------

=head2 plot ( canvas )

See Chart::Magick::Chart::plot.

=cut

sub plot {
    my $self    = shift;
    my $canvas  = shift; 

    $self->drawBackPane( $canvas );
    $self->drawScale( $canvas );
    $self->drawLabels( $canvas );
    $self->drawNeedles( $canvas );
    $self->drawRim( $canvas ); 

    return;
}

#--------------------------------------------------------------------

=head2 autoRange ( )

See Chart::Magick::Chart::autoRange.

Calcs and sets radius and scaleRadius etc. so that the Gauge fits in the canvas supplied by the axis.

=cut

sub autoRange {
    my $self = shift;

    # figure out available radii
    my $radius      = int( min( $self->getWidth, $self->getHeight ) / 2 - $self->rimWidth / 2 - 2 );
    my $scaleRadius = $radius - $self->tickOutset - $self->rimMargin;

    # autoset number of ticks
#    my $scaleLength     = 2 * pi * $scaleRadius * ( $self->stopAngle - $self->startAngle ) / 360;
#    my $minTickWidth    = $self->minTickWidth || 1;
#    my $maxTickCount    = $scaleLength / $minTickWidth;
#
#    my ($min, $max) = map { $_->[0] } ( $self->getDataRange )[2,3];
#    my $tickWidth   = $self->calcTickWidth( $min, $max, $scaleLength );
#    my @ticks       = @{ $self->generateTicks( $min, $max, $tickWidth ) };

    $self->radius( $radius );
    $self->scaleRadius( $scaleRadius );

#    $self->axis->plotOption(
#        anglePerUnit    => ( $self->stopAngle - $self->startAngle ) / ( $ticks[-1] - $ticks[0] ),
#    );

    return;
}

#--------------------------------------------------------------------

=head2 project ( value, radius )

See Chart::Magick::Chart::project.

=cut

sub project {
    my $self    = shift;
    my $value   = shift;
    my $radius  = shift;

    my $direction   = $self->clockwise ? -1 : 1;
    my $angle       = deg2rad( $self->transform( $value ) );

    return $self->SUPER::project(
        [  $radius * cos( $direction * $angle ) ],
        [ -$radius * sin( $direction * $angle ) ],
    );
}

#--------------------------------------------------------------------

=head2 transform ( value )

Transforms a value to an angle.

=cut

sub transform {
    my $self    = shift;
    my $value   = shift;

    my $direction   = $self->clockwise ? -1 : 1;
    my $valueRange  = $self->scaleStop - $self->scaleStart;
    my $scaleAngle  = $self->stopAngle - $self->startAngle;
    my $angle       = 
          $value / $valueRange * $scaleAngle    # angle of the value wrt. to the scale
        + $self->startAngle                     # offset with angle between scale start and 0 deg
        - $direction * 90                       # and make sure that 0 deg is pointing down, not right.
    ;
    
    return $angle;
}

1;

