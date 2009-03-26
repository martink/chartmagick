package Chart::Magick::Data;

use strict;
use Class::InsideOut qw{ :std };
use Data::Dumper;

readonly data           => my %data;
readonly labels         => my %labels;
readonly coordCount     => my %coordCount;
readonly datasetCount   => my %datasetCount;
readonly datasetIndex   => my %datasetIndex;
readonly datasetData    => my %datasetData;
readonly globalData     => my %globalData;

=head1 NAME

Chart::Magick::Data - Dataset abstraction for use with the Chart::Magick class charting modules.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is used by the Chart::Magick modules to pass data into graphs. It is coordinate system agnostic
supports N dimensional coordinates and M dimensional values, with N and M both 1 or larger. It is up to each
individual charting plugin to decide how to handle these coordinates and values.

The following methods are available from this class:

=cut

#---------------------------------------------------------------

=head2 new ( )

Consructor.

=cut 

sub new {
    my $class   = shift;
    my $self    = {};

    bless       $self, $class;
    register    $self;

    my $id = id $self;
    $data{ $id }            = {};
    $datasetCount{ $id }    = 0;
    $coordCount{ $id }      = 0;
    $datasetIndex{ $id }    = 0;
    $datasetData{ $id }     = [];
    $globalData{ $id }      = {};

    return $self;
}

#---------------------------------------------------------------

=head2 addDataPoint ( coord, value, [ dataset ] )

Adds a datapoint at C<coord> with value C<value> to dataset C<dataset>

=head3 coord

The coordinate of the data. Pass as an array ref. If the coordinate is 1-dimensional you can also pass a scalar.

=head3 value 

The value that belong to the coordinate

=head3 dataset

The index of the dataset the data point should be added to. If omitted the current dataset will be used.

=cut

sub addDataPoint {
    my $self    = shift;
    my $coords  = shift;
    my $value   = shift;
    my $dataset = shift || $self->datasetIndex;
    
    if ($self->datasetCount == 0) {
        $datasetCount{ id $self } = 1;
    }
    # Wrap singular coordinates into an array ref.
    unless ( ref $coords eq 'ARRAY' ) {
        $coords = [ $coords ];
    }

    die "Cannot add data with ". @$coords ." coords to a dataset with ". $coordCount{ id $self }. " coords." 
        unless $self->checkCoords( $coords );

    my $lastCoord = pop @{ $coords };

    # Goto the location of the coords in the data hashref
    my $data = $data{ id $self };
    foreach ( @{ $coords } ) {
        $data = \%{ $data->{ $_ } };
    }

    # Add value to coords in dataset
    $data->{ $lastCoord }->{ data }->[ $dataset ] = $value;

    # Set min, max, total, etc.
    $self->updateStats( $data->{ $lastCoord }, [ @$coords, $lastCoord ], $value, $dataset );
}

sub addDataset {
    my $self    = shift;
    my $coords  = shift;
    my $values  = shift;

    die "Number of coordinates and values doesn't match" unless scalar @{ $coords } eq scalar @{ $values };

    # $datsetIndex starts at 0 for the first dataset.
    my $datasetIndex = $datasetCount{ id $self }++;
#    $datasetCount{ id $self }++;

    for my $index ( 0 .. scalar @{ $coords } - 1 ) {
        $self->addDataPoint( $coords->[ $index ], $values->[ $index ], $datasetIndex );
    }
}

sub checkCoords {
    my $self    = shift;
    my $coords  = shift;

    if ( $self->coordCount ) {
        return 1 if $self->coordCount == scalar @{ $coords };
        return 0;
    }
    
    $coordCount{ id $self } = scalar @{ $coords };

    return 1;
}

sub dumpData {
    my $self = shift;

    return 
        "------------- DATA --------------------------\n"
        . Dumper( $data{ id $self } )
        ."\n------------- PERDATASET --------------------\n"
        . Dumper( $datasetData{ id $self } )
        ."\n------------- GLOBAL ------------------------\n"
        . Dumper( $globalData{ id $self } );
}

sub getCoords {
    my $self = shift;

    return sort { $a <=> $b } keys %{ $data{ id $self } };
}

sub getDataPoint {
    my $self    = shift;
    my $coords  = shift;
    my $dataset = shift || $self->datasetIndex;
    my $data    = $data{ id $self };

    # Handle single coord systems quickly
    return $data->{ $coords }->{ data }->[ $dataset ] if ($self->coordCount == 1);

    # Other wise search for the right hash entry
    my $lastCoord = pop @{ $coords };

    # Goto the location of the coords in the data hashref
    my $data = $data{ id $self };
    foreach ( @{ $coords } ) {
        $data = \%{ $data->{ $_ } };
    }

    # Add value to coords in dataset
    return $data->{ $lastCoord }->{ data }->[ $dataset ];

}

sub updateStats {
    my $self        = shift;
    my $destination = shift;
    my $coords      = shift;
    my $value       = shift;
    my $dataset     = shift;
    my $id          = id $self;

#    unless (ref $value eq 'ARRAY') {
#        $value = [ $value ];
#    };
#
#    for my $i ( 0 .. scalar @{ $value } - 1) {
#        my $subVal = $value->[ $i ];
#            $min->[ $i ]    = $subVal if $subVal < $min->[ $i ] || !defined $min->[ $i ];
#            $max->[ $i ]    = $subVal if $subVal > $max->[ $i ] || !defined $max->[ $i ];
#            $total->[ $i ]  += $subVal;
#        }
#    }

    # process value
    for my $data ( $destination, $datasetData{ $id }->[ $dataset ], $globalData{ $id } ) {
        # process value
        $data->{ minValue   } = $value if !defined $data->{ minValue } || $value < $data->{ minValue };
        $data->{ maxValue   } = $value if !defined $data->{ maxValue } || $value > $data->{ maxValue };
        $data->{ total      } += $value;
        $data->{ absTotal   } += abs $value;

        # Don't process coords for $desitination;
        next if $data eq $destination;

        $data->{ coordCount }++;

        # process coords
        for my $i ( 0 .. scalar @{ $coords } - 1 ) {
            $data->{ minCoords }->[ $i ] = $coords->[ $i ] if $coords->[ $i ] < $data->{ minCoords }->[ $i ] 
                || !defined $data->{ minCoords }->[ $i ];
            $data->{ maxCoords }->[ $i ] = $coords->[ $i ] if $coords->[ $i ] > $data->{ maxCoords }->[ $i ] 
                || !defined $data->{ maxCoords }->[ $i ];
        }
    }
}

1;

