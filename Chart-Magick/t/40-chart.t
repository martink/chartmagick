#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Chart::Magick::Axis;

use Test::More tests => 19;
BEGIN {
    use_ok( 'Chart::Magick::Chart', 'Chart::Magick::Chart can be used' );
}

#sub addData {
#sub getDataRange {
#sub preprocessData {
#sub setMarker {

#####################################################################
#
# new 
#
#####################################################################
{
    my $chart = Chart::Magick::Chart->new();
    isa_ok( $chart, 'Chart::Magick::Chart', 'new returns object of correct class' );

    isa_ok( $chart->dataset, 'Chart::Magick::Data', 'new creates a Data object');
    ok( $chart->dataset->datasetCount == 0, 'new creates an empty Data object');
}

# TODO: New cannot set properties, should this change? It would be more conformant with Chart.
##--------------------------------------------------------------------
#{
#    my $chart = Chart::Magick::Chart->new( { width => 1234, height => 4321 } );
#
#    my $ok = $chart->get('width') == 1234 && $chart->get('height') == 4321;
#    ok( $ok, 'new accepts values for properties' );
#}
#
##--------------------------------------------------------------------
#{
#    eval { my $chart = Chart::Magick::Chart->new( { width => 1234, INVALID_OPTION => 1 } ) };
#    ok( $@, 'new dies when an invalid property is passed' );
#}
    
#####################################################################
#
# definition
#
#####################################################################
{
    my $chart = Chart::Magick::Chart->new;

    cmp_deeply( $chart->definition, {}, 'definition defines no properties for base class' );
}

#####################################################################
#
# getAxis / setAxis
#
#####################################################################
{
    my $chart = Chart::Magick::Chart->new;

    eval { $chart->getAxis };
    ok( $@, 'getAxis dies when no axis has been set' );

    # Add 4 tests for testGetSet
    $chart = testGetSet( 'Axis', $chart, 1 );
}

#####################################################################
#
# getPalette / setPalette
#
#####################################################################
{
    # Add 5 tests for testGetSet
    my $chart = testGetSet( 'Palette' );
}

#####################################################################
#
# getData / setData
#
#####################################################################
{
    # Add 5 tests for testGetSet
    my $chart = testGetSet( 'Data' );
}

#####################################################################
#
# setMarker
#
#####################################################################
{


}

#####################################################################
#
# addDataset
#
#####################################################################
{
    my $chart = Chart::Magick::Chart;

}




#####################################################################
#
# Utility subs.
#
#####################################################################


#--------------------------------------------------------------------
sub testGetSet {
    my $name        = shift;
    my $chart       = shift || Chart::Magick::Chart->new;
    my $noDefault   = shift;

    my $getter = "get$name";
    my $setter = "set$name";
    my $class  = "Chart::Magick::$name";

    unless ( $noDefault ) {
        my $default = $chart->$getter;
        isa_ok( $default, $class, "$getter creates and returns a $class if none is set" );
        is ( $chart->$getter, $default, "$getter caches the auto created palette time.");
    }

    eval { $chart->$setter( bless {}, 'Not::The::Right::Class' ) };
    ok( $@, "$setter dies when something is passed that is not a $class" );

    my $custom = $class->new;
    eval { $chart->$setter( $custom ); };
    ok( !$@, "$setter does accept $class objects" ); 

    is( $chart->$getter, $custom, "$setter makes the chart use the passed palette." );

    return $chart;
}


