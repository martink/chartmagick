package Chart::Magick::Matrix;

use strict;
use warnings;

use Carp;
use Image::Magick;
use Class::InsideOut qw{ :std };
use List::Util qw{ sum };

readonly    width   => my %width;
readonly    height  => my %height;
readonly    margin  => my %margin;
readonly    rows    => my %rows;
readonly    im      => my %im;

sub addAxis {
    my $self    = shift;
    my $axis    = shift;
    my $row     = shift || 0;
    my $weight  = shift || 1;

    push @{ $self->rows->[ $row ] }, [ $axis, $weight ];
}

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

sub new {
    my $class   = shift;
    my $width   = shift || croak "No width passed to Chart::Magick::Marker->new";
    my $height  = shift || croak "No height passed to Chart::Magick::Marker->new";
    my $margin  = shift || 20;

    my $self    = register $class;

    my $id = id $self;

    $width{ $id     } = $width;
    $height{ $id    } = $height;
    $margin{ $id    } = $margin;
    $rows{ $id      } = [];
    $im{ $id        } = Image::Magick->new;

    return $self;
};

sub draw {
    my $self = shift;

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
            
            $axis->set( width => $width, height => $rowHeight );
           
            $self->im->Composite(
                image   => $axis->draw,
                x       => $x,
                y       => $y,
            );

            $x += $width + $self->margin;
        }

        $y += $rowHeight + $self->margin;
    }

    return $self->im;
}

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

1;

