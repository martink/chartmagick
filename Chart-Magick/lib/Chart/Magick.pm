package Chart::Magick;

use strict;
use warnings;

use Chart::Magick::Matrix;

our $VERSION = '0.1.0';

sub matrix {
    my $self    = shift;
    my $width   = shift;
    my $height  = shift;
    my $layout  = shift;

    my $matrix  = Chart::Magick::Matrix->new( $width, $height, 20 );

    foreach my $row (@$layout) {
        my @row;

        foreach my $type ( @$row ) {
            my $class = "Chart::Magick::Axis::$type";

            my $ok = eval "require $class; 1";
            die "Cannot instanciate axis class $class because: $@" if !$ok || $@;

            push @row, [ $class->new(), 1 ]
        }

        push @{ $matrix->rows }, \@row;
    }

    return $matrix;
}

1;

