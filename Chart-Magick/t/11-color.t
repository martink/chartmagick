#!perl -T

use Test::Deep;

use Test::More tests => 24;
BEGIN {
    use_ok( 'Chart::Magick::Color', 'Chart::Magick::Color can be used' );
}

#####################################################################
#
# new
#
#####################################################################

my $col = Chart::Magick::Color->new();

isa_ok( $col, 'Chart::Magick::Color', 'new returns object of correct class' );

is( $col->fillTriplet,      '000000',   'fillTriplet defaults to 000000'    );
is( $col->fillAlpha,        '00',       'fillAlpha defaults to 00'          );
is( $col->strokeTriplet,    '000000',   'strokeTriplet defaults to 000000'  );
is( $col->strokeAlpha,      '00',       'strokeAlpha defaults to 00'        );

my $col2 = Chart::Magick::Color->new( {
    strokeTriplet   => '456123',
    strokeAlpha     => '63',
    fillTriplet     => 'abcdef',
    fillAlpha       => '9a',
} );

is( $col2->fillTriplet,     'abcdef',   'new can set fillTriplet'    );
is( $col2->fillAlpha,       '9a',       'new can set fillAlpha'      );
is( $col2->strokeTriplet,   '456123',   'new can set strokeTriplet'  );
is( $col2->strokeAlpha,     '63',       'new can set strokeAlpha'    );

#####################################################################
#
# fillTriplet / fillAlpha / strokeTriplet / strokeAlpha
#
#####################################################################

$col->fillTriplet( '123456' );
$col->fillAlpha( '23' );
$col->strokeTriplet( '098765' );
$col->strokeAlpha( '90' );

is( $col->fillTriplet,      '123456',   'fillTriplet can be changed'    );
is( $col->fillAlpha,        '23',       'fillAlpha can be changed'      );
is( $col->strokeTriplet,    '098765',   'strokeTriplet can be changed'  );
is( $col->strokeAlpha,      '90',       'strokeAlpha can be changed'    );

#####################################################################
#
# getFillColor / getStrokeColor
#
#####################################################################

is( $col->getFillColor,     '#12345623',    'getFillColor returns correct value'    );
is( $col->getStrokeColor,   '#09876590',    'getStrokeColor returns correct value'  );

#####################################################################
#
# copy
#
#####################################################################

my $otherCol = $col->copy;

isa_ok( $col, 'Chart::Magick::Color', 'copy returns object of correct class' );
isnt(   $col, $otherCol, 'Copy creates new object' );

is( $col->fillTriplet,      '123456',   'Copy copies fillTriplet'    );
is( $col->fillAlpha,        '23',       'Copy copies fillAlpha'      );
is( $col->strokeTriplet,    '098765',   'Copy copies strokeTriplet'  );
is( $col->strokeAlpha,      '90',       'Copy copies strokeAlpha'    );

#####################################################################
#
# darken
#
#####################################################################

my $dark = $col->darken;

isa_ok( $col, 'Chart::Magick::Color', 'draken returns object of correct class' );
isnt(   $col, $otherCol, 'darken creates new object' );


#####################################################################
#
# 
#
#####################################################################
#####################################################################
#
# 
#
#####################################################################
#####################################################################
#
# 
#
#####################################################################
#####################################################################
#
# 
#
#####################################################################

