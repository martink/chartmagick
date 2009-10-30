#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Test::More tests => 1;
BEGIN {
    use_ok( 'Chart::Magick::Axis::Lin', 'Chart::Magick::Axis::Lin can be used' );
}

#####################################################################
#
# new 
#
#####################################################################

