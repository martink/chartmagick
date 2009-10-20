#!perl -T

use strict;

use Test::Deep;
use Chart::Magick::Color;
use Scalar::Util qw{ refaddr };

use Test::More tests => 26;
BEGIN {
    use_ok( 'Chart::Magick::Palette', 'Chart::Magick::Palette can be used' );
}

my $col1 = Chart::Magick::Color->new( { fillTriplet => '000001' } );
my $col2 = Chart::Magick::Color->new( { fillTriplet => '000002' } );
my $col3 = Chart::Magick::Color->new( { fillTriplet => '000003' } );
my $col4 = Chart::Magick::Color->new( { fillTriplet => '000004' } );
my $col5 = Chart::Magick::Color->new( { fillTriplet => '000005' } );

#####################################################################
#
# new and getColor
#
#####################################################################
{
    my $palette = Chart::Magick::Palette->new();
    isa_ok( $palette, 'Chart::Magick::Palette', 'new returns object of correct class' );
}

#--------------------------------------------------------------------
{
    my $palette = Chart::Magick::Palette->new( [ $col1, $col2, $col3 ] );
    my $orderOk = 
           $col1 eq $palette->getColor( 0 )
        && $col2 eq $palette->getColor( 1 )
        && $col3 eq $palette->getColor( 2 );

    ok( $orderOk, 'New can add color object in the correct order and keeps the actual Color instances' );
    ok( $col3 eq $palette->getColor( -1 ), 'New only adds color objects that are passed to it.' );
}

#--------------------------------------------------------------------
{
    my $palette = Chart::Magick::Palette->new( [ 
        { fillTriplet => '00000a' }, 
        { fillTriplet => '00000b' }, 
        { fillTriplet => '00000c' }, 
    ] );
    my $classOk = 
        $palette->getColor( 0 )->isa( 'Chart::Magick::Color' )
        && $palette->getColor( 1 )->isa( 'Chart::Magick::Color' )
        && $palette->getColor( 2 )->isa( 'Chart::Magick::Color' );

    ok( $classOk, 'New can take color property hashes and instaciate Color object from them');

    my $orderOk = 
        $palette->getColor( 0 )->fillTriplet eq '00000a'
        && $palette->getColor( 1 )->fillTriplet eq '00000b'
        && $palette->getColor( 2 )->fillTriplet eq '00000c';

    ok( $orderOk, 'New can add color property hashes and keep them in order' );
    is( $palette->getColor( -1 )->fillTriplet, '00000c', 'New only adds colors for hashref passed to it.' );
}

#--------------------------------------------------------------------
{
    my $palette = Chart::Magick::Palette->new( [ 
        $col1,
        { fillTriplet => '00000b' }, 
        $col3,
    ] );

    my $orderOk = 
           $palette->getColor( 0 )              eq $col1
        && $palette->getColor( 1 )->fillTriplet eq '00000b'
        && $palette->getColor( 2 )              eq $col3;

    ok( $orderOk, 'New accepts mixed Color objects and property hashrefs' );
}

#####################################################################
#
# getNumberOfColors
#
#####################################################################
{
    my $p0 = Chart::Magick::Palette->new;
    my $p1 = Chart::Magick::Palette->new( [ $col1, $col2 ] );
    my $p2 = Chart::Magick::Palette->new( [ $col1, $col2, $col3, { } ] );

    is( $p0->getNumberOfColors, 0, 'getNumberOfColors returns 0 for empty palette' );
    is( $p1->getNumberOfColors, 2, 'getNumberOfColors returns correct value' );
    is( $p2->getNumberOfColors, 4, 'getNumberOfColors counts colors created from hashrefs too' );
}

#####################################################################
#
# getPaletteIndex and setPaletteIndex
#
#####################################################################
{
    my $palette = Chart::Magick::Palette->new( [ $col1, $col2, $col3 ] );

    is( $palette->getPaletteIndex, 0, 'getPaletteIndex initializes on 0' );

    $palette->setPaletteIndex( 1 );
    is( $palette->getPaletteIndex, 1, 'setPaletteIndex sets palette index to passed index' );

    $palette->setPaletteIndex( -1 );
    is( $palette->getPaletteIndex, 0, 'setPaletteIndex sets palette index to 0 for negative indices' );

    $palette->setPaletteIndex( 3 );
    is( $palette->getPaletteIndex, 2, 'setPaletteIndex sets palette index to last color index for incices > num of colors' );
}

#####################################################################
#
# getColor - extra tests
#
#####################################################################
{
    my $palette = Chart::Magick::Palette->new( [ $col1, $col2, $col3 ] );

    my $c1 = $palette->getColor;
    $palette->setPaletteIndex( 1 );
    my $c2 = $palette->getColor;
    my $colorsOk = 
           $c1 eq $col1 
        && $c2 eq $col2;

    ok( $colorsOk, 'getColor uses palette index if no index is passed' );
}

#####################################################################
#
# addColor
#
#####################################################################
{    
    my $palette = Chart::Magick::Palette->new( [ $col1, $col2, $col3 ] );
    $palette->addColor( $col4 );

    ok( $palette->getColor( 3 ) eq $col4, 'addColor add a color onto the end of the color list' );

    my $colorsOk = 
        $col1 eq $palette->getColor( 0 )
        && $col2 eq $palette->getColor( 1 )
        && $col3 eq $palette->getColor( 2 );

    ok( $colorsOk, 'addColor does not change the other colors in the palette.' );
}

#####################################################################
#
# getColorIndex
#
#####################################################################
{
    my $palette = Chart::Magick::Palette->new( [ $col1, $col2, $col3, $col4 ] );

    # Lookup out of order to be sure that query order does not influence the result.
    my $indexOk = 
        $palette->getColorIndex( $col1 ) == 0
        && $palette->getColorIndex( $col3 ) == 2
        && $palette->getColorIndex( $col2 ) == 1
        && $palette->getColorIndex( $col4 ) == 3;

    ok( $indexOk, 'getColorIndex returns the correct index for each color' );
    ok( !defined $palette->getColorIndex( $col5 ), 'getColorIndex returns undef for colors not in the palette' );
}

#####################################################################
#
# getColorsInPalette
#
#####################################################################
{
    my $palette = Chart::Magick::Palette->new( [ $col1, $col2, $col3 ] );    
    my $colors  = $palette->getColorsInPalette;

    is( ref $colors, 'ARRAY', 'getColorsInPalette returns array ref' );
    
    my $expect = [ $col1, $col2, $col3 ];
    cmp_deeply(
        $colors,
        $expect,
        'getColorsInPalette returns correct colors',
    );

    # Try to change a color via the array ref...
    $colors->[1] = $col4;

    cmp_deeply(
        $palette->getColorsInPalette,
        $expect,
        'getColorsInPalette returns a safe copy of the internal color array',
    );
}

#####################################################################
#
# getNextColor
#
#####################################################################
{
    my $colors  = [ $col1, $col2, $col3, $col4 ];
    my $palette = Chart::Magick::Palette->new( $colors );

    my $got     = [ map { $palette->getNextColor } ( 1 .. 4 ) ];
use Data::Dumper;
print join( ",", map { refaddr $_ } @$got )."\n";
print join( ",", map { refaddr $_ } @$colors)."\n";
    # TODO: This doesn't fail while it should!!!!
    cmp_deeply(
        $got,
        $colors,
        'getNextColor returns correct colors',
    );
print join( ",", map { refaddr $_ } @$got )."\n";
print join( ",", map { refaddr $_ } @$colors)."\n";

    my $col = $palette->getNextColor;
    is( $col, $col1, 'getNextColor starts at the first color again when crossing the last color' );

    $palette->setPaletteIndex( 2 );
    $col    = $palette->getNextColor;
    is( $col, $col4, 'getNextColor take ito account the palette index.' ); 
}

#sub previousColor {
#sub removeColor {
#sub setColor {
#sub setPaletteIndex {
#sub swapColors {



