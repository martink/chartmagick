package Chart::Magick::Chart::Gauge;

use strict;

use constant pi => 3.14159265358979;
use List::Util qw{ max min };

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
        labelRadius         => 75,
        tickOutset          => 10,
        tickInset           => 5,
        axisColor           => '#333333',
        width               => 100,
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
    $self->drawLabels;

    # Draw ticks
    my $ticks = $self->get('numberOfTicks');
    if ($ticks) {
        my $tickAngle   = ($maxAngle - $minAngle) / ($ticks);
        my $inset       = $self->get('tickInset');
        my $outset      = $self->get('tickOutset');
        my $subTicks    = $self->get('numberOfSubTicks');

        for my $tick (0 .. $ticks) {
            my $angle = $minAngle + $tick * $tickAngle;

            # Draw tick
            $self->drawTick( $scaleRadius, $angle, $inset, $outset );

            # Finished drawing ticks
            last if $tick == $ticks;
           
            # Do we need to draw sub ticks?
            next unless $subTicks;

            # Draw sub ticks
            my $subTickAngle = $tickAngle / $subTicks;
            for my $subTick (1 .. $subTicks) {
                $self->drawTick( $scaleRadius, $angle + $subTick * $subTickAngle, $inset / 5, $outset / 5 );
            } 
        }
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
            . ' ' . $self->getXOffset . ',' . ($self->getYOffset - $self->getGaugeRadius),
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
                    $self->getXOffset . ',' . $self->getYOffset 
            . ' ' . $self->getXOffset . ',' . ($self->getYOffset - $self->getGaugeRadius),
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
sub drawLabels {
    my $self        = shift;
    my $ticks       = $self->get('numberOfTicks');

    my $maxScale    = $self->getMaxScale;
    my $startAngle  = $self->get('startAngle');
    my $stopAngle   = $self->get('stopAngle');

    # No ticks, no labels;
    return unless $ticks;

    for ( 0 .. $ticks) {
        my $angle = $startAngle + ( $stopAngle - $startAngle ) * $_ / ($ticks);

        $self->axis->text(
            text            => $_ * $maxScale / $ticks,
    #        undercolor      => 'black',
            font            => $self->axis->get('labelFont'),
            fill            => $self->axis->get('labelColor'),
            style           => 'normal',
            pointsize       => $self->axis->get('labelFontSize'),
            x               => $self->getXOffset - sin( $angle * pi/180 ) * $self->get('labelRadius'),
            y               => $self->getYOffset + cos( $angle * pi/180 ) * $self->get('labelRadius'),
            alignHorizontal => 
                  $angle < 180                      ? 'center' #'left'
                : $angle > 180 && $angle < 360      ? 'center' #'right'
                :                                     'center'
                ,
            alignVertical   =>  
                  $angle >  45  && $angle <= 135    ? 'center'
                : $angle >  135 && $angle <  225    ? 'center' #'top'
                : $angle >= 225 && $angle <  315    ? 'center'
                :                                     'center' #'bottom'
                ,
        );
    }
}

#-------------------------------------------------------------------
sub drawNeedle {
    my $self        = shift;
    my $value       = shift;
    my $color       = shift;
    my $im          = $self->axis->im;

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
sub formNamespace {
	my $self = shift;

	return $self->SUPER::formNamespace.'_Gauge';
}

#-------------------------------------------------------------------
sub getConfiguration {
    my $self = shift;

    my $config = $self->SUPER::getConfiguration;

    return { %{ $config }, %{ $self->get } };
}

#-------------------------------------------------------------------
sub getGaugeRadius {
    my $self = shift;

    return $self->get( 'width' );
    return min( $self->getXOffset, $self->getYOffset ) - 10;
}

#-------------------------------------------------------------------
sub getMaxScale {
    my $self    = shift;

    return $self->dataset->globalData->{maxValue}->[0];

    my $set = $self->getDataset->[0];
    return int(max( @$set ) / 10 + 0.5) * 10;
}

1;

