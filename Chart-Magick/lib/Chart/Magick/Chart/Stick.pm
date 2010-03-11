package Chart::Magick::Chart::Stick;

use strict;
use warnings;
use Moose;

use List::Util qw{ min max };
use Chart::Magick::Marker;

extends 'Chart::Magick::Chart';

=head1 NAME

Chart::Magick::Chart::Stick

=head1 DESCRIPTION

A stick Chart plugin for Chart::Magick.

=head2 PROPERTIES

The following properties can be set:

=over 4

=item plotMarkers

If true, markers will be plotted at the end of sticks.

=back

=cut

has plotMarkers => (
    is      => 'rw',
    default => 1,
);


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
        marker  => $self->markers->[ $ds ],
        line    => $self->colors->[ $ds ],
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

    my $drawMarkers = $self->plotMarkers;

    # Draw the graphs
    foreach my $x ( @{ $self->dataset->getCoords } ) {
        foreach my $ds ( 0 .. $datasetCount - 1 ) {
            my $y = $self->dataset->getDataPoint( $x, $ds );

            next unless defined $y;

            my ($x1, $y1) = $axis->project( $x, [ 0 ] );
            my ($x2, $y2) = $axis->project( $x, $y    );

            #$x1 -= 0.5;
            #$x2 -= 0.5;

            my $stroke = $self->colors->[ $ds ]->getStrokeColor;
            $canvas->Draw(
                primitive   => 'Line',
                stroke      => $stroke,
                strokewidth => 1,
                points      => "$x1,$y1 $x2,$y2",
            #    antialias   => 0,
            );

            next unless $drawMarkers && $self->markers->[ $ds ];

            $self->markers->[$ds]->draw( $x2, $y2, $canvas, { stroke => $stroke, fill => 'white' } );
        }
    }
}

1;

