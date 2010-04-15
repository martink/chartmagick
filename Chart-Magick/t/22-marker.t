#!perl

use strict;

use Test::Deep;
use Image::Magick;
use Chart::Magick::Axis;

use Test::More tests => 26 + 1;
use Test::NoWarnings;

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

    eval { $marker = Chart::Magick::Marker->new( marker => 'wrong_marker' ) };
    ok( $@, 'new dies when a non-existant marker is passed' );

    # default markers
    eval { $marker = Chart::Magick::Marker->new( marker => $VALID_DEFAULT ); };
    ok( !$@, 'new accepts default markers' );
    isa_ok( $marker, 'Chart::Magick::Marker', 'new invoked with a default returns the correct object' );

    # image magick objects
    my $magick = Image::Magick->new( size => '1x1' );
    $magick->Read('xc:white');
    eval { $marker = Chart::Magick::Marker->new( marker => $magick ); };
    ok( !$@, 'new accepts image magick objects' );
    isa_ok( $marker, 'Chart::Magick::Marker', 'new invoked with an Image::Magick object returns the correct object' );

    # file objects
    SKIP: {
        skip( q{'.' must be an existing file for these tests}, 2 ) unless -e 'bestanie';
        eval { $marker = Chart::Magick::Marker->new( marker => '.' ); };
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
    my ( $im, %args, $draw_called, $comp_called );
    local *Image::Magick::Draw      = sub { $im = shift; %args = @_; $draw_called = 'called' }; 
    local *Image::Magick::Composite = sub { $im = shift; %args = @_; $comp_called = 'called' }; 

    my $axis    = Chart::Magick::Axis->new;
    my $marker  = Chart::Magick::Marker->new( marker => $VALID_DEFAULT, size => 5, axis => $axis );
    my $canvas  = Image::Magick->new(size => "100x100");
    $canvas->Read('xc:white');

    # --- Predefined markers ------------------------
    $marker->draw( 1, 2, $canvas );
    is( $draw_called,   'called', 'draw uses Draw to draw markers for line markers' );
    is( $im, $canvas,    'draw draws onto custom IM object if one is passed' );
    cmp_ok( $args{ x }, '==', 1, 'draw starts drawing on the correct x coordinate' );
    cmp_ok( $args{ y }, '==', 2, 'draw starts drawing on the correct y coordinate' );

    my %args_without = %args;
    $marker->draw( 1, 2, $canvas, { over => 'Ride' } );
    cmp_deeply(
        { %args                         },
        { %args_without, over => 'Ride' },
        'draw correctly passes overrides to ImageMagick',
    );

    # --- Image markers -----------------------------
    $draw_called= undef;
    $im         = undef;
    %args       = ();

    my $image   = Image::Magick->new(size => "10x10");
    $image->Read('xc:white');
    $marker     = Chart::Magick::Marker->new( marker => $image, size => 5, axis => $axis );

    $marker->draw( 1, 2, $canvas );
    is( $comp_called,   'called',   'draw uses compositing to draw image markers' );
    is( $im,            $canvas,    'draw composites onto the passed Image::Magick object' );
    is( $args{ image }, $marker->im,'draw composits the Image:Magick object containing the marker' );
    cmp_ok( $args{ x }, '==', 1 - $marker->anchorX, 'draw composites on the correct x coordinate' );
    cmp_ok( $args{ y }, '==', 2 - $marker->anchorY, 'draw composites on the correct y coordinate' );

    %args_without = %args;
    $marker->draw( 1, 2, $canvas, { over => 'Ride' } );
    cmp_deeply(
        { %args         },
        { %args_without },
        'draw correctly ignores overrides when compositing markers',
    );
}

#####################################################################
#
# createMarkerFromIM
#
#####################################################################
{
    my $marker = Chart::Magick::Marker->new( marker => $VALID_DEFAULT );

    my $newMarker = Image::Magick->new( size => '1x1' );
    $newMarker->Read('xc:white');
    my $generatedMarker = $marker->createMarkerFromIM( $newMarker );

    is( $marker->im, $newMarker, 'createMarkerFromIM sets the im attribute to the object that is passed to it' );
}

#####################################################################
#
# createMarkerFromDefault
#
#####################################################################
{
    my $marker  = Chart::Magick::Marker->new( marker => $VALID_DEFAULT );
    my $im      = $marker->im;
    my $new     = $marker->createMarkerFromDefault( $VALID_DEFAULT, '#123456', '#987654' );
    
    is( $marker->vector->{ stroke }, '#123456', 'createMarkerFormDefault correctly applies stroke color' );
    is( $marker->vector->{ fill   }, '#987654', 'createMarkerFormDefault correctly applies fill color' );
    is( $marker->vector->{ primitive }, 'Path', 'createMarkerFormDefault uses SVG Path definitions to draw' );
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

