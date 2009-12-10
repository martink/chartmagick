package Chart::Magick::Chart::Gauge;

use strict;

use constant pi => 3.14159265358979;
use List::Util qw{ max min };
use POSIX qw{ floor ceil };

use base qw{ Chart::Magick::Chart };

#--------------------------------------------------------------------
sub getDefaultAxisClass {
    return 'Chart::Magick::Axis::None';
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

sub projectValue {
    my $self    = shift;
    my $value   = shift;
    my $radius  = shift;


    my $rad = $self->transformValue( $value ) / 180 * pi;
    return $self->project(
         $radius * cos( $rad ),
        -$radius * sin( $rad ),
    );
}

sub project {
    my $self = shift;
    my $x    = shift;
    my $y    = shift;

    return $self->axis->project(
        [ $x + $self->getWidth  / 2 ],
        [ $y + $self->getHeight / 2 ],
    );
}

sub transformValue {
    my $self    = shift;
    my $value   = shift;

    my $startValue  = $self->get('ticks')->[0];

    my $cw      = 1;
    my $angle   = $self->get('startAngle') + ( $value - $startValue ) * $self->axis->plotOption('anglePerUnit');
    $angle      *= -1 if $cw;
    $angle      -= 90;

    return $angle;
}

#-------------------------------------------------------------------
sub definition {
    my $self = shift;

    my $definition = {
        %{ $self->SUPER::definition },

        paneColor           => '#888888',
        rimColor            => 'orange',
        drawAxis            => 1,
        numberOfTicks       => 5,
        numberOfSubTicks    => 5,
        startAngle          => 45,
        stopAngle           => 315,
        scaleRadius         => 80,
        labelSpacing        => 10,
        tickOutset          => 10,
        tickInset           => 5,
        axisColor           => '#333333',
        radius              => 0,
        rimMargin           => 10,
        minTickWidth        => 40,
        ticks               => [],
    };

    return $definition;
}

#-------------------------------------------------------------------
sub plot {
    my $self = shift;
    my $axis = $self->axis;

    $self->drawBackground;
    $self->drawAxes;

    my $palette = $self->getPalette;

    foreach my $coord ( @{ $self->dataset->getCoords( 0 ) } ) {
        $self->drawNeedle( $self->dataset->getDataPoint( $coord, 0 )->[0] , $palette->getNextColor ); 
    }

    # Center dot.
    $axis->im->Draw(
        primitive   => 'circle',
        points      => join( ',', $self->project(0,0) ) . ' ' . join( ',', $self->project(0,2) ),
        fill        => '#dddddd',
        stroke      => '#bbbbbb',
    );
}

#-------------------------------------------------------------------
sub drawAxes {
    my $self        = shift;

    my $minAngle    = $self->get('startAngle');
    my $maxAngle    = $self->get('stopAngle');
    my $scaleRadius = $self->get('scaleRadius');

    # Draw scale rim
    if ( $self->get('drawAxis') ) {
        my $cw  = '1';
        my $big = ( $maxAngle - $minAngle ) > 180 ? '1' : '0';

        my ( $fromX, $fromY ) = $self->projectValue( $self->get('ticks')->[0],  $scaleRadius  );
        my ( $toX,   $toY   ) = $self->projectValue( $self->get('ticks')->[-1], $scaleRadius );

        $self->im->Draw(
            primitive   => 'Path',
            stroke      => $self->get('axisColor'),
            strokewidth => 2,
            fill        => 'none',
            points      => 
                 " M $fromX,$fromY "
                ." A $scaleRadius,$scaleRadius 0 $big,$cw $toX,$toY ",
        );
    }

    # Draw ticks
    my $tickAngle   = ($maxAngle - $minAngle) / ( @{ $self->get('ticks') } - 1 );
    my $inset       = $self->get('tickInset');
    my $outset      = $self->get('tickOutset');
    my $subTicks    = $self->get('numberOfSubTicks');

    my $previousTick;
    for my $tick ( @{ $self->get('ticks') } ) {
        if ( defined $previousTick ) {
            # Draw sub ticks
            my $subTickValue = ( $tick - $previousTick ) / $subTicks;
            for my $subTick ( 1 .. $subTicks - 1 ) {
                $self->drawTick( $scaleRadius, $previousTick + $subTick * $subTickValue, $inset / 5, $outset / 5 );
            } 
        }

        # Draw tick
        $self->drawTick( $scaleRadius, $tick, $inset, $outset );
        $self->drawLabel( $tick );

        $previousTick = $tick;
    }
}

#-------------------------------------------------------------------
sub drawBackground {
    my $self = shift;
    my $im   = $self->axis->im;


    $im->Draw(
        primitive   => 'Circle',
        stroke      => 'none',
        strokewidth => 5,
        points      =>
              join( ',', $self->project( 0, 0 ) )
            . ' ' 
            . join( ',', $self->project( 0, $self->get('radius') ) ),
        fill        => $self->get('paneColor'),
    );

    $im->Draw(
        primitive   => 'Circle',
        stroke      => 'orange',# $self->get('rimColor'),
        strokewidth => 7,
        gravity     => 'Center',
        points      =>              
                   join( ',', $self->project(0,0) )
           . ' ' . join( ',', $self->project(0, $self->get('radius') ) ),
        fill        => 'none', #'#666666',
    );

    return;
}

#-------------------------------------------------------------------
sub drawLabel {
    my $self        = shift;
    my $tick        = shift;
    my $angle       = shift;

    my $labelRadius = $self->get('scaleRadius') - $self->get('tickInset') - $self->get('labelSpacing');
    my ( $x, $y )   = $self->projectValue( $tick, $labelRadius );

    my $angle   = $self->transformValue( $tick );
    $angle      = abs( ( 360 + $angle -90 ) % 360 );

    $self->axis->text(
        text            => $tick,
#        undercolor      => 'black',
        font            => $self->axis->get('labelFont'),
        fill            => $self->axis->get('labelColor'),
        style           => 'normal',
        pointsize       => $self->axis->get('labelFontSize'),
        x               => $x,
        y               => $y,
        halign          => 
              $angle >   0 && $angle < 180      ? 'left'
            : $angle > 180 && $angle < 360      ? 'right'
            :                                     'center'
            ,
        valign =>  
              $angle >  45  && $angle <= 135    ? 'center'
            : $angle >  135 && $angle <  225    ? 'center' #'top'
            : $angle >= 225 && $angle <  315    ? 'center'
            :                                     'center' #'bottom'
            ,
    );
}




#-------------------------------------------------------------------
sub drawNeedle {
    my $self        = shift;
    my $value       = shift;
    my $color       = shift;

    my $angle       = $self->transformValue( $value ); 

    my $tail    = 0.1 * $self->get('scaleRadius');
    my $body    =   1 * $self->get('scaleRadius');

    #$self->im->Set(Gravity => 'Center' );

    my $needleLength   = $self->get('scaleRadius');
    my $halfWidth      = 2;
    my $tipLength      = 2 * 2 * $halfWidth;
    my $flangeRadius   = 6 * $halfWidth;
    my $connectY       = sqrt( $flangeRadius ** 2 - $halfWidth ** 2 );

    $self->im->Draw(
        primitive   => 'path',
        points      => 
             " M  0,$needleLength"
            ." L " . (-$halfWidth) . "," . ($needleLength - $tipLength)
            ." L " . (-$halfWidth) . "," . $connectY
            ." A $flangeRadius,$flangeRadius 0 1,1 $halfWidth,$connectY"
            ." L " . ( $halfWidth) . "," . ($needleLength - $tipLength)
            ." Z ",
        fill        => $color->getFillColor, #'#777777',
        stroke      => $color->getStrokeColor, #'#555555',
        rotate      => -$angle -90,
        affine      => [ 1, 0, 0, 1, $self->project(0,0)],
    );
}

#-------------------------------------------------------------------
sub drawTick {
    my $self    = shift;
    my $radius  = shift;
    my $tick    = shift;
    my $inset   = shift;
    my $outset  = shift;
    my $image   = shift || $self->axis->im;

    my ( $fromX, $fromY ) = $self->projectValue( $tick, $radius - $inset  );
    my ( $toX,   $toY   ) = $self->projectValue( $tick, $radius + $outset );

    $image->Draw(
        primitive   => 'Line',
        stroke      => $self->get('axisColor'),
        strokewidth => 2,
        points      => "$fromX,$fromY $toX,$toY",
    );
}

#-------------------------------------------------------------------
sub autoRange {
    my $self = shift;

    # figure out available radii
    my $radius      = min( $self->getWidth, $self->getHeight ) / 2;
    my $scaleRadius = $radius - $self->get('tickOutset') - $self->get('rimMargin');

    # autoset number of ticks
    my $scaleLength     = 2 * pi * $scaleRadius * ( $self->get('stopAngle') - $self->get('startAngle') ) / 360;
    my $minTickWidth    = $self->get('minTickWidth') || 1;
    my $maxTickCount    = $scaleLength / $minTickWidth;

    my ($min, $max) = map { $_->[0] } ( $self->getDataRange )[2,3];
    my $tickWidth   = $self->calcTickWidth( $min, $max, $scaleLength );
    my @ticks       = @{ $self->generateTicks( $min, $max, $tickWidth ) };

    $self->set( 
        radius      => $radius,
        scaleRadius => $scaleRadius,
        ticks       => \@ticks,
    );

    $self->axis->plotOption(
        anglePerUnit    => ( $self->get('stopAngle') - $self->get('startAngle') ) / ( $ticks[-1] - $ticks[0] ),
    );

    return;
}

sub generateTicks {
    my $self    = shift;
    my $from    = shift;
    my $to      = shift;
    my $width   = shift;

    # Figure out the first tick so that the ticks will align with zero.
    my $firstTick = floor( $from / $width ) * $width;

    # This is actually actual (number_of_ticks - 1), but below we count from 0 (.. $tickCount), so for our purposes it is
    # the correct amount.
    my $tickCount = ceil( ( $to - $firstTick ) / $width );

    # generate the ticks
    my $ticks   = [ map { $_ * $width + $firstTick } ( 0 .. $tickCount ) ];

    return $ticks;
}

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

1;

