package Chart::Magick::Chart::Line;

use strict;
use List::Util qw{ min max };
use Chart::Magick::Marker;

use base qw{ Chart::Magick::Chart }; 

=head1 NAME

Chart::Magick::Chart::Line

=head1 DESCRIPTION

A line graph Chart plugin for Chart::Magick.

=head1 METHODS

The following methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 definition ( )

See Chart::Magick::Chart::definition for details.

The following properties can be set:

=over 4

=item plotMarkers

Determines whether or not markers are draw at data points. Defaults to 1.

=item markerSize

Default marker size (in pixels) to be used when none was set with the marker itself. Defaults to 5.

=back

=cut

sub definition {
    my $class = shift;

    my $definition = $class->SUPER::definition(@_);

    my $properties = {
        plotMarkers     => 1,
    };

    return { %$definition, %$properties };
}

#--------------------------------------------------------------------

=head2 getSymbolType ( )

See Chart::Magick::Chart::getSymbolType.

=cut

sub getSymbolType {
    my $self    = shift;
    my $legend  = $self->axis->legend;

    return $legend->SYMBOL_LINE + $legend->SYMBOL_MARKER;
}

#--------------------------------------------------------------------

=head2 plot

Draws the graph.

=cut

sub plot {
    my $self    = shift;
    my $canvas  = shift;
    my $axis    = $self->axis;

    my $datasetCount =  $self->dataset->datasetCount;
    my $previousCoord;

    # Cache palette and instaciate markers
    my @colors  = @{ $self->colors  };
    my @markers = @{ $self->markers };

    my ( @paths, @coords );
    # Draw the graphs
    foreach my $x ( @{ $self->dataset->getCoords } ) {

        for my $ds ( 0 .. $datasetCount - 1) {
#           my $color = $colors[ $ds ];

            my $y = $self->dataset->getDataPoint( $x, $ds );

            next unless defined $y;

            if ( $previousCoord->[ $ds ] ) {
                my @from = @{ $previousCoord->[ $ds ] };
                my @to   = ( $x, $y );

                my $path = 
                #    " M " . $axis->toPx( @from )
                   " L " . $axis->toPx( @to   )
                ;

#                $paths[$ds] .= $path;
                push @{ $coords[ $ds ] }, $axis->toPx( @to   );

#	            $canvas->Draw(
#                	primitive	=> 'Path',
#              	    stroke		=> $color->getStrokeColor,
#                  	points		=> $path,
#              	    fill		=> 'none',
#                );
            }

            # Draw marker of previous data point so that it will be on top of the lines entering and leaving the
            # point.
            my $marker = $markers[ $ds ];
            if ( $marker && $self->get('plotMarkers') && exists $previousCoord->[ $ds ] ) {
                $marker->draw( $axis->project( @{ $previousCoord->[$ds] } ), $canvas );
            }

            # Store the current position of this dataset
            $previousCoord->[ $ds ] = [ $x, $y ];
        }
    }

    foreach my $ds (0..$datasetCount - 1) {
                my $color = $colors[$ds];
                $canvas->Draw(
                	primitive	=> 'Line',
              	    stroke		=> $color->getStrokeColor,
                  	points		=> join( ' ', @{ $coords[$ds] } ),
              	    fill		=> 'none',
                );
#                $canvas->Draw(
#                	primitive	=> 'Path',
#              	    stroke		=> $color->getStrokeColor,
#                  	points		=> $paths[$ds],
#              	    fill		=> 'none',
#                );
        

    }

    # Draw last markers
    if ( $self->get('plotMarkers') ) {
        for my $ds ( 0 .. $datasetCount - 1 ) {
            next unless $markers[ $ds ];
            $markers[ $ds ]->draw( $axis->project( @{ $previousCoord->[$ds] } ), $canvas );
        }
    }
}

1;

