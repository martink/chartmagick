package Chart::Magick::Chart::Line;

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
    my $axis = $self->axis;

    my $datasetCount =  $self->dataset->datasetCount;
    my $previousCoord;

    my $marker = Chart::Magick::Marker->new( $axis, 3 );

    foreach my $x ( @{ $self->dataset->getCoords } ) {
        $self->getPalette->paletteIndex( 1 );

        for my $ds ( 0 .. $datasetCount - 1) {
            my $color = $self->getPalette->getNextColor;
            my $y = $self->dataset->getDataPoint( $x, $ds );

            next unless defined $y;

            if ( $previousCoord->[ $ds ] ) {
                my @from = @{ $previousCoord->[ $ds ] };
                my @to   = ( $x, $y );

                my $path = 
                    "M " . $axis->toPx( @from   )
                   ."L " . $axis->toPx( @to     )
                ;

	            $axis->im->Draw(
                	primitive	=> 'Path',
              	    stroke		=> $color->getStrokeColor,
                  	points		=> $path,
              	    fill		=> 'none',
                );
            }

            # Draw markers
            if ( $self->get('plotMarkers') ) {
                $marker->draw( $axis->project( $x, $y ), $color->getStrokeColor );
            }

            # Store the current position of this dataset
            $previousCoord->[ $ds ] = [ $x, $y ];
        }
    }
}

1;

