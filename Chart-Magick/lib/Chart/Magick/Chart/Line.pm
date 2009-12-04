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

sub inRange {
    my $self    = shift;
    my $coord   = shift;

    return ( $coord->[0] >= $self->axis->get('xStart') && $coord->[0] <= $self->axis->get('xStop') );
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
    foreach my $x ( grep { $self->inRange( $_ ) }  @{ $self->dataset->getCoords } ) {
        for my $ds ( 0 .. $datasetCount - 1) {
            my $y = $self->dataset->getDataPoint( $x, $ds );

            next unless defined $y;

            my @to = ( $x, $y );

            push @{ $coords[ $ds ] }, $axis->toPx( @to );
        }
    }


    foreach my $ds (0..$datasetCount - 1) {
        my $color = $colors[$ds];

        $canvas->Draw(
            primitive	=> 'polyline',
            stroke		=> $color->getStrokeColor,
            points		=> join( ' ', @{ $coords[$ds] } ),
            fill		=> 'none',
        );
       
        next unless $self->get('plotMarkers') && $markers[ $ds ];
        
        my $marker = $markers[ $ds ];
        
        foreach ( @{ $coords[$ds] } ) {
            $marker->draw( split( /,/, $_ ), $canvas );
        }
    }
}

1;

