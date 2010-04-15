package Chart::Magick::Marker;

use strict;
use warnings;
use Moose;

use Carp;
use List::Util qw{ max };
use Scalar::Util qw{ blessed };
use Chart::Magick::ImageMagick;

has marker => (
    is      => 'rw',
);

has im => (
    is      => 'rw',
    isa     => 'Image::Magick',
);

has vector => (
    is          => 'rw',
    isa         => 'HashRef',
    predicate   => 'isVector',
);

has size => (
    is      => 'rw',
    isa     => 'Int',
    default => 6,
);

has anchorX => (
    is      => 'rw',
    default => 0,
);

has anchorY => (
    is      => 'rw',
    default => 0,
);

has color => (
    is      => 'rw',
    isa     => 'Chart::Magick::Color',
);

=head1 NAME

Chart::Magick::Marker

=head1 DESCRIPTION

A module that provides markers for use within the Chart::Magick system.

=head1 SYNOPSIS

=cut

#---------------------------------------------

=head1 DEFAULT MARKERS

Currently there are three default markers defined:

=over 4

=item *

triangle

=item *

square

=item *

cicrle

=back

=cut

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

=head1 METHODS

These methods are provided by this class:

=cut

#---------------------------------------------

=head2 isDefaultMarker ( name )

Returns a true value if name is the identifier of a default marker. See L</"DEFAULT MARKERS">.

=head3 name

The identifier you want to check.

=cut

sub isDefaultMarker {
    my $class = shift;
    my $label = shift || return 0;

    return exists $DEFAULT_MARKERS{ $label };
}

#---------------------------------------------

=head3 new ( marker, size, args )

Constructor.

=head3 marker

The marker you want to use. This could be any of the following:

=over 4

=item *

The name of a default marker. See L</"DEFAULT MARKERS">.

=item *

The path to an image file, that should be used as marker.

=item *

An instanciated Image::Magick object, which contains the image for the marker.

=back

=head3 size

The size of the marker in pixels. Markers will be scaled to this size in such way that neither width or height of
the image exeeds this value.

=head3 args

TODO: Do we still need these?

=cut

sub BUILD {
    my $self    = shift;
    my $marker  = $self->marker;

    if ( $self->isDefaultMarker( $marker ) ) {
        $self->createMarkerFromDefault( $marker );
    }
    elsif ( blessed( $marker ) && $marker->isa('Image::Magick') ) {
        $self->createMarkerFromIM( $marker );
    }
    elsif ( -e $marker ) {
        $self->createMarkerFromFile( $marker )
    }
    else {
        croak "Chart::Magick::Marker->new requires either a predefined marker, an image file path or an Image::Magick object";
    }

    return;
};

#---------------------------------------------

=head2 draw ( x, y, canvas, override )

Draws a marker onto canvas at coordinate x,y.

=head3 x

X coordinate of the markers on the canvas.

=head3 y

Y coordinate of the markers on the canvas.

=head3 canvas

Instanciated Image::Magick object onto which the marker should be drawn.

=head3 override

Optional hashref containing key value pairs that Image::Magick->Draw can understand. Mostly useful to override
stroke and fill. Only has effect for default markers.

=cut

sub draw {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;
    my $im      = shift;
    my $override= shift || {};

    if ( $self->isVector ) {
        my %vector = %{ $self->vector };
        if ( $self->color ) {
            $vector{ stroke } = $self->color->getStrokeColor;
        }
        $im->Draw(
            %vector,
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

=head2 createMarkerFromIM ( im )

Takes an Image::Magick object that should be used as a marker. Returns an Image::Magick object that can be used as
a marker.

=head3 im

An Image::Magick object that should be used as marker.

=cut

sub createMarkerFromIM {
    my $self    = shift;
    my $im      = shift;
    my $id      = id $self;

    $self->anchorX( $im->get('width')  / 2 );
    $self->anchorY( $im->get('height') / 2 );

    $self->im( $im );

    return;
}

#---------------------------------------------

=head3 createMarkerFromFile ( filename )

Loads an image file and creates an Image::Magick object from it that can be used as the actual marker.

=head3 filename

The file that should be used as marker.

=cut

sub createMarkerFromFile {
    my $self        = shift;
    my $filename    = shift || croak 'getMarkerFromFile requires a filename.';

    # open image
    my $im      = Chart::Magick::ImageMagick->new;
    my $error   = $im->Read( $filename );
    croak "getMarkerFromFile could not open file $filename because $error" if $error;

    # scale image
    my $size = $self->size;

    if ( $size ) {
        my $maxDimension = max( $im->Get('width'), $im->get('height') );
        my $scale = $size / $maxDimension;

        $im->Scale( 
            height  => $im->get('height') * $scale, 
            width   => $im->get('width')  * $scale,
        );
    }

    $self->anchorX( $im->get('width')  / 2 );
    $self->anchorY( $im->get('height') / 2 );

    $self->im( $im );

    return;
}

#-------------------------------------------

=head2 createMarkerFromDefault ( name, stroke, fill )

Set the current marker to a default.

=head3 name

The name of the default marker to use. See L</"DEFAULT MARKERS">.

=head3 stroke

Optional default stroke color for this marker. Color must be in a format that Image::Magick understands.
Defaults to 'black'.

=head3 fill

Optional default fill color for this marker. Color must be in a format that Image::Magick understands.
Defaults to 'none'.

=cut

sub createMarkerFromDefault {
    my $self        = shift;
    my $shape       = shift || 'square';
    my $strokeColor = shift || 'black';
    my $fillColor   = shift || 'none';

    my $strokeWidth = 1;

    my $marker  = $DEFAULT_MARKERS{ $shape };
    my $scale   = $self->size / $marker->{ size };
    my $path    = sprintf $marker->{ shape }, map { $_ * $scale } @{ $marker->{ points } };

    $self->vector( {
        primitive    => 'Path',
        stroke       => $strokeColor,
        strokewidth  => $strokeWidth,
        points       => $path,
        fill         => $fillColor,
        antialias    => 'true',
    } );

    return;
}    

1;

