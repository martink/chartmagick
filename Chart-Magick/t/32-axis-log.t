#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Chart::Magick::Axis::Lin;

use Test::More tests => 44;
BEGIN {
    use_ok( 'Chart::Magick::Axis::Log', 'Chart::Magick::Axis::Lin can be used' );
}

#####################################################################
#
# new
#
#####################################################################
{
    my $axis;
    eval { $axis = Chart::Magick::Axis::Log->new; };
    ok( !$@, 'new can be called' );
    is( ref $axis, 'Chart::Magick::Axis::Log', 'new returns an object of correct class' );
    isa_ok( $axis, 'Chart::Magick::Axis::Lin', 'new returns an object that inherits from Chart::Magick::Axis::Lin' );
}

#####################################################################
#
# definition
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Log->new;
   
    my $def = $axis->definition;
    is( ref $def, 'HASH', 'definition returns a hash ref' );

    my $superDef    = Chart::Magick::Axis::Lin->new->definition;
    cmp_deeply(
        [ keys %{ $def } ],
        superbagof( keys %{ $superDef }  ),
        'definition includes all properties from super class' 
    );

    cmp_deeply(
        $def,
        superhashof( {
            xExpandRange    => ignore(),
            yExpandRange    => ignore(),
        } ),
        'definition adds the correct properties',
    );
}

#####################################################################
#
# adjustXRangeToOrigin / adjustYRangeToOrigin
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Log->new;

    $axis->set(
        xIncludeOrigin  => 1,
        yIncludeOrigin  => 1,
    );

    cmp_deeply(
        [ $axis->adjustXRangeToOrigin( 1, 2 ) ],
        [ 1, 2 ],
        'adjustXRangeToOrigin overrides superclass method to never include origin',
    );
    cmp_deeply(
        [ $axis->adjustYRangeToOrigin( 1, 2 ) ],
        [ 1, 2 ],
        'adjustYRangeToOrigin overrides superclass method to never include origin',
    );
}

#####################################################################
#
# draw
#
#####################################################################
{
    no warnings 'redefine';

    my $state = {}; 
    local *Chart::Magick::Axis::Lin::draw = sub { 
        my $self = shift;
        $state->{ x } = $self->get('xAlignAxesWithTicks');
        $state->{ y } = $self->get('yAlignAxesWithTicks');
    };

    my $axis = Chart::Magick::Axis::Log->new;
    $axis->set(
        xAlignAxesWithTicks => 1,
        yAlignAxesWithTicks => 1,
    );

    $axis->draw;

    ok( scalar keys %{$state} > 0, 'draw calls superclass method' );
    cmp_deeply(
        $state,
        { x => 0, y => 0 },
        'draw resets the x and yAlignAxesWithTicks flags prior to calling its super method',
    );
}

#####################################################################
#
# generateLogTicks
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Log->new;
    
    eval { $axis->generateLogTicks( -1, 10 ) };
    ok( $@, 'generateLogTicks dies when negative from values are passed' );

    eval { $axis->generateLogTicks( 0, 10 ) };
    ok( $@, 'generateLogTicks dies when a zero from value is passed' );

    eval { $axis->generateLogTicks( 10, 1 ) }; 
    ok( $@, 'generateLogTicks dies when to < from' );

    is( ref $axis->generateLogTicks( 1, 10 ), 'ARRAY', 'generateLogTicks returns an array ref' );

    cmp_deeply(
        $axis->generateLogTicks( 1, 100 ),
        [ 1, 10, 100 ],
        'generateLogTicks return correct ticks for tick aligned range',
    );
    cmp_deeply(
        $axis->generateLogTicks( 0.1, 100 ),
        [ 0.1, 1, 10, 100 ],
        'generateLogTicks can handle fractional lower boundaries',
    );
    cmp_deeply(
        $axis->generateLogTicks( 0.001, 0.1 ),
        [ 0.001, 0.01, 0.1 ],
        'generateLogTicks can handle fractional upper boundaries',
    );
    cmp_deeply(
        $axis->generateLogTicks( 0.5, 100 ),
        [ 0.1, 1, 10, 100 ],
        'generateLogTicks can handle non-aligned lower boundaries',
    );
    cmp_deeply(
        $axis->generateLogTicks( 1, 105 ),
        [ 1, 10, 100, 1000 ],
        'generateLogTicks can handle non-aligned upper boundaries',
    );
    cmp_deeply(
        $axis->generateLogTicks( 0.3, 53 ),
        [ 0.1, 1, 10, 100 ],
        'generateLogTicks can handle none-aligned upper and lower boundaries',
    );
}

#####################################################################
#
# getDataRange
#
#####################################################################
{
    my $axis    = Chart::Magick::Axis::Log->new;
    my $chart   = DummyChart->new;
    $chart->setDataRange( [ 0.3 ], [ 5 ], [ 0.5 ], [ 11 ] );
    $axis->addChart( $chart );

    $axis->set( xExpandRange => 0, yExpandRange    => 0 );
    cmp_deeply(
        [ $axis->getDataRange ],
        [ [ 0.3 ], [ 5 ], [ 0.5 ], [ 11 ] ],
        'getDataRange returns correct result with no range expansion',
    );

    $axis->set( xExpandRange => 1, yExpandRange    => 0 );
    cmp_deeply(
        [ $axis->getDataRange ],
        [ [ 0.1 ], [ 10 ], [ 0.5 ], [ 11 ] ],
        'getDataRange returns correct result with x range expansion',
    );

    $axis->set( xExpandRange => 0, yExpandRange    => 1 );
    cmp_deeply(
        [ $axis->getDataRange ],
        [ [ 0.3 ], [ 5 ], [ 0.1 ], [ 100 ] ],
        'getDataRange returns correct result with y range expansion',
    );

    $axis->set( xExpandRange => 1, yExpandRange    => 1 );
    cmp_deeply(
        [ $axis->getDataRange ],
        [ [ 0.1 ], [ 10 ], [ 0.1 ], [ 100 ] ],
        'getDataRange returns correct result with x and y range expansion',
    );
}

#####################################################################
#
# getXTicks / getYTicks
#
#####################################################################
{
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::Log->new;

    local *Chart::Magick::Axis::Log::generateLogTicks = sub { return [ "__$_[1]", "__$_[2]" ] };
 
    $axis->set(
        xStart  => 'xStart',
        xStop   => 'xStop',
        yStart  => 'yStart',
        yStop   => 'yStop',
    );

    cmp_deeply(
        $axis->getXTicks,
        [ '__xStart', '__xStop' ],
        'getXTicks uses generateLogTicks with correct values to generate ticks',
    );
    cmp_deeply(
        $axis->getYTicks,
        [ '__yStart', '__yStop' ],
        'getYTicks uses generateLogTicks with correct values to generate ticks',
    );
}   

#####################################################################
#
# logTransform
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Log->new;

    ok( !defined $axis->logTransform,       'logTransform returns undef for undef input' );
    ok( !defined $axis->logTransform( -1 ), 'logTransform returns undef for negative input' );
    ok( !defined $axis->logTransform( 0  ), 'logTransform returns undef for zero input' );

    cmp_ok( $axis->logTransform( 10 ), '==', 1,     'logTransform defaults to base 10' );
    is( $axis->logTransform( 10 ), '1.00000',       'logTransform returns with 5 digit precision' );
    is( $axis->logTransform( 1e100 ), '100.00000',  'logTransform can handle big numbers' );

    is( $axis->logTransform( 64, 2 ), '6.00000',    'logTransform can handle other bases' );
}

#####################################################################
#
# transformX / transformY
#
#####################################################################
{
    #TODO: Test carps!
    my $axis = Chart::Magick::Axis::Log->new;
    $axis->set( xStart => 0.1, yStart => 0.01 );

    # transformX
    cmp_ok( $axis->transformX( 10 ), '==', 1,  'transformX returns correct value for valid input' );
    cmp_ok( $axis->transformX( 0  ), '==', -1, 'transformX transform xStart for zero input' );
    cmp_ok( $axis->transformX( -2 ), '==', -1, 'transformX transform xStart for negative input' );

    $axis->set( xStart => 0 );
    cmp_ok( $axis->transformX( 0  ), '==', 0,  'transformX returns 0 for zero input and zero xStart' );
    cmp_ok( $axis->transformX( -2 ), '==', 0,  'transformX returns 0 for negative input and zero xStart' );

    # transformY
    cmp_ok( $axis->transformY( 10 ), '==', 1,  'transformY returns correct value for valid input' );
    cmp_ok( $axis->transformY( 0  ), '==', -2, 'transformY transform yStart for zero input' );
    cmp_ok( $axis->transformY( -2 ), '==', -2, 'transformY transform yStart for negative input' );

    $axis->set( yStart => 0 );
    cmp_ok( $axis->transformY( 0  ), '==', 0,  'transformY returns 0 for zero input and zero yStart' );
    cmp_ok( $axis->transformY( -2 ), '==', 0,  'transformY returns 0 for negative input and zero yStart' );

}

#--------------------------------------------------------------------
=pod

Dummy class used for tests in this file.

=cut

package DummyChart;
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


