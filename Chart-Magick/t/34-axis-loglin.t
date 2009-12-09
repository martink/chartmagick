#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Chart::Magick::Axis::Lin;

use Test::More tests => 9;
BEGIN {
    use_ok( 'Chart::Magick::Axis::LogLin', 'Chart::Magick::Axis::Lin can be used' );
}

#####################################################################
#
# new
#
#####################################################################
{
    my $axis;
    eval { $axis = Chart::Magick::Axis::LogLin->new; };
    ok( !$@, 'new can be called' );
    is( ref $axis, 'Chart::Magick::Axis::LogLin', 'new returns an object of correct class' );
    isa_ok( $axis, 'Chart::Magick::Axis::Log', 'new returns an object that inherits from Chart::Magick::Axis::Log' );
}

#####################################################################
#
# adjustXRangeToOrigin
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::LogLin->new;

    $axis->set(
        xIncludeOrigin  => 1,
    );

    cmp_deeply(
        [ $axis->adjustXRangeToOrigin( 1, 2 ) ],
        [ 0, 2 ],
        'adjustXRangeToOrigin is not disabled',
    );
}

#####################################################################
#
# draw
#
#####################################################################
{
    no warnings qw{ redefine once };

    my $state;  
    local *Chart::Magick::Axis::Lin::draw = sub { 
        my $self = shift;
        $state = $self->get('xExpandRange');
    };

    my $axis = Chart::Magick::Axis::LogLin->new;
    $axis->set(
        xExpandRange => 1,
    );

    $axis->draw;

    ok( defined $state, 'draw calls superclass method' );
    ok( !$state, 'draw disables xExpandRange' );
}

#####################################################################
#
# getXTicks
#
#####################################################################
{
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::LogLin->new;

    local *Chart::Magick::Axis::Lin::getXTicks = sub { return 'correct' };
 
    is( $axis->getXTicks, 'correct', 'getXTicks uses Chart::Magick::Axis::Lin::getXTicks to generate ticks' );
}   

#####################################################################
#
# transformX / transformX
#
#####################################################################
{
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::LogLin->new;

    local *Chart::Magick::Axis::Lin::transformX = sub { return "__$_[1]" };

    is( $axis->transformX( 100 ), '__100', 'transformX uses Chart::Magick::Axis::Lin::transformX' );
}

