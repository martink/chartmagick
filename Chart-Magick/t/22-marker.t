#!perl

use strict;

use Test::Deep;
use Image::Magick;
use Chart::Magick::Axis;

use Test::More tests => 22;

BEGIN {
    use_ok( 'Chart::Magick::Marker', 'Chart::Magick::Marker can be used' );
}

my ($VALID_DEFAULT) = keys %Chart::Magick::Marker::DEFAULT_MARKERS;

#####################################################################
#
# isDefaultMarker
#
#####################################################################
{
    my @defaults = keys %Chart::Magick::Marker::DEFAULT_MARKERS;

    my $ok = 1;
    foreach my $name ( @defaults ) {
        $ok = 0 unless Chart::Magick::Marker->isDefaultMarker( $name );
    }

    ok( $ok, 'isDefaultMarker returns true for all default marker names' );
    ok( !Chart::Magick::Marker->isDefaultMarker( 'WRONG!' ), 'isDefaultMarker returns false for non-existant default names' );
}

#####################################################################
#
# new
#
#####################################################################
{
    my $marker;
    eval { $marker = Chart::Magick::Marker->new };
    ok( $@, 'new dies when no markername is passed' );

    eval { $marker = Chart::Magick::Marker->new( 'wrong_marker' ) };
    ok( $@, 'new dies when a non-existant marker is passed' );

    # default markers
    eval { $marker = Chart::Magick::Marker->new( $VALID_DEFAULT ); };
    ok( !$@, 'new accepts default markers' );
    isa_ok( $marker, 'Chart::Magick::Marker', 'new invoked with a default returns the correct object' );

    # image magick objects
    my $magick = Image::Magick->new;
    eval { $marker = Chart::Magick::Marker->new( $magick ); };
    ok( !$@, 'new accepts image magick objects' );
    isa_ok( $marker, 'Chart::Magick::Marker', 'new invoked with an Image::Magick object returns the correct object' );

    # file objects
    SKIP: {
        skip( q{'.' must be an existing file for these tests}, 2 ) unless -e 'bestanie';
        eval { $marker = Chart::Magick::Marker->new( '.' ); };
        ok( !$@, 'new accepts image file names' );
        isa_ok( $marker, 'Chart::Magick::Marker', 'new invoked with a filename returns the correct object' );
    }


    # TODO: test size, properties and axis
}

#####################################################################
#
# draw
#
#####################################################################
{
    no warnings 'redefine';
    my ($im, %args);
    local *Image::Magick::Composite = sub { $im = shift; %args = @_; return 'called' }; 

    my $axis = Chart::Magick::Axis->new;

    my $marker      = Chart::Magick::Marker->new( $VALID_DEFAULT, 5, $axis );
    my $called      = $marker->draw( 1, 2 );
    
    is( $called, 'called', 'draw uses compositing to draw markers' );
    is( $im, $axis->im, 'draw composites onto the Image::Magick object of the axis' );
    is( $args{ image }, $marker->im, 'draw composits the Image:Magick object containing the marker' );
    cmp_ok( $args{ x }, '==', 1 - $marker->anchorX, 'draw composites on the correct x coordinate' );
    cmp_ok( $args{ y }, '==', 2 - $marker->anchorY, 'draw composites on the correct y coordinate' );
}

#####################################################################
#
# createMarkerFromIM
#
#####################################################################
{
    my $marker = Chart::Magick::Marker->new( $VALID_DEFAULT );

    my $newMarker = Image::Magick->new;
    my $generatedMarker = $marker->createMarkerFromIM( $newMarker );

    is( $generatedMarker, $newMarker, 'createMarkerFromIM returns the IM object that is passed to it' );
}

#####################################################################
#
# createMarkerFromDefault
#
#####################################################################
{
    no warnings 'redefine';
    my ( $class, %args );
    local *Image::Magick::Draw = sub { $class = shift; %args = @_ };

    my $marker  = Chart::Magick::Marker->new( $VALID_DEFAULT );
    my $im      = $marker->im;
    my $new     = $marker->createMarkerFromDefault( 'marker2', '#123456', '#987654' );
    
    isnt( $im, $new, 'createMarkerFromDefault creates a new Image::Magick object' );
    isa_ok( $new, 'Image::Magick', 'createMarkerFromDefault returns a Image::Magick' );
    
    is( $class, $new, 'createMarkerFormDefault draws onto the IM object it returns' );
    is( $args{ stroke }, '#123456', 'createMarkerFormDefault correctly applies stroke color' );
    is( $args{ fill   }, '#987654', 'createMarkerFormDefault correctly applies fill color' );
    # TODO: potentially check strokewidth, and somehow path.
}

######################################################################
##
## GetMarkerFromFile
##
######################################################################
#{
#
#
#}

