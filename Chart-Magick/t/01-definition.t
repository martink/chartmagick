#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Test::More tests => 24;
BEGIN {
    use_ok( 'Chart::Magick::Definition', 'Chart::Magick::Definition can be used' );
}

#####################################################################
#
# initializeProperties
#
#####################################################################
{
    my $wrong = NoDefinitionMethod->new;
    eval { $wrong->initializeProperties };
    ok( $@, 'initializeProperties will die if class has no definition method' );
    
    my $good = DummyDef->new;
    eval { $good->initializeProperties };
    ok( !$@, 'initializeProperties won\'t die if class has no definition method' );
}

#####################################################################
#
# get
#
#####################################################################
{
    my $dummy    = DummyDef->new;
    $dummy->initializeProperties;

    is( $dummy->get('string'), 'a',         'get fetches string defaults' );
    ok( $dummy->get('number') == 9,         'get fetches numerical defaults' );
    ok( !defined $dummy->get('undefined'),  'get fetches undef defaults' );
    ok( $dummy->get('zero') == 0,           'get fetches zero defaults' );
    is( $dummy->get('empty'), '',           'get fetches empty string defaults' );

    cmp_deeply( $dummy->get('arrayRef'),        [ 'a', 'b' ],   'get fetches array ref defaults' );
    cmp_deeply( $dummy->get('emptyArrayRef'),   [ ],            'get fetches empty array ref defaults' );
    cmp_deeply( $dummy->get('hashRef'),         { 'a' => 'b' }, 'get fetches hash ref defaults' );
    cmp_deeply( $dummy->get('emptyHashRef'),    { },            'get fetches empty hash ref defaults' );

    is( $dummy->get('subRef'), 2, 'get executes subRef defaults and returns the result' );
    my $args = $dummy->{_args};
    ok( scalar @$args == 1, 'get passes only one variable when calling a sub ref value');
    is( $dummy, $args->[0], 'get passes self to the subrefs it executes' );

    eval { $dummy->get('INVALID KEY') };
    ok( $@, 'get dies when a non-existant property is requested' );


    $dummy->set( string => 1234 );
    is( $dummy->get( 'string'), 1234, 'set can set a value and get fetches it' );
    
    $dummy->set( string => 5678, number => 9876 );
    my $ok = $dummy->get('string') == 5678 && $dummy->get('number') == 9876;
    ok( $ok, 'set accepts multple properties in the form of a hash' );

    $dummy->set( { string => 6789, number => 8765 } );
    $ok = $dummy->get('string') == 6789 && $dummy->get('number') == 8765;
    ok( $ok, 'set accepts multple properties in the form of a hash ref' );

    eval { $dummy->set( string => 345, INVALID_OPTION => 1 ) };
    ok( $@, 'set dies when an invalid option is passed' );

    my $dummy2 = DummyDef->new;
    $dummy2->initializeProperties( string => 'abcde', number => 192 );

    my $ok = $dummy2->get('string') eq 'abcde' && $dummy2->get('number') == 192;
    ok( $ok, 'initializeProperties sets properties to provided overrides' );

    my $dummy3 = DummyDef->new;
    eval { $dummy3->initializeProperties( string => 'abcde', INVALID => 1 ) };
    ok( $@, 'initializeProperties dies when a non-existing property is passed' );
    
    my $props = $dummy3->get;

    cmp_deeply(
        $props,
        { %{ $dummy3->definition }, subRef => 2 },
        'get returns all properties when no specific property is requested',
    );

    $props->{ number } = 78;
    cmp_deeply(
        $dummy3->get,
        { %{ $dummy3->definition }, subRef => 2 },
        'get returns a safe copy of the properties hash ref when no specific property is requested',
    );
}

#--------------------------------------------------------------------
package NoDefinitionMethod;
use base qw{ Chart::Magick::Definition };

sub new { bless {}, shift };

1;

#--------------------------------------------------------------------
package DummyDef;
use base qw{ Chart::Magick::Definition };

sub definition {
    my $self = shift;

    return {
        string          => 'a',
        number          => 9,
        undefined       => undef,
        zero            => 0,
        empty           => '',
        arrayRef        => [ 'a', 'b' ],
        emptyArrayRef   => [ ],
        hashRef         => { 'a' => 'b' },
        emptyHashRef    => { },
        subRef          => sub { $self->{_args} = [ @_ ]; return 2 },
    };
};

sub new { bless {}, shift };

1;

