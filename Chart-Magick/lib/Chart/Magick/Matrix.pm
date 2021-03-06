package Chart::Magick::Matrix;

use strict;
use warnings;
use Moose;
use Chart::Magick::Types;

use Carp;
use Image::Magick;
use List::Util qw{ sum };

has width => (
    is          => 'rw',
    isa         => 'PositiveOrZeroInt',
    required    => 1,
);
has height => (
    is          => 'rw',
    isa         => 'PositiveOrZeroInt',
    required    => 1,
);
has margin => (
    is          => 'rw',
    isa         => 'PositiveOrZeroInt',
    default     => 20,
);
has rows => (
    is          => 'rw',
    isa         => 'ArrayRef[ArrayRef]',
    default     => sub { [] },
);
has im => (
    is          => 'ro',
    isa         => 'Image::Magick',
    default     => sub { Image::Magick->new },
);
has isDrawn => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

=head1 NAME

Chart::Magick::Matrix

=head1 DESCRIPTION

Modulde to layout multple Chart::Magick::Axis objects onto a single canvas.

=head1 SYNOPSIS

    my $matrix = Chart::Magick::Matrix->new( 600, 300 ); 

    $matrix->addAxis( $axis1, 0 );   # Add an axis to the first row
    $matrix->addAxis( $axis2, 0 );   # Add another axis to the first row
    $matrix->addAxis( $axis3, 1 );   # Add an axis to the second row

    $matrix->write( 'matrix1.png' );

    # Yields the following layout
    #|-----------------------|
    #|    ax1    |    ax2    |
    #|-----------------------|
    #|          ax3          |
    #|-----------------------|


    $matrix->setWeight( 0, 1, 2 );  # Increase weight of $axis2

    $matrix->write( 'matrix2.png' );
    
    # Yields the following layout
    #|-----------------------|
    #|   ax1  |      ax2     |
    #|-----------------------|
    #|          ax3          |
    #|-----------------------|

=cut

=head2 addAxis ( axis, row,  weight )

Adds an Chart::Magick axis object to the given row.

=head3 axis

An instanciated Chart::Magick::Axis object.

=head3 row

The number of the row to add the axis to. First row is 0. Defaults to 0.

=head3 weight

The weight that should be assigned to this axis. Defaults to 1.

=cut

sub addAxis {
    my $self    = shift;
    my $axis    = shift;
    my $row     = shift || 0;
    my $weight  = shift || 1;

    push @{ $self->rows->[ $row ] }, [ $axis, $weight ];
}

=head2 getAxis ( row, col )

Return the Chart::Magick::Axis object at column C<col> of row C<row>.

=head3 row

The index of the row. First row is 0.

=head3 col

The index of the column. Fist column is 0.

=cut

sub getAxis {
    my $self    = shift;
    my $row     = shift;
    my $col     = shift;

    my $rows = $self->rows;

    if ( exists $rows->[ $row ] && exists $rows->[ $row ]->[ $col ] ) {
        return $rows->[ $row ]->[ $col ]->[0];
    }

    carp "No axis is set on row $row at index $col";
    return;
}

=head2 draw ( )

Renders the matrix.

=cut

sub draw {
    my $self = shift;

    # Delete any other canvases that are in the Image::Magick object.
    @{ $self->im } = ();

    # Create a new canvas of the correct size.
    $self->im->Set(
        size    => $self->width .'x'. $self->height,
    );
    $self->im->Read( 'xc:grey40' );

    my @rows        = @{ $self->rows };
    my $rowCount    = scalar( @rows );

    my $rowHeight   = ( $self->height - $self->margin ) / $rowCount - $self->margin;

    my $y = $self->margin;

    foreach my $row ( @rows ) {    
        my @columns     = @{ $row };
        my $colCount    = scalar @columns;

        my $baseWidth   = ( $self->width - $self->margin ) / $colCount - $self->margin;
        my $normFactor  = $baseWidth * $colCount / sum map { $_->[1] } @columns;

        my $x = $self->margin;
        for my $column ( @columns ) {
            my ( $axis, $weight ) = @{ $column };
            my $width   = $weight * $normFactor;
            
            $axis->width( $width );
            $axis->height( $rowHeight );
           
            $self->im->Composite(
                image   => $axis->draw,
                x       => $x,
                y       => $y,
            );

            $x += $width + $self->margin;
        }

        $y += $rowHeight + $self->margin;
    }

    $self->isDrawn( 1 );

    return $self;
}

=head2 setWeight ( row, col, weight )

Set the weight of the axis at row C<row> and index C<col> to the specified value.

=head3 row

The index of the row of the axis. First row is 0.

=head3 col

The index of the column of the axis. First column is 0.

=head3 weight

The weight that should be assigned to the axis.

=cut

sub setWeight {
    my $self    = shift;
    my $row     = shift;
    my $col     = shift;
    my $weight  = shift || 1;

    my $rows = $self->rows;

    if ( exists $rows->[ $row ] && exists $rows->[ $row ]->[ $col ] ) {
        $rows->[ $row ]->[ $col ]->[1] = $weight;
        
        return;
    }

    carp "Cannot set weight on row $row at index $col, because no axis is set";
    return;
}

=head2 write ( filename )

Writes the matrix to the filesystem. Filetype is determined by the extension of the filename.

=head3 filename

Full path and file name to the intended location of the image.

=cut

sub write {
    my $self        = shift;
    my $filename    = shift || croak 'No filename passed';

    $self->draw unless $self->isDrawn;

    my $error = $self->im->Write( $filename );
    croak "Could not write file $filename because $error" if $error;

    return;
}

=head2 display ( )

Opens a window and renders the graph in it. Opening the window is done by the Image::Magick->Display method, and
thus imagemagick should be compiled with the correct delegate for your windowing system.

=cut

sub display {
    my $self        = shift;

    $self->draw unless $self->isDrawn;

    my $error = $self->im->Display;
    croak "Could not open display because $error" if $error;

    return;
}

1;

