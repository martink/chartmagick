#!perl 

use strict;

use Test::Deep;
use Chart::Magick::Axis;
use Scalar::Util qw{ refaddr };

use Test::More tests => 42;
BEGIN {
    use_ok( 'Chart::Magick::Axis', 'Chart::Magick::Axis can be used' );
}

#####################################################################
#
# new 
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new();
    isa_ok( $axis, 'Chart::Magick::Axis', 'new returns object of correct class' );
}

#--------------------------------------------------------------------
{
    my $axis = Chart::Magick::Axis->new( { width => 1234, height => 4321 } );

    my $ok = $axis->get('width') == 1234 && $axis->get('height') == 4321;
    ok( $ok, 'new accepts values for properties' );
}

#--------------------------------------------------------------------
{
    eval { my $axis = Chart::Magick::Axis->new( { width => 1234, INVALID_OPTION => 1 } ) };
    ok( $@, 'new dies when an invalid property is passed' );
}

#####################################################################
#
# getCoordDimension / getValueDimension
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;

    ok( $axis->getCoordDimension == 0, 'getCoordDimension defaults to 0' );
    ok( $axis->getValueDimension == 0, 'getValueDimension defaults to 0' );
}

#####################################################################
#
# get / set (single property)
#
#####################################################################
{
    my $axis    = Chart::Magick::Axis->new;
    my $def     = $axis->definition;

    is( $axis->get( 'width'), $def->{ width }, 'get fetches default value set in definition if no value is set' );
    
    $axis->set( width => 1234 );
    is( $axis->get( 'width'), 1234, 'set can set a value and get fetches it' );

    my @args;
    $axis->set( width => sub { @args = @_; return 7890 } );
    is( $axis->get( 'width' ), 7890, 'get returns the value returned by a sub ref if a property is set to that' );
    ok( scalar @args == 1, 'get passes only one variable when calling a sub ref value');
    is( $axis, $args[0], 'get passes the axis object on which it is called when calling a sub ref value' );

}

#####################################################################
#
# set ( multiple / invalid properties )
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;

    $axis->set( width => 5678, height => 9876 );
    my $ok = $axis->get('width') == 5678 && $axis->get('height') == 9876;
    ok( $ok, 'set accepts multple properties in the form of a hash' );

    $axis->set( width => 6789, height => 8765 );
    my $ok = $axis->get('width') == 6789 && $axis->get('height') == 8765;
    ok( $ok, 'set accepts multple properties in the form of a hash ref' );

    eval { $axis->set( width => 345, INVALID_OPTION => 1 ) };
    ok( $@, 'set dies when an invalid option is passed' );
}

#####################################################################
#
# plotOption
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;

    $axis->plotOption( a => 'AAA' );
    my $expect = { a => 'AAA' };
    cmp_deeply( $axis->plotOption, $expect, 'plotOption can set and get variables' );

    $axis->plotOption( b => 'BBB', c => 5 );
    $expect = { a => 'AAA', b => 'BBB', c => 5 };
    cmp_deeply( $axis->plotOption, $expect, 'plotOption appends list of options when new options are passed' );

    $axis->plotOption( b => '!CCC' );
    $expect->{ b } = '!CCC';
    cmp_deeply( $axis->plotOption, $expect, 'plotOption replaces options when existing options are passed' );
    
    eval { $axis->plotOption( 'doesNotExist' ) };
    ok( $@, 'plotOption dies when a non-existant option is requested' );
}

#####################################################################
#
# im
#
#####################################################################
{
    my $axis1 = Chart::Magick::Axis->new;
    my $axis2 = Chart::Magick::Axis->new;

    isa_ok( $axis1->im, 'Image::Magick', 'im returns an Image::Magick object' );
    ok( $axis1 ne $axis2, 'im returns a unique Image::Magick instance for each object' );
}

#####################################################################
#
# addChart / charts
#
#####################################################################
{
    my $axis    = Chart::Magick::Axis->new;
    my $charts  = $axis->charts;

    is( ref $charts, 'ARRAY', 'charts returns an array ref' );
    ok( scalar @{ $axis->charts } == 0, 'charts returns an empty array ref when no Charts have been added yet' );

    eval { $axis->addChart( $axis ) };
    ok( $@, 'addChart dies when an object that is not a Chart::Magick::Chart is passed' );
    
    # Chart::Magick::Chart::Dummy is a dummy class defined at the bottom of this file.
    my $chart1 = Chart::Magick::Chart::Dummy->new;
    my $chart2 = Chart::Magick::Chart::Dummy->new;
    eval { 
        $axis->addChart( $chart1 );
        $axis->addChart( $chart2 );
    };
    ok( !$@, 'addChart doesn\'t die when an object that is a Chart::Magick::Chart is passed' );

    cmp_deeply( 
        [ map { refaddr $_ } @{ $axis->charts }   ], 
        [ map { refaddr $_ } ( $chart1, $chart2 ) ], 
        'charts return all added Chart objects in the correct order'  
    );    

    my $axis2 = Chart::Magick::Axis->new;
    $axis2->addChart( $chart2, $chart1 );

    cmp_deeply(
        [ map { refaddr $_ } @{ $axis2->charts }   ],
        [ map { refaddr $_ } ( $chart2, $chart1 ) ],
        'addChart can add multiple charts at once and keeps them in order',
    );
}

#####################################################################
#
# addLabels / getLabels
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;
    
    my $labels = {
        1   => 'a',
        2   => 'b',
        2.5 => 'c',
    };
    $axis->addLabels( $labels );

    my $got = $axis->getLabels( 0 );
    cmp_deeply( $got,             $labels,  'addLabels adds labels to the 0th axis by default' );
    cmp_deeply( $axis->getLabels, $labels,  'getLabels defaults to the 0th axis by default' );

    $got->{ 2 } = 'c';
    cmp_deeply( $axis->getLabels, $labels,  'getLabels returns a safe copy of the labels hash' );

    is( $axis->getLabels( 0, 2.5 ), 'c',    'getLabels returns the correct label when an existing coord is passed' );
    ok( !defined $axis->getLabels( 0, 9 ),  'getLabels returns undef when a non-existing coord is passed' );

    $axis->addLabels( { 7 => 'd', -10 => 'e' } );
    $labels->{   7 } = 'd';
    $labels->{ -10 } = 'e';
    cmp_deeply( $axis->getLabels, $labels, 'addLabels appends the label list with labels with different coords' );
    
    $axis->addLabels( { 2.5 => 'f' } );
    $labels->{ 2.5 } = 'f';
    cmp_deeply( $axis->getLabels, $labels, 'addLabels replaces existing labels with ones when existing coords are passed' );

    my $labels2 = {
        1   => 'x',
        2   => 'y',
        2.5 => 'z',
    };
    $axis->addLabels( $labels2, 1 );
    cmp_deeply( $axis->getLabels( 1 ), $labels2, 'addLabels can add labels to another axis' ); 
    cmp_deeply( $axis->getLabels( 0 ), $labels,  'addLabels: adding labels to one axis does not interfere with labels on another' );

}

#####################################################################
#
# plotFirst
#
#####################################################################

# plotFirst does nothing in Chart::Magick::Axis.

#####################################################################
#
# plotLast
#
#####################################################################
{
    my $called = 0;
    local *Chart::Magick::Axis::plotTitle = sub { $called = 1 };

    my $axis = Chart::Magick::Axis->new;
    $axis->plotLast;

    ok( $called, 'plotLast plots the title' );
}

#####################################################################
#
# checkFont
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;

    SKIP: {
        skip( "The checkFonts tests require that '.' is an existing file when using -e'", 3 ) unless -e '.';

        local *Image::Magick::QueryFont = sub { 
            my ( $self, $fontname ) = @_;
            return $fontname eq 'valid_font' ? '.' : 'FileThatDoesntExist';
        };
        
        ok( $axis->checkFont('.'),             'checkFont returns true when an existing font file is passed' );
        ok( $axis->checkFont('valid_font'),    'checkFont return true when a correctly resolvable font name is passed' );
        ok( !$axis->checkFont('invalid_font'), 'checkFont returns false for fontname that resolves to an existing font file' );
    }
}

#####################################################################
#
# project
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;

    eval { $axis->project( [], [] ) };
    ok( $@, 'project must be overloaded in sub class' );
}

#####################################################################
#
# toPx
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;

    local *Chart::Magick::Axis::project = sub { return ( 3, 4 ) };

    is( $axis->toPx, '3,4', 'toPx correctly formats the coordinate' );
}

#####################################################################
#
# getDataRange
#
#####################################################################
{
    my $axis = Chart::Magick::Axis->new;

    my $chart1 = Chart::Magick::Chart::Dummy->new;
    my $chart2 = Chart::Magick::Chart::Dummy->new;
    my $chart3 = Chart::Magick::Chart::Dummy->new;
    my $chart4 = Chart::Magick::Chart::Dummy->new;

    $axis->addChart( $chart1, $chart2, $chart3, $chart4 );

    $chart1->setDataRange( [   1, 2 ], [  800, -160 ], [ 3.12,  10   ], [ 140, -134 ] );
    $chart2->setDataRange( [ -10, 3 ], [  200,   -5 ], [ 3.12,  11   ], [  90, 1034 ] );
    $chart3->setDataRange( [   4, 1 ], [ -100, -320 ], [ 3.12,  -0.1 ], [  90,   34 ] );
    $chart4->setDataRange( [   0, 2 ], [    0,   -5 ], [ 0.00,   0   ], [   0,    0 ] );

    # chart                    2  3         1     2         4      3        1     2
    my $expect =         [ [ -10, 1 ], [  800,   -5 ], [    0,  -0.1 ], [ 140, 1034 ] ];

    # Override default behaviour so we can test processing of multidimensional coords and values.
    local *Chart::Magick::Axis::getCoordDimension = sub { return 2 };
    local *Chart::Magick::Axis::getValueDimension = sub { return 2 };

    cmp_deeply(
        [ $axis->getDataRange ],
        $expect,
        'getDataRange correctly returns the minimal range envelope to fit all charts'
    );
}

#sub preprocessData {
#sub textWrap {
#sub text {
#sub definition {
#sub draw {
#sub getDataRange {

#--------------------------------------------------------------------
=pod

Dummy class used for tests in this file.

=cut

package Chart::Magick::Chart::Dummy;
use strict;
use base qw{ Chart::Magick::Chart };

sub setDataRange {
    my $self = shift;
    $self->{ _dataRange } = [ @_ ];
}

sub getDataRange {
    my $self = shift;
    return @{ $self->{ _dataRange } || [] };
}

sub plot { };

1;

