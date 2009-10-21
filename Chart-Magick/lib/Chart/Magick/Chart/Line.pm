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
        markerSize      => 5,
    };

    return { %$definition, %$properties };
}

#-------------------------------------------------------------------

=head2 plot

Draws the graph.

=cut

sub plot {
    my $self = shift;
    my $axis = $self->axis;

    my $datasetCount =  $self->dataset->datasetCount;
    my $previousCoord;
    my $markers = [];
    my $markerSize = $self->get('markerSize');

    $self->getPalette->paletteIndex( 1 );
    for my $ds ( 0 .. $datasetCount - 1) { 
        next unless exists $self->markers->[ $ds ];

        my $markerDef = $self->markers->[ $ds ];
        $markerDef->{ size } ||= $markerSize;
        $markerDef->{ strokeColor } = $self->getPalette->getNextColor->getStrokeColor;
        $markerDef->{ axis } = $axis;

        $markers->[ $ds ] = Chart::Magick::Marker->new( $markerDef );
    }

    # Cache palette.
    my @palette;
    $self->getPalette->paletteIndex( 1 );
    push @palette, $self->getPalette->getNextColor for ( 1 .. $datasetCount );

    foreach my $x ( @{ $self->dataset->getCoords } ) {

        for my $ds ( 0 .. $datasetCount - 1) {
            my $color = $palette[ $ds ];

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

            # Draw marker of previous data point so that it will be on top of the lines entering and leaving the
            # point.
            my $marker = $markers->[ $ds ];
            if ( $marker && $self->get('plotMarkers') && exists $previousCoord->[ $ds ] ) {
                $marker->draw( $axis->project( @{ $previousCoord->[ $ds ] } ) );
            }

            # Store the current position of this dataset
            $previousCoord->[ $ds ] = [ $x, $y ];
        }
    }

    # Draw last markers
    if ( $self->get('plotMarkers') ) {
        for my $ds ( 0 .. $datasetCount - 1 ) {
            next unless $markers->[ $ds ];
            $markers->[ $ds ]->draw( $axis->project( @{ $previousCoord->[ $ds ] } ) );
        }
    }
}

1;

