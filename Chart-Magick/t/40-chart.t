#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Chart::Magick::Axis;

use Test::More tests => 26 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok( 'Chart::Magick::Chart', 'Chart::Magick::Chart can be used' );
}


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
    
#########################################################################
#####
##### definition
#####
#########################################################################
####{
####    my $chart = Chart::Magick::Chart->new;
####
####    cmp_deeply( 
####        $chart->definition, 
####        { 
####            markerSize => re('^\d+$'),              # default marker size must be a non-negative integer
####        }, 
####        'definition defines correct properties' );
####}

######################################################################
##
## getAxis / setAxis
##
######################################################################
#{
#    my $chart = Chart::Magick::Chart->new;
#
#    eval { $chart->getAxis };
#    ok( $@, 'getAxis dies when no axis has been set' );
#
#    # Add 4 tests for testGetSet
#    $chart = testGetSet( 'Axis', $chart, 1 );
#}

######################################################################
##
## getPalette / setPalette
##
######################################################################
#{
#    # Add 5 tests for testGetSet
#    my $chart = testGetSet( 'Palette' );
#}
#
######################################################################
##
## getData / setData
##
######################################################################
#{
#    # Add 5 tests for testGetSet
#    my $chart = testGetSet( 'Data' );
#}

#####################################################################
#
# setMarker
#
#####################################################################
{
    my $chart = Chart::Magick::Chart->new;

    cmp_deeply( 
        $chart->markers,
        [],
        'Initially no markers are set.',
    );

    eval { $chart->setMarker };
    ok( $@, 'setMarker dies when no marker name is passed' );
    
    eval { $chart->setMarker( 0, 'square' ) };
    ok( !$@, 'setMarker doesn\'t die when a marker name is passed' );
    
    my $expect = [ isa('Chart::Magick::Marker') ];
    cmp_deeply(
        $chart->markers,
        $expect,
        'setMarker adds marker object to marker array',
    );
    my $marker0 = refaddr( $chart->markers->[0] );
    
    $chart->setMarker( 3, 'triangle', 10 );
    $expect->[3] = isa('Chart::Magick::Marker');
    cmp_deeply(
        $chart->markers,
        $expect,
        'setMarker adds additional marker objects to the  given location',
    );
    cmp_ok( refaddr( $chart->markers->[0] ), '==', $marker0, 'setMarker does not interfere with marker objects at other locations' );

    $chart->setMarker( 0, 'circle', 12 );
    cmp_ok( refaddr( $chart->markers->[0] ), '!=', $marker0, 'setMarker overwrites marker defs at given location if present' );


}

#####################################################################
#
# addDataset
#
#####################################################################
{
    my $chart = Chart::Magick::Chart->new;
    my $data  = $chart->dataset;

    cmp_ok( $data->datasetCount, '==', 0, 'Initially no datasets are present' );

    my $coords = [ 0, 1, 2 ];
    my $values = [ 9, 8, 7 ];
    
    eval { $chart->addDataset };
    ok( $@, 'addDataset dies when no coords are given' );

    eval { $chart->addDataset( $coords ) };
    ok( $@, 'addDataset dies when no values are given' );

    eval { $chart->addDataset( $coords, $values ) };
    ok( !$@, 'addDataset doesn\'t die when both coords and values are given' );
    cmp_ok( $data->datasetCount, '==', 1, 'addDataset adds the dataset to the Data object' );
    cmp_deeply( 
        $data->getCoords( 0 ),
        [ map { [ $_ ] } @{ $coords } ],
        'addDataset passes the correct coords to the Data object',
    );
    cmp_deeply( 
        [ map { $data->getDataPoint( $_, 0 ) } @{ $coords } ],
        [ map { [ $_ ] } @{ $values } ],
        'addDataset passes the correct values to the Data object',
    );
    cmp_deeply(
        $chart->markers,
        [],
        'addDataset does not add markers when none are given',
    );

    my $coords2 = [ 5, 6, 7 ];
    my $values2 = [ 1, 2, 3 ];
    $chart->addDataset( $coords, $values, 'label', 'square', 43 );
    cmp_ok( $data->datasetCount, '==', 2, 'addDataset adds a new dataset to the Data object' );
    cmp_deeply(
        $chart->markers,
        [ undef, isa('Chart::Magick::Marker') ],
        'addDataset adds the correct marker def at the correct location',
    );
}

#####################################################################
#
#  preprocessData
#
#####################################################################
{
    # NOTE: preprocessData does nothing in Chart::Magick::Chart and just serves as an interface.
    #       As such this code tests nothing but is here for code coverage.
    my $chart = Chart::Magick::Chart->new;

    $chart->preprocessData;
}

#####################################################################
#
# getDataRange
#
#####################################################################
{
    my $chart = Chart::Magick::Chart->new;
    $chart->addDataset( [ -1, 3, 5 ], [  2, 8, -3 ] );
    $chart->addDataset( [  0, 7, 5 ], [ -8, 8,  3 ] );

    my $expect = $chart->dataset->globalData;
    my @range  = $chart->getDataRange;
    cmp_ok( scalar @range, '==', 4, 'getDataRange returns array of length 4' );

    cmp_ok( $range[ 0 ], '==', $expect->{ minCoord }, 'getDataRange returns correct min coord' );
    cmp_ok( $range[ 1 ], '==', $expect->{ maxCoord }, 'getDataRange returns correct max coord' );
    cmp_ok( $range[ 2 ], '==', $expect->{ minValue }, 'getDataRange returns correct min value' );
    cmp_ok( $range[ 3 ], '==', $expect->{ maxValue }, 'getDataRange returns correct max value' );
}

######################################################################
##
## setAxis / axis
##
######################################################################
#{
#    my $axis    = Chart::Magick::Axis->new;
#    my $chart   = Chart::Magick::Chart->new;
#    $chart->setAxis( $axis );
#     
#    is( $chart->axis, $axis,     'axis returns correct axis object' );
#}

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


