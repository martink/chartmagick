package Chart::Magick::Chart::Scatter;

use strict;
use List::Util qw{ min max };
use Chart::Magick::Marker;

use base qw{ Chart::Magick::Chart }; 

=head1 NAME

Chart::Magick::Chart::Scatter

=head1 DESCRIPTION

A scatter plot Chart plugin for Chart::Magick.

=head1 METHODS

The following methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 definition ( )

See Chart::Magick::Chart::definition for details.

The following properties can be set:

=over 4

=item markerSize

Default marker size (in pixels) to be used when none was set with the marker itself. Defaults to 5.

=back

=cut

sub definition {
    my $class = shift;

    my $definition = $class->SUPER::definition(@_);

    my $properties = {
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

    return $legend->SYMBOL_MARKER;
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
    my @markers     = @{ $self->markers };
    my @datasets    = grep { defined $markers[$_] } ( 0 .. $datasetCount - 1 ) ;

    # Draw the graphs
    foreach my $x ( @{ $self->dataset->getCoords } ) {
        foreach my $ds ( @datasets ) {
            my $y = $self->dataset->getDataPoint( $x, $ds );

            next unless defined $y;

            $markers[$ds]->draw( $axis->project( $x, $y ), $canvas );
        }
    }
}

1;

