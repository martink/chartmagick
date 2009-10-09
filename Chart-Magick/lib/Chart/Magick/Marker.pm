package Chart::Magick::Marker;

use strict;

use Class::InsideOut;
use Carp;

readonly axis   => my %axis;
readonly marker => my %marker;
readonly size   => my %size;

sub new {
    my $class       = shift;
    my $properties  = ref $_[0] eq 'HASH' ? shift : { @_ };
    
    my $self = bless {}, $class;
    register $self;

    my $id = id $self;

    $axis{ $id }    = $properties->{ axis };
    $size{ $id }    = $properties->{ size }
    $marker{ $id }  = 
        exists $properties->{ predefined }  ? $self->getPredefinedMarker( $properties->{ predefined } ) :
        exists $properties->{ fromFile }    ? $self->getMarkerFromFile( $properties->{ fromFile } )     :
        exists $properties->{ im }          ? $self->getImageMagickMarker( $properties->{ im } )        :
        croak "Chart::Magick::Marker->new requires one of the following properties: predefined, fromFile or im";

    return $self;
}

sub draw {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;
    my $color   = shift || 'lightgray';

    $self->axis->im->Composite(
        image   => $self->im,
        gravity => 'Center',
        x       => $x,
        y       => $y,
    }
}

sub getPredefinedMarker {
    my $self    = shift;
    my $shape   = shift || 'marker2';

    my $size    = $size{ id $self };

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
        marker2 => [
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

    my $marker  = $markers->{ $shape };
    my $path    = join ' ', map { $_->[0] . $size*$_[1] . ',' . $size*$_[2] } @{ $marker->{ shape };
    my $width   = $size * $marker->{ width  };
    my $height  = $size * $marker->{ height };

#    my $translateX = int( $x - 0.5*$size + 0.5 );
#    my $translateY = int( $y - 0.5*$size + 0.5 );

    my $im = Image::Magick->new( width => $width, height => $height );
    $im->ReadImage( 'xc:none' );
    $im->Draw(
       primitive    => 'Path',
       stroke       => 'lightgrey', #$color,
       strokewidth  => 1,
       points       => $path,
       fill         => 'none',
       # Use an affine transform here, since the translate option doesn't work at all...
#       translate    => [ 100, 100 ], #"$translateX,$translateY",
#       affine       => [ 1, 0, 0, 1, $translateX,$translateY ],
       antialias    => 'true',
    );

    return $im;
}    

1;

