package Chart::Magick::Chart::Bar;

use strict;
use List::Util qw{ sum reduce };
#use POSIX;

use base qw{ Chart::Magick::Chart };

sub definition {
    my $self    = shift;
    my %options = %{ $self->SUPER::definition };

    my %overrides = (
        barWidth    => 20,
        barSpacing  => 5,
        drawMode    => 'sideBySide',
    );  

    return { %options, %overrides };
}


sub drawBar {
    my $self            = shift;
    my $axis            = shift;

    my $color           = shift;
    my $width           = shift;
    my $length          = shift;
    my $coord           = shift;        # x-location of center of bar group
    my $coordOffset     = shift || 0;   # offset of bar center wrt. $coord 
    my $bottom          = shift || 0;   # y-location of bar bottom wrt. 0 axis

    my $left    = $coord - $width / 2 + $coordOffset;   # x-location of left bar edge
    my $right   = $left + $width;                       # x-location of right bar edge
    my $top     = $bottom + $length;

    my @botLeft  = $axis->toPx( [ $left  ], [ $bottom ] );
    my @topLeft  = $axis->toPx( [ $left  ], [ $top    ] );
    my @topRight = $axis->toPx( [ $right ], [ $top    ] );
    my @botRight = $axis->toPx( [ $right ], [ $bottom ] );

	$axis->im->Draw(
		primitive	=> 'Path',
		stroke		=> $color->getStrokeColor,
		fill		=> $color->getFillColor,
		points		=> 
			  " M " . $axis->toPx( [ $left  ], [ $bottom ] )
			. " L " . $axis->toPx( [ $left  ], [ $top    ] )
            . " L " . $axis->toPx( [ $right ], [ $top    ] )
			. " L " . $axis->toPx( [ $right ], [ $bottom ] ),
	);
    
}

sub getDataRange {
    my $self = shift;

    return $self->SUPER::getDataRange( @_ ) unless $self->get('drawMode') eq 'cumulative';

    my $global = $self->dataset->globalData;
    my $maxNeg = 0;
    my $maxPos = 0;

    # Doing it this way is wrong b/c it should prolly be don in Data. However it works for now.
    foreach my $coord ( $self->dataset->getCoords ) {
        my @values = map { $self->dataset->getDataPoint( $coord, $_ ) } (0 .. $self->dataset->datasetCount - 1);

        my $negSum = sum grep { $_ < 0 } map { $_ ? $_->[0] : 0 } @values;
        my $posSum = sum grep { $_ > 0 } map { $_ ? $_->[0] : 0 } @values;

        $maxNeg = $negSum if $negSum < $maxNeg;
        $maxPos = $posSum if $posSum > $maxPos;
    }

    return ( $global->{ minCoord }, $global->{ maxCoord }, [ $maxNeg ], [ $maxPos ] );
}

sub plot {
    my $self = shift;
    my $axis = shift;

    my $barCount    = $self->dataset->datasetCount;
    my $groupCount  = $self->get('drawMode') eq 'cumulative' 
                    ? 1
                    : $barCount
                    ;


    my $minSpacing;
    my $p;
    foreach ( $self->dataset->getCoords ) {
        if ( defined $p ) {
            $minSpacing = abs( $_->[0] - $p ) if !$minSpacing || abs( $_->[0] - $p ) < $minSpacing;
        }
           
        $p = $_->[0];
    }

    my $dataRange       = 5;
    my $groupWidth      = $minSpacing; #$dataRange / $groupCount;
    my $groupSpacing    = $groupWidth * 0.1;
    my $barSpacing      = $groupWidth * 0.05;

    my $barWidth        = ( $groupWidth  - $groupSpacing ) / $groupCount - $barSpacing ;
    $barWidth *= 0.5;

    foreach my $coord ( $self->dataset->getCoords ) {
        $self->getPalette->paletteIndex( 1 );

        my $positiveVerticalOffset = 0;
        my $negativeVerticalOffset = 0;
        for my $dataset ( 0 .. $barCount - 1 ) {
            my $color       = $self->getPalette->getNextColor;
            my $barLength   = $self->dataset->getDataPoint( $coord, $dataset )->[0];

            if ( $self->get('drawMode') eq 'cumulative' ) {
                my $verticalOffset;
                if ( $barLength >= 0 ) {
                    $verticalOffset          = $positiveVerticalOffset;
                    $positiveVerticalOffset += $barLength;
                }
                else {
                    $verticalOffset          = $negativeVerticalOffset;
                    $negativeVerticalOffset += $barLength;
                }

                # Draw bars on top of each other.
                $self->drawBar( $axis, $color, $barWidth, $barLength, $coord->[0], 0, $verticalOffset );

                $verticalOffset += $barLength;
            }
            else {
                # Default to sideBySide draw mode
                my $offset      = $dataset * ( $barWidth + $barSpacing) - ($barSpacing + $barWidth ) * ( $barCount - 1 ) / 2;

                $self->drawBar( $axis, $color, $barWidth, $barLength, $coord->[ 0 ], $offset, 0  );
            }
        }
    }
}


sub preprocessData {


}








#
#
#
#
##-------------------------------------------------------------------
#sub plot {
#    my $self    = shift;
#    my $axis    = shift;
#    
#
#    my $barWidth    = $self->get('barWidth');
#    my $barSpacing  = $self->get('barSpacing');
##    my $groupWidth  = ( $datasetCount - 1 ) * ( $barWidth + $barSpacing ); #+ $barWidth;
#
#    my $yCache = {};
#
#    my $dsCount = $self->dataset->datasetCount;
#
#    foreach my $x ( $self->dataset->getCoords ) {
#        if ( $self->get('drawMode') eq 'sideBySide' ) {
#            my $offset = -1 * ($dsCount - 1) / 2 * ( $barSpacing + $barWidth );
#           
#            $self->getPalette->paletteIndex( 1 );
#            for my $dsi (0 .. $dsCount - 1) {
#                my $color   = $self->getPalette->getNextColor;
#                my $length  = $self->dataset->getDataPoint( $x, $dsi ); #$self->{_ds2}->{$x}->{ $dsi };
#
##                $self->drawBar( $axis, $length * $axis->getPxPerYUnit, $color, $axis->toPxX( $x ) + $offset, $axis->toPxY( 0 ) );
#                $offset += $barWidth + $barSpacing;
#            }
#
#        }
#        else { #if ( $self->get('stacked') ) {
#            $self->getPalette->paletteIndex( 1 );
#            my $yBot = 0;
#            for my $dsi (0 .. $dsCount - 1) {
#                my $color   = $self->getPalette->getNextColor;
#                my $length  = $self->dataset->getDataPoint( $x, $dsi ); #$self->{_ds2}->{$x}->{ $dsi };
#                
#                $self->drawBar( $axis, $length * $axis->getPxPerYUnit, $color, $axis->toPxX( $x ), $axis->toPxY( $yBot ) );
#
#                $yBot += $length;
#            }
#            
#        }
#    }
#}
#
##-------------------------------------------------------------------
#sub preprocessData {
#    my $self = shift;
#    my $axis = shift;
#
#    my $maxY = 0;
#    my $minY = 0;
#
#    my $barWidth    = $self->get('barWidth');
#    my $barSpacing  = $self->get('barSpacing');
#    my $dsCount     = $self->dataset->datasetCount;
#    my $indent = 0;
#
#    if ( $self->get( 'drawMode' ) eq 'stacked' ) {
#        $indent = $barWidth / 2;
#        $self->set('maxY', $maxY);
#        $self->set('minY', $minY);
#    }
#    else {
#        $indent = ( ($barWidth + $barSpacing) * ($dsCount - 1) + $barWidth ) / 2;
#    }
#
#    $axis->set( 'xTickOffset', $indent) if $axis->get( 'xTickOffset' ) < $indent;
#}
#
##-------------------------------------------------------------------
#sub drawBar {
#	my $self    = shift;
#    my $axis    = shift;
#    my $length  = shift;
#	my $color   = shift;
#    my $x       = shift;
#    my $y       = shift;
#
#    my $width   = $self->get('barWidth');
#
#    my $xLeft   = int( $x - $width / 2  );
#    my $xRight  = int( $xLeft + $width  );
#    my $yTop    = int( $y - $length     );
#    my $yBottom = int( $y               );
#
#	$axis->im->Draw(
#		primitive	=> 'Path',
#		stroke		=> $color->getStrokeColor, #$bar->{strokeColor},
#		points		=> 
#			  " M $xLeft,$yBottom "
#			. " L $xLeft,$yTop "
#            . " L $xRight,$yTop "
#			. " L $xRight,$yBottom",
#		fill		=> $color->getFillColor, #$bar->{fillColor},
##   affine      => $axis->getChartTransform,
#	);
#}

1;

