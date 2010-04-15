#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Chart::Magick::Axis::Lin;

use Test::More tests => 49 + 1;
use Test::NoWarnings;
use Test::Warn;
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
# adjustXRangeToOrigin / adjustYRangeToOrigin
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Log->new;

    $axis->xIncludeOrigin( 1 );
    $axis->yIncludeOrigin( 1 );

    cmp_deeply(
        [ $axis->adjustXRange( 1, 2 ) ],
        [ 1, 2 ],
        'adjustXRange overrides superclass method to never include origin',
    );
    cmp_deeply(
        [ $axis->adjustYRange( 1, 2 ) ],
        [ 1, 2 ],
        'adjustYRange overrides superclass method to never include origin',
    );
}

#####################################################################
#
# draw
#
#####################################################################
{
    no warnings qw{ redefine once };

    my $state = {}; 
    local *Chart::Magick::Axis::Lin::draw = sub { 
        my $self = shift;
        $state->{ x } = $self->xExpandRange;
        $state->{ y } = $self->yExpandRange;
    };

    my $axis = Chart::Magick::Axis::Log->new;
    $axis->xExpandRange( 1 );
    $axis->yExpandRange( 1 );

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

    $axis->xExpandRange( 0 );
    $axis->yExpandRange( 0 );
    cmp_deeply(
        [ $axis->getDataRange ],
        [ [ 0.3 ], [ 5 ], [ 0.5 ], [ 11 ] ],
        'getDataRange returns correct result with no range expansion',
    );

    $axis->xExpandRange( 1 );
    $axis->yExpandRange( 0 );
    cmp_deeply(
        [ $axis->getDataRange ],
        [ [ 0.1 ], [ 10 ], [ 0.5 ], [ 11 ] ],
        'getDataRange returns correct result with x range expansion',
    );

    $axis->xExpandRange( 0 );
    $axis->yExpandRange( 1 );
    cmp_deeply(
        [ $axis->getDataRange ],
        [ [ 0.3 ], [ 5 ], [ 0.1 ], [ 100 ] ],
        'getDataRange returns correct result with y range expansion',
    );

    $axis->xExpandRange( 1 );
    $axis->yExpandRange( 1 );
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
 
    $axis->xStart( 1 );
    $axis->xStop( 2 );
    $axis->yStart( 3 );
    $axis->yStop( 4 );

    cmp_deeply(
        $axis->getXTicks,
        [ '__1', '__2' ],
        'getXTicks uses generateLogTicks with correct values to generate ticks',
    );
    cmp_deeply(
        $axis->getYTicks,
        [ '__3', '__4' ],
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
    $axis->xStart( 0.1 );
    $axis->yStart( 0.01 );

    my $result;

    # transformX
    cmp_ok( $axis->transformX( 10 ), '==', 1,  'transformX returns correct value for valid input' );

    warning_is
        { $result = $axis->transformX( 0 ) }
        { carped => 'Cannot transform x value 0 to a logarithmic scale. Using 0.1 instead!' },
        'transformX carps for zero input';
    cmp_ok( $result, '==', -1, 'transformX transform xStart for zero input' );

    warning_is
        { $result = $axis->transformX( -2 ) }
        { carped => 'Cannot transform x value -2 to a logarithmic scale. Using 0.1 instead!' },
        'transformX carps for negative input';
    cmp_ok( $result, '==', -1, 'transformX transform xStart for negative input' );

    $axis->xStart( 0 );
    warning_is 
        { $result = $axis->transformX( 0  ) }
        { carped => 'Cannot transform x value 0 to a logarithmic scale. Using 0 instead!' },
        'transformX carps for zero input';
    cmp_ok( $result, '==', 0,  'transformX returns 0 for zero input and zero xStart' );

    warning_is
        { $result = $axis->transformX( -2 ) }
        { carped => 'Cannot transform x value -2 to a logarithmic scale. Using 0 instead!' },
        'transformX carps for negative input';
    cmp_ok( $result, '==', 0,  'transformX returns 0 for negative input and zero xStart' );

    # transformY
    cmp_ok( $axis->transformY( 10 ), '==', 1,  'transformY returns correct value for valid input' );
    warning_is
        { $result = $axis->transformY( 0 ) }
        { carped => 'Cannot transform y value 0 to a logarithmic scale. Using 0.01 instead!' },
        'transformY carps for zero input';
    cmp_ok( $result, '==', -2, 'transformY transforms yStart for zero input' );

    warning_is
        { $result = $axis->transformY( -2 ) }
        { carped => 'Cannot transform y value -2 to a logarithmic scale. Using 0.01 instead!' },
        'transformY carps for negative input';
    cmp_ok( $result, '==', -2, 'transformY transforms yStart for negative input' );

    $axis->yStart( 0 );
    warning_is 
        { $result = $axis->transformY( 0  ) }
        { carped => 'Cannot transform y value 0 to a logarithmic scale. Using 0 instead!' },
        'transformY carps for zero input';
    cmp_ok( $result, '==', 0,  'transformY returns 0 for zero input and zero yStart' );

    warning_is
        { $result = $axis->transformY( -2 ) }
        { carped => 'Cannot transform y value -2 to a logarithmic scale. Using 0 instead!' },
        'transformY carps for negative input';
    cmp_ok( $result, '==', 0,  'transformY returns 0 for negative input and zero yStart' );

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


