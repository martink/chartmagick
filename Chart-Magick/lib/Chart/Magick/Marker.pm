package Chart::Magick::Marker;

use strict;
use warnings;

use Class::InsideOut qw{ :std };
use Carp;
use List::Util qw{ max };
use Scalar::Util qw{ blessed };
use Chart::Magick::ImageMagick;

readonly im         => my %im;
readonly direct     => my %direct;
readonly size       => my %size;
readonly anchorX    => my %anchorX;
readonly anchorY    => my %anchorY;
readonly color      => my %color;

#---------------------------------------------
our %DEFAULT_MARKERS = (
    triangle => {
        size    => 1,
        shape   => 'm%f,%f l%f,%f l%f,%f Z', 
        points  => [ 0, -0.6, 0.5, 1, -1, 0 ],
    },
    square => { 
        size    => 1,
        shape   => 'm%f,%f l%f,%f l%f,%f l%f,%f Z',
        points  => [ 0.5, -0.5, -1, 0, 0, 1, 1, 0 ],
    },
    circle => { 
        size    => 2,
        shape   => 'm%f,%f a%f,%f 0 0,0 %f,%f a%f,%f 0 0,0 %f,%f',
        points  => [ 1, 0, 1, 1, -2, 0, 1, 1, 2, 0 ],
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
    my $size    = shift || 6;
    my $args    = shift || {};
    
    my $self    = bless {}, $class;
    register $self;

    my $id = id $self;

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
    my $im      = shift;
    my $override= shift || {};

    my $direct = $direct{ id $self };
    if ($direct) {
        if ( $self->color ) {
            $direct->{ stroke } = $self->color->getStrokeColor;
        }
        $im->Draw(
            %$direct,
            %$override,
            x   => $x,
            y   => $y,
        );
    }
    else {
        $im->Composite(
            image   => $self->im,
            gravity => 'NorthWest',
            x       => $x - $self->anchorX,
            y       => $y - $self->anchorY,
        ); 
    }

    return;
}

#---------------------------------------------
sub createMarkerFromIM {
    my $self    = shift;
    my $im      = shift;
    my $id      = id $self;

    $anchorX{ $id } = $im->get('width')  / 2;
    $anchorY{ $id } = $im->get('height') / 2;

    return $im;
}

#---------------------------------------------
sub createMarkerFromFile {
    my $self        = shift;
    my $filename    = shift || croak 'getMarkerFromFile requires a filename.';
    my $id          = id $self;

    # open image
    my $im      = Chart::Magick::ImageMagick->new;
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

#-------------------------------------------
sub createMarkerFromDefault {
    my $self        = shift;
    my $shape       = shift || 'square';
    my $strokeColor = shift || 'black';
    my $fillColor   = shift || 'none';

    my $strokeWidth = 1;

    my $marker  = $DEFAULT_MARKERS{ $shape };
    my $scale   = $self->size / $marker->{ size };
    my $path    = sprintf $marker->{ shape }, map { $_ * $scale } @{ $marker->{ points } };

    $direct{ id $self }  = {
        primitive    => 'Path',
        stroke       => $strokeColor,
        strokewidth  => $strokeWidth,
        points       => $path,
        fill         => $fillColor,
        antialias    => 'true',
    },

    return;
}    

#-------------------------------------------
sub setColor {
    my $self    = shift;
    my $color   = shift;
    $color{ id $self } = $color;

    return $self;
}

1;

