package Chart::Magick::Chart::Gauge;

use strict;
use warnings;

use Math::Trig qw{ :pi deg2rad };
use List::Util qw{ min };

use base qw{ Chart::Magick::Chart };

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

#---------------------------------------------------------------------

=head2 definition ( )

Defines the properties for this class. See also Chart::Magick::Chart::definition.

The following properties can be set:

=over 4

####TODO: Add these items.

=back

=cut

sub definition {
    my $self = shift;

    my $definition = {
        %{ $self->SUPER::definition },

        paneColor           => '#888888',
        rimColor            => 'orange',
        scaleColor          => '#333333',
        drawScale            => 1,

        #TODO: remove later!
        scaleStart          => 0,
        scaleStop           => 10,
        
        numberOfTicks       => 5,
        numberOfSubTicks    => 5,

        startAngle          => 45,
        stopAngle           => 315,
        clockwise           => 1,

        scaleRadius         => 80,
        labelSpacing        => 10,
        tickOutset          => 10,
        tickInset           => 5,
        subtickOutset       => 2,
        subtickInset        => 2,
        radius              => 100,
        rimMargin           => 10,
        rimWidth            => 10,
        minTickWidth        => 40,
        ticks               => [],
        needleType          => 'fancy',
    };

    return $definition;
}

#--------------------------------------------------------------------

=head2 drawBackPane ( canvas )

Draws the the backpane of the gauge on the passed canvas.

=cut

sub drawBackPane {
    my $self    = shift;
    my $canvas  = shift;

    my $radius = $self->get('radius');

    $canvas->Draw(
        primitive   => 'Circle',
        points      => $self->toPx( 0, 0 ) . ' ' . $self->toPx( 0, $radius ),
        fill        => $self->get('paneColor'),
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

    my $labelRadius = $self->get('scaleRadius') - $self->get('tickInset') - $self->get('labelSpacing');

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
    #        undercolor      => 'black',
            font            => $self->axis->get('labelFont'),
            fill            => $self->axis->get('labelColor'),
            style           => 'normal',
            pointsize       => $self->axis->get('labelFontSize'),
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

    my $palette = $self->getPalette;

    my $needlePath = $self->getNeedlePath( $self->get('needleType'), $self->get('scaleRadius') );
    my ($x, $y) = $self->project( 0,0 );

    foreach my $coord ( @{ $self->dataset->getCoords( 0 ) } ) {
        my $color = $palette->getNextColor;

        # Calc (co)sine from angle for the affine rotation.
        my $angle   = deg2rad( $self->transform( $coord->[0] ) * ( $self->get('clockwise') ? 1 : -1 ) );
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

    my $radius  = $self->get('radius');

    $canvas->Draw(
        primitive   => 'Circle',
        points      => $self->toPx( 0, 0 ) . ' ' . $self->toPx( 0, $radius ),
        strokewidth => $self->get('rimWidth'),
        stroke      => $self->get('rimColor'),
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

    my $radius  = $self->get('scaleRadius');

    #### PlotOption
    my $start   = $self->get('scaleStart');
    my $stop    = $self->get('scaleStop');

    # Draw the baseline of the scale.
    my $startCoord  = $self->toPx( $start, $radius );
    my $middleCoord = $self->toPx( ($stop - $start)/ 2, $radius );
    my $stopCoord   = $self->toPx( $stop, $radius );
    my $direction   = $self->get('clockwise') ? '1' : '0';

    $canvas->Draw(
        primitive   => 'Path',
        points      => 
              "M$startCoord "
            . "A$radius,$radius 0 0,$direction $middleCoord "
            . "A$radius,$radius 0 0,$direction $stopCoord ",
        stroke      => $self->get('scaleColor'),
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

    my $radius  = $self->get('scaleRadius');

    # Ticks
    my $from    = $radius - $self->get('tickInset');
    my $to      = $radius + $self->get('tickOutset' );
    my @ticks;

    foreach my $tick ( $self->getTicks ) {
        push @ticks, [ 
            $self->toPx( $tick, $from ), 
            $self->toPx( $tick, $to   ),
        ];
    }

    # Subticks
    $from   = $radius - $self->get('subtickInset');
    $to     = $radius + $self->get('subtickOutset');

    foreach my $subtick ( $self->getSubticks ) {
        push @ticks, [
            $self->toPx( $subtick, $from ),
            $self->toPx( $subtick, $to   ),
        ];
    }
        
    $canvas->Draw(
        primitive   => 'Path',
        points      => join( ' ', map { "M $_->[0] L $_->[1]" } @ticks ),
        stroke      => $self->get('scaleColor'),
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

    my $tickCount = $self->get('numberOfTicks');
    my $start     = $self->get('scaleStart');
    my $stop      = $self->get('scaleStop');
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
    my $radius      = int( min( $self->getWidth, $self->getHeight ) / 2 - $self->get('rimWidth') / 2 - 2 );
    my $scaleRadius = $radius - $self->get('tickOutset') - $self->get('rimMargin');

    # autoset number of ticks
#    my $scaleLength     = 2 * pi * $scaleRadius * ( $self->get('stopAngle') - $self->get('startAngle') ) / 360;
#    my $minTickWidth    = $self->get('minTickWidth') || 1;
#    my $maxTickCount    = $scaleLength / $minTickWidth;
#
#    my ($min, $max) = map { $_->[0] } ( $self->getDataRange )[2,3];
#    my $tickWidth   = $self->calcTickWidth( $min, $max, $scaleLength );
#    my @ticks       = @{ $self->generateTicks( $min, $max, $tickWidth ) };

    $self->set( 
        radius      => $radius,
        scaleRadius => $scaleRadius,
#        ticks       => \@ticks,
    );

#    $self->axis->plotOption(
#        anglePerUnit    => ( $self->get('stopAngle') - $self->get('startAngle') ) / ( $ticks[-1] - $ticks[0] ),
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

    my $direction   = $self->get('clockwise') ? -1 : 1;
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

    my $direction   = $self->get('clockwise') ? -1 : 1;
    my $valueRange  = $self->get('scaleStop') - $self->get('scaleStart');
    my $scaleAngle  = $self->get('stopAngle') - $self->get('startAngle');
    my $angle       = 
          $value / $valueRange * $scaleAngle        # angle of the value wrt. to the scale
        + $self->get('startAngle')                  # offset with angle between scale start and 0 deg
        - $direction * 90                           # and make sure that 0 deg is pointing down, not right.
    ;
    
    return $angle;
}

1;

