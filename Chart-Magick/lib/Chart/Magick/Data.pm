package Chart::Magick::Data;

use strict;
use warnings;
use Moose;

####use Class::InsideOut qw{ :std };
use Carp;
use Data::Dumper;

#readonly data           => my %data;
has data => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        datasetCount    => 'count',
    }
);
#readonly labels         => my %labels;
has labels => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        setLabel        => 'set',
    },
);
#readonly coordDim       => my %coordDim;
has coordDim => (
    is      => 'rw',
    isa     => 'Int',
);
####readonly datasetCount   => my %datasetCount;
#readonly datasetIndex   => my %datasetIndex;
has datasetIndex => (
    is      => 'rw',
    default => 0,
);
#readonly datasetData    => my %datasetData;
has datasetData => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);
#readonly globalData     => my %globalData;
has globalData => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

=head1 NAME

Chart::Magick::Data - Dataset abstraction layer for use with the Chart::Magick class charting modules.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is used by the Chart::Magick modules to pass data into graphs. It is coordinate system agnostic
supports N dimensional coordinates and M dimensional values, with N and M both 1 or larger. It is up to each
individual charting plugin to decide how to handle these coordinates and values.

The following methods are available from this class:

=cut

#---------------------------------------------------------------

####=head2 new ( )
####
####Consructor.
####
####=cut 
####
####sub new {
####    my $class   = shift;
####    my $self    = {};
####
####    bless       $self, $class;
####    register    $self;
####
####    my $id = id $self;
########    $data{ $id          } = [];
########    $datasetCount{ $id  } = 0;
########    $coordDim{ $id      } = 0;
########    $datasetIndex{ $id  } = 0;
########    $datasetData{ $id   } = [];
########    $globalData{ $id    } = {};
########    $labels{ $id        } = [];
####
####    return $self;
####}

#---------------------------------------------------------------

=head2 addDataPoint ( coord, value, [ dataset ] )

adds a datapoint at C<coord> with value C<value> to dataset C<dataset>

=head3 coord

the coordinate of the data. Pass as an array ref. If the coordinate is 1-dimensional you can also pass a scalar.

=head3 value 

the value that belong to the coordinate

=head3 dataset

the index of the dataset the data point should be added to. If omitted the current dataset will be used.

=cut

sub addDataPoint {
    my $self    = shift;
    my $coords  = shift;
    my $value   = shift;
    my $dataset = shift || $self->datasetIndex;
    
####    if ($self->datasetCount == 0) {
####        $datasetCount{ id $self } = 1;
####    }
    # Wrap singular coordinates into an array ref.
    unless ( ref $coords eq 'ARRAY' ) {
        $coords = [ $coords ];
    }
    unless ( ref $value  eq 'ARRAY' ) {
        $value  = [ $value  ];
    }

    croak "Cannot add data with " . @$coords ." dimensional coords to a dataset with ". $self->coordDim. " dimensional coords." 
        unless $self->checkCoords( $coords );

    # Goto the location of the coords in the data hashref
#    my $data = $data{ id $self };
    my $data = $self->data;

    my $key = join '_', @{ $coords };
##########    $data->[ $dataset  ]->{ $key }->{ value } = $value;
    $data->[ $dataset  ]->{ $key } = $value;

    # Set min, max, total, etc.
    $self->updateStats( $coords, $value, $dataset );

    return;
}

#---------------------------------------------------------------

=head2 addDataset ( coords values )

adds a dataset. Multidimensional coords are always array refs, one dimensional coords may be either scalrs of array
refs with one element. The same goes for values.

=head3 coords

array ref of coords.

=head3 values

array ref of values.

=cut

sub addDataset {
    my $self    = shift;
    my $coords  = shift;
    my $values  = shift;
    my $label   = shift;

    croak "Number of coordinates and values doesn't match" unless scalar @{ $coords } eq scalar @{ $values };

    # $datsetIndex starts at 0 for the first dataset.
    my $datasetIndex = $self->datasetCount; ####$datasetCount{ id $self }++;

    for my $index ( 0 .. scalar @{ $coords } - 1 ) {
        $self->addDataPoint( $coords->[ $index ], $values->[ $index ], $datasetIndex );
    }

    # Set dataset name
    $self->setLabel( $datasetIndex, $label ) if $label;
####    $labels{ id $self }->[ $datasetIndex ] = $label if $label;

    return;
}

#---------------------------------------------------------------

=head2 checkCoords ( coord )

checks whether the passed coord is compatible with the other coords in the data object. The required dimension is
set by the first coord passed to this method.

note: coords (even one dimensional) must be array refs.

=head3 coord

the coord you want to check.

=cut

sub checkCoords {
    my $self    = shift;
    my $coords  = shift;

    if ( $self->coordDim ) {
        return 1 if $self->coordDim == scalar @{ $coords };
        return 0;
    }
    
    $self->coordDim( scalar @{ $coords } );

    return 1;
}

#---------------------------------------------------------------

=head2 dumpData ( )

debug method. Dumps the raw data in the object and the statistics both per dataset and global.

requires Data::Dumper to be installed.

=cut

sub dumpData {
    my $self = shift;

    my $ok = eval { require Data::Dumper; 1 };
    return "Cannot dump data since require Data::Dumper failed.\nError message:\n $@\n" if !$ok || $@;

    return 
         "\n------------- DATA --------------------------\n"
        . Dumper( $self->data )
        ."\n------------- PERDATASET --------------------\n"
        . Dumper( $self->datasetData )
        ."\n------------- GLOBAL ------------------------\n"
        . Dumper( $self->globalData );
}

#---------------------------------------------------------------

=head2 memUsage ( )

debug method. Returns memory usage stats for this object. Note that data is aquired by Devel::Sizev::total_size and
thus these numbers are not the total amount of used memory. Please read the documentation of Devel::Size for more
information.

requires Devel::Size

=cut

sub memUsage {
    my $self = shift;
    my $ok = eval { require Devel::Size; Devel::Size->import( 'total_size' ); 1 };
    return "Cannot display mem usage since require Devel::Size failed.\nError message:\n $@\n" if !$ok || $@;

    return 
         "\n------------- MEMORY USAGE ------------------\n"
        . "Data set     : " . total_size( $self->data )       . " bytes\n"
        . "Global stats : " . total_size( $self->globalData ) . " bytes\n"
        . "DS stats     : " . total_size( $self->datasetData ). " bytes\n";

}
#---------------------------------------------------------------

=head2 getCoords ( [ dataset ] )

Returns an array ref containing the sorted unique coords that are in either the specified dataset or all datasets.
These coords are array refs themselves. Please note that sorting for now is performed only on the first coord
element. 

=head3 dataset

Optional. The index of the dataset you want the coords of. Returns coords of all datasets if omitted.

=cut

sub getCoords {
    my $self    = shift;
    my $dataset = shift;

    my $data    = $self->data;

    my $coords  = defined $dataset 
                ? $data->[ $dataset ]
                : { map { %{$_} } @{$data} }
                ;

    # TODO: Fix coord sorting
    return [ 
        sort    { $a->[0] <=> $b->[0] }         # !!!only sorts on first coord, needs something more advanced
        map     { [ split /_/, $_ ] }           # decode the keys to actual coords
        keys    %$coords                        # coords are encoded in the keys of the data hash
    ];
}

#---------------------------------------------------------------

=head2 getDataPoint ( coord, [ dataset ] )

Returns the value at the given coord for the given dataset as an array ref. If there's no value at those coords for
the dataset undef will be returned.

=head3 coord

The coord for which the value should be retuned.

=head3 dataset

The index dataset of the dataset that should be used. If omitted, defaults to the current selected index.

=cut

sub getDataPoint {
    my $self    = shift;
    my $coords  = shift;
    my $dataset = shift || $self->datasetIndex;
    #### TODO: getDataset
    my $data    = $self->data->[ $dataset ];

    $coords = [ $coords ] if ( ref $coords ne 'ARRAY' );

    my $key = join '_', @{ $coords };
    return exists $data->{ $key } ? $data->{ $key } : undef;
##########
#    return exists $data->{ $key } ? $data->{ $key }->{ value } : undef;
}

#---------------------------------------------------------------

=head2 updateStats ( coord, value, dataset )

Analyzes the passed coord/value pair and updates the global and dataset stats if necessary.

=head3 coord

The coord for this data point.

=head3 value

The value for this data point.

=head3 dataset

The index of the dataset this datapoint belongs to.

=cut

sub updateStats {
    my $self        = shift;
#   my $destination = shift;
    my $coords      = shift;
    my $value       = shift;
    my $dataset     = shift;
#    my $id          = id $self;

    # process value
#    for my $data ( $destination, $datasetData{ $id }->[ $dataset ], $globalData{ $id } ) {
     # Update stats per dataset and globally.
     for my $data ( $self->datasetData->[ $dataset ], $self->globalData ) {
        # process value
        my $i = 0;
        foreach ( @{ $value } ) {
            $data->{ minValue   }->[ $i ]  = $_ if !defined $data->{ minValue }->[ $i ] || $_ < $data->{ minValue }->[ $i ]; 
            $data->{ maxValue   }->[ $i ]  = $_ if !defined $data->{ maxValue }->[ $i ] || $_ > $data->{ maxValue }->[ $i ];
            $data->{ posTotal   }->[ $i ] += $_ if $_ > 0;
            $data->{ negTotal   }->[ $i ] += $_ if $_ < 0;
            $data->{ total      }->[ $i ] += $_;
            $data->{ absTotal   }->[ $i ] += abs $_;

            $i++;
        }

        # Don't process coords for $desitination;
#        next if $data eq $destination;

        $data->{ coordCount }++;

        # process coords
        $i = 0;
        foreach ( @{ $coords } ) {
            $data->{ minCoord }->[ $i ] = $_ if !defined $data->{ minCoord }->[ $i ] || $_ < $data->{ minCoord }->[ $i ]; 
            $data->{ maxCoord }->[ $i ] = $_ if !defined $data->{ maxCoord }->[ $i ] || $_ > $data->{ maxCoord }->[ $i ];
        }
    }

    return;
}

1;

