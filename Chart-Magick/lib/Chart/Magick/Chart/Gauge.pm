package Chart::Magick::Chart::Gauge;

use strict;

use constant pi => 3.14159265358979;
use List::Util qw{ max min };
use POSIX qw{ floor ceil };

use base qw{ Chart::Magick::Chart };


sub getXOffset {
    my $self = shift;
    my $axis = $self->axis;

    return $axis->getChartWidth / 2 + $axis->get('marginLeft');
}

sub getYOffset {
    my $self = shift;
    my $axis = $self->axis;

    return $axis->getChartHeight / 2 + $axis->get('marginTop');
}

sub project {
    my $self    = shift;
    my $value   = shift;
    my $radius  = shift;

    my $angle   = ( $self->get('startAngle') + $value * $self->axis->plotOption('anglePerUnit') ) / 180 * pi;

    return (
        $radius * cos( $angle ) + $self->getWidth  / 2,
        $radius * sin( $angle ) + $self->getHeight  / 2,
    );
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
        labelSpacing        => 5,
        tickOutset          => 10,
        tickInset           => 5,
        axisColor           => '#333333',
        radius              => 0,
        rimMargin           => 5,
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

    $axis->im->Draw(
        primitive   => 'circle',
        points      => '0,0 0,2',
        fill        => '#dddddd',
        stroke      => '#bbbbbb',
      # translate   => $self->getXOffset.','.$self->getYOffset,
        affine      => [ 1, 0, 0, 1, $self->getXOffset, $self->getYOffset ],
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
        $self->axis->im->Draw(
            primitive   => 'Ellipse',
            stroke      => $self->get('axisColor'),
            strokewidth => 2,
            fill        => 'none',
            points      => 
                        '0,0'                                   # Center
                .' ' .  "$scaleRadius,$scaleRadius"             # Width, height
                .' ' .  (($minAngle < $maxAngle)                # Angles
                        ? "$minAngle,$maxAngle"
                        : "$maxAngle,$minAngle"), 
            translate   => $self->getXOffset . ',' . $self->getYOffset,
            rotate      => 90,
            affine      => [ 1, 0, 0, 1, $self->getXOffset, $self->getYOffset ],

        );
    }

    # Draw labels
#    $self->drawLabels;

    # Draw ticks
    my $tickAngle   = ($maxAngle - $minAngle) / ( @{ $self->get('ticks') } - 1 );
    my $inset       = $self->get('tickInset');
    my $outset      = $self->get('tickOutset');
    my $subTicks    = $self->get('numberOfSubTicks');

    my $angle = $minAngle;

    for my $tick ( @{ $self->get('ticks') } ) {
        # Draw tick
        $self->drawTick( $scaleRadius, $angle, $inset, $outset );
        $self->drawLabel( $tick, $angle );

        # Do we need to draw sub ticks?
        if ( $subTicks && $angle < $maxAngle ) {
            # Draw sub ticks
            my $subTickAngle = $tickAngle / $subTicks;
            for my $subTick (1 .. $subTicks) {
                $self->drawTick( $scaleRadius, $angle + $subTick * $subTickAngle, $inset / 5, $outset / 5 );
            } 
        }

        $angle += $tickAngle;
    }
}

#-------------------------------------------------------------------
sub drawBackground {
    my $self = shift;
    my $im   = $self->axis->im;

    my $rim = Image::Magick->new;
    $rim->Set( size => $self->axis->get('width')."x". $self->axis->get('height') );
    $rim->Read(filename => 'xc:none');
    $rim->Set( 'antialias' => 'True', matte => 'True' );

    $rim->Draw(
        primitive   => 'Circle',
        stroke      => $self->get('rimColor'),
        strokewidth => 7,
        points      => 
                    $self->getXOffset . ',' . $self->getYOffset 
            . ' ' . $self->getXOffset . ',' . ($self->getYOffset - $self->get('radius') ),
        fill        => 'none', #'#666666',
    );

    $rim->Shade(
#        geometry    => "300x0",
        azimuth     => 10,
        elevation   => 30,
        gray        => 'True',
    );
    $rim->Blur(
        sigma       => 4,
    );


    $rim->Colorize(
        fill        => $self->get('rimColor'),
    );
    $im->SigmoidalContrast(
        contrast    => 10,
        'mid-point' => '60%',
    );

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

#    $rim->Shadow(
#        opacity     => 30,
#        sigma       => 4,
#        x           => 5,
#        y           => 5,
#    );

    $im->Composite(
#        compose     => 'Atop',
        image       => $rim,
        gravity     => 'Center',
    );

#    $im->Shadow(
#        opacity     => 80,
#        sigma       => 4,
#        x           => 5,
#        y           => 5,
#    );
    $im->Layers(
        method      => 'merge',
    );
}

#-------------------------------------------------------------------
sub drawLabel {
    my $self        = shift;
    my $tick        = shift;
    my $angle       = shift;

    my $labelRadius = $self->get('scaleRadius') - $self->get('tickInset') - $self->get('labelSpacing');
    my ( $x, $y )   = $self->project( $angle, $labelRadius );

print "=====hierrr\n";

    $self->axis->text(
        text            => $tick,
#        undercolor      => 'black',
        font            => $self->axis->get('labelFont'),
        fill            => $self->axis->get('labelColor'),
        style           => 'normal',
        pointsize       => $self->axis->get('labelFontSize'),
        x               => $x,
        y               => $y,
        halign => 
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
    my $im          = $self->axis->im;
return;
    my $maxScale    = $self->getMaxScale;
    my $minAngle    = $self->get('startAngle');
    my $maxAngle    = $self->get('stopAngle');
    my $angle  = ($maxAngle - $minAngle) * $value / $maxScale + $minAngle;

    my $tail    = 0.1 * $self->get('scaleRadius');
    my $body    =   1 * $self->get('scaleRadius');

    $im->Set(Gravity => 'Center' );
#    $self->image->Draw(
#        primitive   => 'line',
#        antialias   => 'true',
#        stroke      => $color->getStrokeTriplet,
#        points      => '0,0 0,75',
#        rotate      => $angle,
#        translate   => $self->getXOffset . ',' . $self->getYOffset
#    );

#    $self->image->Draw(
#        primitive   => 'polygon',
#        points      => 
#            "0,-$tail "
#            ."-$tail,0 "
#            ."0,$body "
#            ."$tail,0",
#        fill        => $color->getFillColor,
#        stroke      => $color->getStrokeColor,
#        rotate      => $angle,
#        translate   => $self->getXOffset . ',' . $self->getYOffset,
#    );

     my $needleLength   = $self->get('scaleRadius');
     my $halfWidth      = 2;
     my $tipLength      = 2 * 2 * $halfWidth;
     my $flangeRadius   = 6 * $halfWidth;
     my $connectY       = sqrt( $flangeRadius ** 2 - $halfWidth ** 2 );

     $im->Draw(
        primitive   => 'path',
        points      => 
             " M  0,$needleLength"
            ." L " . (-$halfWidth) . "," . ($needleLength - $tipLength)
            ." L " . (-$halfWidth) . "," . $connectY
            ." A $flangeRadius,$flangeRadius 0 1,1 $halfWidth,$connectY"
            ." L " . ( $halfWidth) . "," . ($needleLength - $tipLength)
            ." Z ",
        fill        => '#777777',
        stroke      => '#555555',
        rotate      => $angle,
#       translate   => [ $self->getXOffset, $self->getYOffset ], #$self->getXOffset . ',' . $self->getYOffset,
        affine      => [ 1, 0, 0, 1, $self->getXOffset, $self->getYOffset ],
    );
}

#-------------------------------------------------------------------
sub drawTick {
    my $self    = shift;
    my $radius  = shift;
    my $angle   = shift;
    my $inset   = shift;
    my $outset  = shift;
    my $image   = shift || $self->axis->im;

    my $fromX   = $self->getXOffset - sin( $angle * pi/180 ) * ($radius - $inset);
    my $fromY   = $self->getYOffset + cos( $angle * pi/180 ) * ($radius - $inset);
    my $toX     = $self->getXOffset - sin( $angle * pi/180 ) * ($radius + $outset);
    my $toY     = $self->getYOffset + cos( $angle * pi/180 ) * ($radius + $outset);

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
print join( ',', @ticks ), "\n";

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

