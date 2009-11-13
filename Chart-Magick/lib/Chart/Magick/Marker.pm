package Chart::Magick::Marker;

use strict;
use warnings;

use Class::InsideOut qw{ :std };
use Carp;
use List::Util qw{ max };
use Scalar::Util qw{ blessed };

readonly axis       => my %axis;
readonly im         => my %im;
readonly size       => my %size;
readonly anchorX    => my %anchorX;
readonly anchorY    => my %anchorY;

#---------------------------------------------
our %DEFAULT_MARKERS = (
    marker1 => {
        width   => 1,
        height  => 0.75,
        shape   => [
            [ 'M', 0,    0.75   ],
            [ 'L', 0.5,  0      ],
            [ 'L', 1,    0.75   ],
            [ 'L', 0,    0.75   ],
        ],
    },
    marker2 => { 
        width   => 1,
        height  => 1,
        shape   => [
            [ 'M',  0,   0      ],
            [ 'L',  1,   0      ],
            [ 'L',  1,   1      ],
            [ 'L',  0,   1      ],
            [ 'L',  0,   0      ],
        ],
    },
);

#---------------------------------------------
sub isDefaultMarker {
    my $class = shift;
    my $label = shift || return 0;

    return exists $DEFAULT_MARKERS{ $label };
}

#---------------------------------------------
sub new {
    my $class   = shift;
    my $marker  = shift || q{};
    my $size    = shift || 5;
    my $axis    = shift;
    my $args    = shift || {};
    
    my $self    = bless {}, $class;
    register $self;

    my $id = id $self;

    $axis{ $id }    = $axis;
    $size{ $id }    = $size;
    $im{ $id }  = 
          ( $self->isDefaultMarker( $marker ) ) ? 
            $self->createMarkerFromDefault( $marker, $args->{ strokeColor }, $args->{ fillColor } )

        : ( blessed( $marker ) && $marker->isa('Image::Magick') ) ? 
            $self->createMarkerFromIM( $marker )

        : ( -e $marker ) ? 
            $self->createMarkerFromFile( $marker )

        : croak "Chart::Magick::Marker->new requires either a predefined marker, an image file path or an Image::Magick object";

    return $self;
}

#---------------------------------------------
sub draw {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;

    $self->axis->im->Composite(
        image   => $self->im,
        gravity => 'NorthWest',
        x       => $x - $self->anchorX,
        y       => $y - $self->anchorY,
    ); 

    return;
}

#---------------------------------------------
sub createMarkerFromIM {
    my $self    = shift;
    my $im      = shift;

    return $im;
}

#---------------------------------------------
sub createMarkerFromFile {
    my $self        = shift;
    my $filename    = shift || croak 'getMarkerFromFile requires a filename.';
    my $id          = id $self;

    # open image
    my $im      = Image::Magick->new;
    my $error   = $im->Read( $filename );
    croak "getMarkerFromFile could not open file $filename because $error" if $error;

    # scale image
    my $size = $size{ $id };

    if ( $size ) {
        my $maxDimension = max( $im->Get('width'), $im->get('height') );
        my $scale = $size / $maxDimension;

        $im->Scale( 
            height  => $im->get('height') * $scale, 
            width   => $im->get('width')  * $scale,
        );
    }

    $anchorX{ $id } = $im->get('width')  / 2;
    $anchorY{ $id } = $im->get('height') / 2;

    return $im;
}

#---------------------------------------------
sub createMarkerFromDefault {
    my $self        = shift;
    my $shape       = shift || 'marker2';
    my $strokeColor = shift || 'black';
    my $fillColor   = shift || 'none';

    my $id      = id $self;
    my $size    = $size{ $id };

    my $strokeWidth = 1;

    my $marker  = $DEFAULT_MARKERS{ $shape };
    my $path    = join ' ', map { $_->[0] . $size*$_->[1] . ',' . $size*$_->[2] } @{ $marker->{ shape } };
    my $width   = $size * $marker->{ width  } + $strokeWidth;
    my $height  = $size * $marker->{ height } + $strokeWidth;

    $anchorX{ $id } = $size * $marker->{ width } / 2;
    $anchorY{ $id } = $size * $marker->{ height } / 2;

    my $im = Image::Magick->new( size => $width .'x'. $height, index => 1 );
    $im->ReadImage( 'xc:none' );
    $im->Draw(
       primitive    => 'Path',
       stroke       => $strokeColor,
       strokewidth  => $strokeWidth,
       points       => $path,
       fill         => $fillColor,
       antialias    => 'true',
    );
    
    return $im;
}    

1;

