package Chart::Magick::Chart::Line;

use strict;
use warnings;
use Moose;

use List::Util qw{ min max };
use Chart::Magick::Marker;

extends 'Chart::Magick::Chart';

=head1 NAME

Chart::Magick::Chart::Line

=head1 DESCRIPTION

A line graph Chart plugin for Chart::Magick.

=head1 METHODS

The following methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 properties

The following properties can be set:

=over 4

=item plotMarkers

Determines whether or not markers are draw at data points. Defaults to 1.

=back

=cut

has plotMarkers => (
	is		=>'rw',
	default => 1,
    isa     => 'Bool',
);

#--------------------------------------------------------------------

=head2 getDefaultAxisClass ( )

See Chart::Magick::Chart::getDefaultAxisClass.

Line's default axis class is Chart::Magick::Axis::Lin.

=cut

sub getDefaultAxisClass {
    return 'Chart::Magick::Axis::Lin';
}

#--------------------------------------------------------------------

=head2 getSymbolDef ( )

See Chart::Magick::Chart::getSymbolDef.

=cut

sub getSymbolDef {
    my $self    = shift;
    my $ds      = shift;

    return {
        line    => $self->colors->[ $ds ],
        marker  => $self->markers->[ $ds ],
    };
}

sub inRange {
    my $self    = shift;
    my $coord   = shift;

    return ( $coord->[0] >= $self->axis->xStart && $coord->[0] <= $self->axis->xStop );
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

    my $xStart  = $self->axis->xStart;
    my $xStop   = $self->axis->xStop;

    # Draw the graphs
    foreach my $x ( grep { $axis->coordInRange( $_ ) }  @{ $self->dataset->getCoords } ) {
        for my $ds ( 0 .. $datasetCount - 1) {
            my $y = $self->dataset->getDataPoint( $x, $ds );

            next unless defined $y;

            push @{ $coords[ $ds ] }, $axis->toPx( $x, $y );
        }
    }

    foreach my $ds (0..$datasetCount - 1) {
        next unless defined $coords[$ds];

        my $color = $colors[$ds];

        $canvas->Draw(
            primitive	=> 'polyline',
            stroke		=> $color->getStrokeColor,
            strokewidth => 1,
            points		=> join( ' ', @{ $coords[$ds] } ),
            fill		=> 'none',
        );
       
        next unless $self->plotMarkers && $markers[ $ds ];
        
        my $marker = $markers[ $ds ];
        
        foreach ( @{ $coords[$ds] } ) {
            $marker->draw( split( /,/, $_ ), $canvas );
        }
    }
}

1;

