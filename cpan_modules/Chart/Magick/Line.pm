package Chart::Magick::Line;

use strict;
use List::Util qw{ min max };
use Chart::Magick::Marker;

use base qw{ Chart::Magick::Chart }; 


#-------------------------------------------------------------------
sub definition {
    my $class = shift;

    my $definition = $class->SUPER::definition(@_);

    my $properties = {
        plotMarkers     => 1,
    };

    return { %$definition, %$properties };
}


#-------------------------------------------------------------------
sub plot {
    my $self = shift;
    my $axis = shift;

    my $datasetCount =  $self->dataset->datasetCount;
    my $yCache;

    my $marker = Chart::Magick::Marker->new( 3 );

    foreach my $x ($self->dataset->getCoords) {
        $self->getPalette->paletteIndex( 1 );

        for my $ds ( 0 .. $datasetCount - 1) {
            my $color = $self->getPalette->getNextColor;
            my $y = $self->dataset->getDataPoint( $x, $ds );

            next unless defined $y;

            if ( defined $yCache->[ $ds ] ) {
                my $path = 
                    "M " . $axis->toPxX( $yCache->[ $ds ]->[ 0 ] ) . "," . $axis->toPxY( $yCache->[ $ds ]->[ 1 ] )
                   ."L " . $axis->toPxX( $x )                      . "," . $axis->toPxY( $y )
                ;

	            $axis->im->Draw(
                	primitive	=> 'Path',
              	    stroke		=> $color->getStrokeColor,
                  	points		=> $path,
              	    fill		=> 'none',
                );

                if ( $self->get('plotMarkers') ) {
                    $marker->draw( $axis->toPxX( $x ), $axis->toPxY( $y ), $axis->im, $color->getStrokeColor );
                }
            }

            $yCache->[ $ds ] = [ $x, $y ];
        }
    }
}

1;

