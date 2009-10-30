#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Test::More tests => 6;
BEGIN {
    use_ok( 'Chart::Magick::Chart', 'Chart::Magick::Chart can be used' );
}

#sub addData {
#sub getDataRange {
#sub getPalette {
#sub preprocessData {
#sub setChart {
#sub setData {
#sub setMarker {
#sub setPalette {

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
# getPalette
#
#####################################################################
{
    my $chart = Chart::Magick::Chart->new;

    my $palette = $chart->getPalette;
    isa_ok( $palette, 'Chart::Magick::Palette', 'getPalette returns a Chart::Magick::Palette' );
}
