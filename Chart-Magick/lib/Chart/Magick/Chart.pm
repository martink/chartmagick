package Chart::Magick::Chart;

use strict;
use warnings;

use Class::InsideOut    qw{ :std };
use List::Util          qw{ min max };
use Chart::Magick::Palette;
use Chart::Magick::Color;
use Chart::Magick::Data;
use Chart::Magick::Marker;
use Carp;

use base qw{ Chart::Magick::Definition };

readonly palette    => my %palette;
readonly dataset    => my %dataset;
readonly markers    => my %markers;
readonly axis       => my %axis;
readonly colors     => my %colors;

#-------------------------------------------------------------------

=head2 addDataset ( coords, values, label, marker, markerSize )

Adds a dataset to the dataset of this chart. Optionally you can set a marker for this dataset as well.

=head3 coords

Array ref of coord array refs. See Chart::Magick::Data::addDataset for details.

=head3 values

Array ref of value array refs. See Chart::Magick::Data::addDataset for details.

=head3 label

The (legend) label for this dataset.

=head3 marker

Optional. A marker spec for the marker for this dataset. See setMarker() method.

=head3 markerSize

Optional. The size of the markers for this dataset. See setMarker() method.

=cut

sub addDataset {
    my $self        = shift;
    my @params      = @_;

    my ( $coords, $values );
    if ( ref $params[ 0 ] eq 'HASH' ) {
        my $data    = shift @params;
        $coords     = [ keys    %{ $data } ],
        $values     = [ values  %{ $data } ],
    }
    else {
        $coords     = shift @params; 
        $values     = shift @params;
    }

    croak 'Need coordinates' unless $coords;
    croak 'Need values'      unless $values;

    my ( $label, $marker, $markerSize ) = @params;

    $self->dataset->addDataset( $coords, $values, $label );
    $self->setMarker( $self->dataset->datasetCount - 1, $marker, $markerSize ) if $marker;

    return;
}

#-------------------------------------------------------------------

=head2 addToLegend

Adds the datasets in this chart to the legend of the axis.

=cut

sub addToLegend {
    my $self = shift;
    my $data = $self->dataset;

    for my $ds ( 0 .. $data->datasetCount ) {
        next unless defined $data->labels->[ $ds ];

        $self->axis->legend->addItem(
            $data->labels->[ $ds ],
            $self->getSymbolDef( $ds ),
         );
    }

}

#-------------------------------------------------------------------

=head2 autoRange ( )

This method is a hook which is called after the axis has set its diemensions. You can use this method to precalc
values that have to scale with the axis. 

=cut

sub autoRange {
    return;
}

#-------------------------------------------------------------------

=head2 definition 

Defines the properties of your plugin as well as their default values.

=cut
#TODO: More verbose docs overhere.

sub definition {
    return {
        markerSize      => 6,
    };
}

#-------------------------------------------------------------------

=head2 getAxis ( )

Returns the Axis object this Chart is set to draw on.

=cut

sub getAxis {
    my $self    = shift;

    my $axis    = $axis{ id $self };

    croak "Cannot call getAxis when no Axis has been set" unless $axis;
    return $axis;
}

#-------------------------------------------------------------------

=head2 getData ( )

Returns the Data object the plugin should chart.

=cut

sub getData {
    my $self    = shift;

    return $dataset{ id $self };
}

#-------------------------------------------------------------------

=head2 getDataRange ( )

Returns a list of four arrayrefs containing range in terms off coords and values the plugin needs to plot the
chart. The arrayrefs each contain the minimum or maximum values for each of the coord or value dimensions.

These arrayref are returned in the following order:

    minimum coord, maximum coord, minimum value, maximum value

=cut

sub getDataRange {
    my $self    = shift;
    my $global  = $self->dataset->globalData;

    return ( $global->{ minCoord }, $global->{ maxCoord }, $global->{ minValue }, $global->{ maxValue } );

}

#-------------------------------------------------------------------

=head2 getHeight ( )

Returns the height in pixels of the area available for the chart.

=cut

sub getHeight {
    my $self = shift;

    return $self->axis->getChartHeight;
}

#-------------------------------------------------------------------

=head2 getPalette ( )

Returns the Chart::Magick::Palette object associated with this plugin. If none is set, will create a default
palette and return that.

=cut

sub getPalette {
    my $self    = shift;
    my $id      = id $self;

    # If a palette has been set, return it
    return $palette{ $id } if $palette{ $id };

    # Otherwise generate a default palette
    my @colors = (
        { fillTriplet => '7ebfe5', fillAlpha => '77', strokeTriplet => '7ebfe5', strokeAlpha => 'ff' },
        { fillTriplet => '43EC43', fillAlpha => '77', strokeTriplet => '43EC43', strokeAlpha => 'ff' },
        { fillTriplet => 'EC9843', fillAlpha => '77', strokeTriplet => 'EC9843', strokeAlpha => 'ff' },
        { fillTriplet => 'E036E6', fillAlpha => '77', strokeTriplet => 'E036E6', strokeAlpha => 'ff' },
        { fillTriplet => 'F3EB27', fillAlpha => '77', strokeTriplet => 'F3EB27', strokeAlpha => 'ff' },
    );

    my $palette = Chart::Magick::Palette->new;
    $palette->addColor( Chart::Magick::Color->new( $_ ) ) for @colors;
    
    $palette{ $id } = $palette;

    return $palette;
}

#-------------------------------------------------------------------

=head2 getSymbolDef ( )

Returns the symbol definition of this chart type. See the Symbol definitions section of Chart::Magick::Legend for
more information on symbol definitions.

Defaults to lines plus markers.

Override this method if your chart type has another type of symbol.

=cut

sub getSymbolDef {
    my $self    = shift;
    my $ds      = shift;

    return {
        line    => $self->colors->[ $ds ],
        marker  => $self->markers->[ $ds ],
    };
}

#-------------------------------------------------------------------

=head2 getDefaultAxisClass ( )

Returns the default axis class for this chart. Your subclass must override this method.

=cut

sub getDefaultAxisClass {
    my $self = shift;

    croak "Char class " . ref( $self ) . " does not override getDefaultAxisClass.";
}

#-------------------------------------------------------------------

=head2 getWidth ( )

Returns the width in pixels of the area available for the chart.

=cut

sub getWidth {
    my $self = shift;

    return $self->axis->getChartWidth;
}

#-------------------------------------------------------------------

=head2 hasBlockSymbols ( )

Returns a boolean telling whether the symbols in the legend should be drawn as colored blocks instead of line/marker
pairs.

Defaults to false. Override in you Chart plugin if it needs block symbols.

=cut

sub hasBlockSymbols {
    return 0;
}

#-------------------------------------------------------------------

=head2 layoutHints ( )

Returns a hashref containing the layout hints for this plugin. 

=cut

sub layoutHints {
    return {
        coordPadding    => [ 0 ],
        valuePadding    => [ 0 ],
    };
}

#-------------------------------------------------------------------

=head2 new ( )

Constructor.

=cut

sub new {
    my $class       = shift;
    my $properties  = shift || {};
    my $self        = {};

    bless       $self, $class;
    register    $self;

    my $id            = id $self;
    $dataset{ $id   } = Chart::Magick::Data->new;
    $markers{ $id   } = [];
    $colors{ $id    } = [];

    $self->initializeProperties( $properties );

    return $self;
}

#-------------------------------------------------------------------

=head2 preprocessData ( )

Override this method to do any preprocessing before the drawing phase begins.

=cut

sub preprocessData {
    my $self = shift;
    my $markerSize = $self->get('markerSize');

    $self->getPalette->paletteIndex( undef );
    for my $ds ( 0 .. $self->dataset->datasetCount - 1 ) {
        my $color = $self->getPalette->getNextColor;

        push @{ $colors{ id $self } }, $color;

#        if ( exists $self->markers->[ $ds ] ) {
#            my ($name, $size) = @{ $self->markers->[ $ds ] }{ qw(name size) };
#            $size ||= $markerSize;
#
#            $self->markers->[ $ds ] = Chart::Magick::Marker->new( $name, $size, {
#                strokeColor => $color->getStrokeColor,
#            } );
#        }
    }

    return;
}

#-------------------------------------------------------------------

=head2 project ( coords, values )

See Chat::Magick::Axis::project.

=cut

sub project {
    my ($self, @params) = @_;

    return $self->axis->project( @params );
}

#-------------------------------------------------------------------

=head2 setAxis ( axis )

Set the axis objcet the chart should be drawn on.

=head3 axis

An instanciated Chart::Magick::Axis:: object.

=cut

sub setAxis {
    my $self = shift;
    my $axis = shift;

    croak "setAxis requires a Chart::Magick::Axis object to be passed" 
        unless $axis && $axis->isa( 'Chart::Magick::Axis' );

    $axis{ id $self } = $axis;

    return;
}

#-------------------------------------------------------------------

=head2 toPx ( coords, values )

Convenience method. Calls C<project> and returns its results joined by a comma as a sting which directly usable as
a point in Image::Magick Draw oprations.

=cut

sub toPx {
    my ( $self, @params ) = @_;

    return join ',', $self->project( @params );
}

#-------------------------------------------------------------------

=head2 setData ( dataset )

Set the dataset object the plugin should chart.

=head3 dataset

An instanciated Chart::Magick::Data object.

=cut

sub setData {
    my $self = shift;
    my $data = shift;

    croak "setData requires a Chart::Magick::Data object to be passed" 
        unless $data && $data->isa( 'Chart::Magick::Data' );

    $dataset{ id $self } = $data;

    return;
}

#-------------------------------------------------------------------

=head2 setMarker ( datasetIndex, marker, size )

Set a marker for a specfic dataset.

=head3 datasetIndex

The index of the dataset.

=head3 marker

The marker spec. This can be either:

=over 4

=item *

A path to an image file. The image will be scaled and used as the marker.

=item *

An Image::Magick object, which contains the marker image.

=item *

The name of a predefined marker.

=back

=head3 size

The size of the marker. Both height and width will be at most this value. Scaling keeps the aspect ratio.
 
=cut

sub setMarker {
    my $self    = shift;
    my $index   = shift;
    my $marker  = shift || croak "Need a marker";
    my $size    = shift || $self->get('markerSize');

#    my $def = { 
#        name    => $marker,
#        size    => $size 
#    };
#
#    $markers{ id $self }->[ $index ] = $def;
    $markers{ id $self }->[ $index ] = Chart::Magick::Marker->new( $marker, $size );

    return;
}

#-------------------------------------------------------------------

=head2 setPalette ( palette )

Set the palette to use for drawing the chart.

=head3 palette

An instanciated Chart::Magick::Palette object.

=cut

sub setPalette {
    my $self    = shift;
    my $palette = shift;

    croak "setPalette requires a palette to be passed" unless $palette;
    croak "Palette must be a Chart::Magick::Palette" unless $palette->isa( 'Chart::Magick::Palette' );

    $palette{ id $self } = $palette;

    return;
}

1;

