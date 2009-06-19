#!perl -T

use Test::Deep;

use Test::More tests => 21;


BEGIN {
    use_ok( 'Chart::Magick::Data', 'Chart::Magick::Data can be used' );
}

#####################################################################
#
# new
#
#####################################################################

my $data = Chart::Magick::Data->new();

isa_ok( $data, 'Chart::Magick::Data', 'new returns object of correct class' );

#####################################################################
#
# addDataPoint
#
#####################################################################

eval { $data->addDataPoint( 1, 2 ); };
ok(     $@ eq '',   'we can add a 1x1 dimensional data point');

eval { $data->addDataPoint( 2, 3 ); };
ok(     $@ eq '',   'we can add another 1x1 dimensional datapoint');

eval { $data->addDataPoint( [ 1, 2 ], 3 ); };
ok(     $@,         'we cannot mix coords of different dimensionality');

# TODO: See whether we want this behaviour or not.
#eval { $data->addDataPoint( 1, [3 ,4] ); };
#ok(     $@,         'we cannot mix values of different dimensionality');

eval { $data->addDataPoint( [ 1, 2 ], [ 3, 4 ] ); };
ok(     $@,         'we cannot mix coords and values of different dimensionality');

eval { $data->addDataPoint( 6, 7, 1 ) };
ok(     $@ eq '',   'we can add data to another dataset within the object' );

#####################################################################
#
# getDataPoint
#
#####################################################################

my $val     = $data->getDataPoint( 1, 0 );
ok( ref $val eq 'ARRAY', 'getDataPoint returns arrays refs' );

my $sameVal = $data->getDataPoint( [ 1 ], 0 );
is( $val->[0], $sameVal->[0], 'getDataPoint returns same value when invoked with coords in arrayref notation' );

my ( @gotDs0, @gotDs1 );
for ( 1, 2, 6 ) {
    push @gotDs0, $data->getDataPoint( $_, 0 );
    push @gotDs1, $data->getDataPoint( $_, 1 );
}
my @expectDs0 = ( [ 2 ], [ 3 ], undef );
my @expectDs1 = ( undef, undef, [ 7 ] );

cmp_deeply( \@expectDs0, \@gotDs0, 'getDataPoint returns correct values for one dataset' );
cmp_deeply( \@expectDs1, \@gotDs1, 'getDataPoint returns correct values for another dataset' );
    
#####################################################################
#
# getCoords
#
#####################################################################

my @gotAllCoords = $data->getCoords;
my @expect       = ( [ 1 ], [ 2 ], [ 6 ] );
cmp_deeply( \@gotAllCoords, \@expect, 'getCoords returns correct coords for all datasets' );

my @gotDs0Coords = $data->getCoords( 0 );
@expect          = ( [ 1 ], [ 2 ] );
cmp_deeply( \@gotDs0Coords, \@expect, 'getCoords returns correct coords for dataset 0' );

my @gotDs1Coords = $data->getCoords( 1 );
@expect          = ( [ 6 ] );
cmp_deeply( \@gotDs1Coords, \@expect, 'getCoords returns correct coords for dataset 1' );

#####################################################################
#
# addDataset
#
#####################################################################

#####################################################################
#
# checkCoords
#
#####################################################################

my $coordCheck  = Chart::Magick::Data->new;
my $correct     = $coordCheck->checkCoords( [ 1, 2, 3 ] );

is( $coordCheck->coordDim, 3,   'checkCoords sets the coord dimension upon the first check' );
ok( $correct,                   'checkCoords returns true for the first check' );

my $alsoCorrect = $coordCheck->checkCoords( [ 5, 6, -2 ] );
ok( $alsoCorrect,               'checkCoords returns true for other coords with the same dimensionality' );

my $wrong       = $coordCheck->checkCoords( [ 1, 2 ] );
is( $coordCheck->coordDim, 3,   'using checkCoords with lower dimensinal coords does not alter coordDim' );
ok( !$wrong,                    'checkCoords returns false for lower dimensional coords' );

my $alsoWrong   = $coordCheck->checkCoords( [ 1, 2, 3, 4 ] );
is( $coordCheck->coordDim, 3,   'using checkCoords with higher dimensinal coords does not alter coordDim' );
ok( !$alsoWrong,                'checkCoords returns false for higher dimensional coords' );


#####################################################################
#
# updateStats
#
#####################################################################


#---------------------------------------------------------------------------------------------------------
# The methods below are for debugging purposes only and don't need testing real bad. 

#####################################################################
#
# dumpData
#
#####################################################################

#####################################################################
#
# memUsage
#
#####################################################################


