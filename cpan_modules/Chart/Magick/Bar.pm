package Chart::Magick::Bar;

use strict;
use List::Util qw{ sum };
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


#-------------------------------------------------------------------
sub plot {
    my $self    = shift;
    my $axis    = shift;
    

    my $barWidth    = $self->get('barWidth');
    my $barSpacing  = $self->get('barSpacing');
#    my $groupWidth  = ( $datasetCount - 1 ) * ( $barWidth + $barSpacing ); #+ $barWidth;

    my $yCache = {};

    my $dsCount = $self->dataset->datasetCount;

    foreach my $x ( $self->dataset->getCoords ) {
        if ( $self->get('drawMode') eq 'sideBySide' ) {
            my $offset = -1 * ($dsCount - 1) / 2 * ( $barSpacing + $barWidth );
           
            $self->getPalette->paletteIndex( 1 );
            for my $dsi (0 .. $dsCount - 1) {
                my $color   = $self->getPalette->getNextColor;
                my $length  = $self->dataset->getDataPoint( $x, $dsi ); #$self->{_ds2}->{$x}->{ $dsi };

                $self->drawBar( $axis, $length * $axis->getPxPerYUnit, $color, $axis->toPxX( $x ) + $offset, $axis->toPxY( 0 ) );

                $offset += $barWidth + $barSpacing;
            }

        }
        else { #if ( $self->get('stacked') ) {
            $self->getPalette->paletteIndex( 1 );
            my $yBot = 0;
            for my $dsi (0 .. $dsCount - 1) {
                my $color   = $self->getPalette->getNextColor;
                my $length  = $self->dataset->getDataPoint( $x, $dsi ); #$self->{_ds2}->{$x}->{ $dsi };
                
                $self->drawBar( $axis, $length * $axis->getPxPerYUnit, $color, $axis->toPxX( $x ), $axis->toPxY( $yBot ) );

                $yBot += $length;
            }
            
        }
    }
}

#-------------------------------------------------------------------
sub preprocessData {
    my $self = shift;

    my $maxY = 0;
    my $minY = 0;
    if ( $self->get( 'drawMode' ) eq 'stacked' ) {
        $self->set('maxY', $maxY);
        $self->set('minY', $minY);
    }
}

#-------------------------------------------------------------------
sub drawBar {
	my $self    = shift;
    my $axis    = shift;
    my $length  = shift;
	my $color   = shift;
    my $x       = shift;
    my $y       = shift;

    my $width   = $self->get('barWidth');

    my $xLeft   = int( $x - $width / 2  );
    my $xRight  = int( $xLeft + $width  );
    my $yTop    = int( $y - $length     );
    my $yBottom = int( $y               );

	$axis->im->Draw(
		primitive	=> 'Path',
		stroke		=> $color->getStrokeColor, #$bar->{strokeColor},
		points		=> 
			  " M $xLeft,$yBottom "
			. " L $xLeft,$yTop "
            . " L $xRight,$yTop "
			. " L $xRight,$yBottom",
		fill		=> $color->getFillColor, #$bar->{fillColor},
#   affine      => $axis->getChartTransform,
	);
}

1;

