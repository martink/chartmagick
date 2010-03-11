package Chart::Magick::Chart::Scatter;

use strict;
use warnings;
use Moose;

use List::Util qw{ min max };
use Chart::Magick::Marker;

extends 'Chart::Magick::Chart';

=head1 NAME

Chart::Magick::Chart::Scatter

=head1 DESCRIPTION

A scatter plot Chart plugin for Chart::Magick.

=head1 PROPERTIES

Chart::Magick::Chart::Scatter has no properties of its own.

=head1 METHODS

The following methods are available from this class:

=cut

#--------------------------------------------------------------------

=head2 getDefaultAxisClass ( )

See Chart::Magick::Chart::getDefaultAxisClass.

Bar's default axis class is Chart::Magick::Axis::Lin.

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
        marker  => $self->markers->[ $ds ]->setColor( $self->colors->[ $ds ] ),
    };
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

