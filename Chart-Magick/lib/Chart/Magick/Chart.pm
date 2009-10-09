package Chart::Magick::Chart;

use strict;

use Class::InsideOut    qw{ :std };
use List::Util          qw{ min max };
use Chart::Magick::Palette;
use Chart::Magick::Color;
use Chart::Magick::Data;
use Chart::Magick::Marker;
use Carp;

readonly palette    => my %palette;
readonly dataset    => my %dataset;
readonly markers    => my %markers;
private  properties => my %properties;
readonly axis       => my %axis;

#-------------------------------------------------------------------
sub addData {
    my $self        = shift;
    my $coords      = shift || croak "Need coordinates";
    my $values      = shift || croak "Need values";
    my $marker      = shift;
    my $markerSize  = shift;

    $self->dataset->addDataset( $coords, $values );
    $self->setMarker( $self->dataset->datasetCount - 1, $marker, $markerSize ) if $marker;
}

#-------------------------------------------------------------------

=head2 definition 

Defines the properties of your plugin as well as their default values.

=cut
#TODO: More verbose docs overhere.

sub definition {
    return {};
}

#-------------------------------------------------------------------

=head2 get ( [ key ] )

Returns the value of property 'key'. If key is ommitted returns all properties as a hashref.

=head3 key

The property you want the value of. 

=cut

sub get {
    my $self    = shift;
    my $key     = shift;

    return { $properties{ id $self } } unless $key;
    return $properties{ id $self }->{ $key };
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

=head2 new ( )

Constructor.

=cut

sub new {
    my $class   = shift;
    my $self    = {};

    bless       $self, $class;
    register    $self;

    my $id              = id $self;
    $dataset{ $id }     = Chart::Magick::Data->new;
    $markers{ $id }     = [];
    $properties{ $id }  = $self->definition || {};

    return $self;
}

#-------------------------------------------------------------------
sub preprocessData {

}

#-------------------------------------------------------------------

=head2 set ( properties )

Sets properties for this plugin.

=head3 properties

Either a hash or a hashref containing properties and there new values as keys and values respectively.

=cut

sub set {
    my $self    = shift;
    my %update  = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    my $properties  = $properties{ id $self };

    while ( my ($key, $value) = each %update ) {
        if ( exists $properties->{ $key } ) {
            $properties->{ $key } = $value;
        }
    }
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

    $axis{ id $self } = $axis;
}

#-------------------------------------------------------------------

=head2 setData ( dataset )

Set the dataset object the plugin should chart.

=head3 dataset

An instanciated Chart::Magick::Data object.

=cut

sub setData {
    my $self    = shift;
    my $dataset = shift;

    $dataset{ id $self } = $dataset;
}

#-------------------------------------------------------------------
sub setMarker {
    my $self    = shift;
    my $index   = shift;
    my $marker  = shift || croak "Need a marker";
    my $size    = shift;

    my $def = { size => $size };

    if (-e $marker) {
        $def->{ fromFile } = $marker;
    }
    elsif ( ref $marker eq 'Image::Magick' ) {
        $def->{ magick  } = $marker;
    }
    elsif ( Chart::Magick::Marker->isDefaultMarker( $marker ) ) {
        $def->{ predefined } = $marker;
    }
    else {
        croak "Invalid marker [$marker] passed";
    }

    $markers{ id $self }->[ $index ] = $def;
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
}

1;

