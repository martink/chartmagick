package Chart::Magick::Marker;

use strict;

use Class::InsideOut qw{ :std };
use Carp;
use List::Util qw{ max };

readonly axis       => my %axis;
readonly marker     => my %marker;
readonly size       => my %size;
readonly anchorX    => my %anchorX;
readonly anchorY    => my %anchorY;

#---------------------------------------------
sub new {
    my $class       = shift;
    my $properties  = ref $_[0] eq 'HASH' ? shift : { @_ };
    
    my $self = bless {}, $class;
    register $self;

    my $id = id $self;

    $axis{ $id }    = $properties->{ axis };
    $size{ $id }    = $properties->{ size };
    $marker{ $id }  = 
          ( exists $properties->{ predefined } ) ? 
            $self->getPredefinedMarker( @{ $properties }{ 'predefined', 'strokeColor', 'fillColor' } )

        : ( exists $properties->{ fromFile } ) ? 
            $self->getMarkerFromFile( $properties->{ fromFile } )

        : ( exists $properties->{ magick } ) ? 
            $self->getImageMagickMarker( $properties->{ magick } )

        : croak "Chart::Magick::Marker->new requires one of the following properties: predefined, fromFile or magick";

    return $self;
}

#---------------------------------------------
sub draw {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;
    my $color   = shift || 'lightgray';
    my $id      = id $self;

    $self->axis->im->Composite(
        image   => $self->marker,
        gravity => 'NorthWest',
        x       => $x - $self->anchorX,
        y       => $y - $self->anchorY,
    ); 
}

#---------------------------------------------
sub getImageMagickMarker {
    my $self    = shift;
    my $im      = shift;

    return $im;
}

#---------------------------------------------
sub getMarkerFromFile {
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
sub getPredefinedMarker {
    my $self        = shift;
    my $shape       = shift || 'marker2';
    my $strokeColor = shift || 'black';
    my $fillColor   = shift || 'none';

    my $id      = id $self;
    my $size    = $size{ $id };

    my $markers = {
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
    };

    my $strokeWidth = 1;

    my $marker  = $markers->{ $shape };
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

