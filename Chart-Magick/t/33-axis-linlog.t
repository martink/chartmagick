#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Chart::Magick::Axis::Lin;

use Test::More tests => 9;
BEGIN {
    use_ok( 'Chart::Magick::Axis::LinLog', 'Chart::Magick::Axis::Lin can be used' );
}

#####################################################################
#
# new
#
#####################################################################
{
    my $axis;
    eval { $axis = Chart::Magick::Axis::LinLog->new; };
    ok( !$@, 'new can be called' );
    is( ref $axis, 'Chart::Magick::Axis::LinLog', 'new returns an object of correct class' );
    isa_ok( $axis, 'Chart::Magick::Axis::Log', 'new returns an object that inherits from Chart::Magick::Axis::Log' );
}

#####################################################################
#
# adjustYRangeToOrigin
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::LinLog->new;

    $axis->set(
        yIncludeOrigin  => 1,
    );

    cmp_deeply(
        [ $axis->adjustYRangeToOrigin( 1, 2 ) ],
        [ 0, 2 ],
        'adjustYRangeToOrigin is not disabled',
    );
}

#####################################################################
#
# draw
#
#####################################################################
{
    no warnings 'redefine';

    my $state;  
    local *Chart::Magick::Axis::Lin::draw = sub { 
        my $self = shift;
        $state = $self->get('yExpandRange');
    };

    my $axis = Chart::Magick::Axis::LinLog->new;
    $axis->set(
        yExpandRange => 1,
    );

    $axis->draw;

    ok( defined $state, 'draw calls superclass method' );
    ok( !$state, 'draw disables yExpandRange' );
}

#####################################################################
#
# getYTicks
#
#####################################################################
{
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::LinLog->new;

    local *Chart::Magick::Axis::Lin::getYTicks = sub { return 'correct' };
 
    is( $axis->getYTicks, 'correct', 'getYTicks uses Chart::Magick::Axis::Lin::getYTicks to generate ticks' );
}   

#####################################################################
#
# transformX / transformY
#
#####################################################################
{
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::LinLog->new;

    local *Chart::Magick::Axis::Lin::transformY = sub { return "__$_[1]" };

    is( $axis->transformY( 100 ), '__100', 'transformY uses Chart::Magick::Axis::Lin::transformY' );
}

