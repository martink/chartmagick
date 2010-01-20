#!perl 

use strict;

use Test::Deep          qw{ !all    };  # Prevent import of Test::Deep::all, since we'll import List::MoreUtils::all
use Scalar::Util        qw{ refaddr };
use List::MoreUtils     qw{ uniq    };
use List::Util          qw{ min max };
use Chart::Magick::Axis::Lin;

use Test::More tests => 20 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok( 'Chart::Magick::Chart::Bar', 'Chart::Magick::Chart::Bar can be used' );
}

#####################################################################
#
# new 
#
#####################################################################
{
    my $chart = Chart::Magick::Chart::Bar->new();
    ok( !$@, 'new can be called' );
    is( ref $chart, 'Chart::Magick::Chart::Bar', 'new returns an object of correct class' );
    isa_ok( $chart, 'Chart::Magick::Chart', 'new returns an object that inherits from Chart::Magick::Chart' );
}

#####################################################################
#
# definition
#
#####################################################################
{
    my $chart = Chart::Magick::Chart::Bar->new();
   
    my $superDef    = Chart::Magick::Chart->new->definition;
    my $def         = $chart->definition;
    is( ref $def, 'HASH', 'definition returns a hash ref' );

    cmp_deeply(
        [ keys %{ $def } ],
        superbagof( keys %{ $superDef }  ),
        'definition includes all properties from super class' 
    );

    cmp_deeply(
        $def,
        superhashof( {
            barWidth    => ignore(),
            barSpacing  => ignore(),
            drawMode    => ignore(),
        } ),
        'definition adds the correct properties',
    );
}

#####################################################################
#
# preprocessData
#
#####################################################################
#{
#    my $chart = setupDummyData();
#
#    $chart->preprocessData;
#    cmp_deeply(
#        [ map { $chart->axis->get($_) } qw{ xTickOffset xTickCount } ],
#        [ 1, 6 ],
#        'preprocessData makes the correct adjustments on an axis with default properties',
#    );
#
#    $chart->axis->set(
#        xTickOffset => 10,
#        xTickCount  => 100,
#    );
#    $chart->preprocessData;
#    cmp_deeply(
#        [ map { $chart->axis->get($_) } qw{ xTickOffset xTickCount } ],
#        [ 10, 6 ],
#        'preprocessData makes the correct adjustments on an axis with manually set properties',
#    );
#
#}

#####################################################################
#
# layoutHints
#
#####################################################################
{
    my $chart = setupDummyData();

    cmp_deeply(
        $chart->layoutHints,
        {
            coordPadding    => [ 0.5 ],
            valuePadding    => [ 0   ],
        },
        'layoutHints returns the correct hints',
    );
}

#####################################################################
#
# getDataRange
#
#####################################################################
{
    my $chart = setupDummyData();

    $chart->set( 'drawMode', 'sideBySide' );

    my @range = $chart->getDataRange;
    cmp_ok( scalar( @range ),                            '==', 4, 'getDataRange returns an array with four elements' );
    cmp_ok( scalar( grep { ref $_ eq 'ARRAY' } @range ), '==', 4, 'getDataRange returns an array of only arrayrefs'  );

    my @datasets    = testData();
    my @coords      = map { @{ $_->[0] } } @datasets;
    my @values      = map { @{ $_->[1] } } @datasets;

    cmp_deeply(
        \@range,
        [ [ min @coords ], [ max @coords ], [ min @values ], [ max @values ] ],
        'getDataRange returns correct value',
    );

    $chart->set( 'drawMode', 'cumulative' );

    @range = $chart->getDataRange;
    cmp_ok( scalar( @range ),                            '==', 4, 'getDataRange(cumulative) returns an array with four elements' );
    cmp_ok( scalar( grep { ref $_ eq 'ARRAY' } @range ), '==', 4, 'getDataRange(cumulative) returns an array of only arrayrefs'  );

    no warnings 'uninitialized';
    my %sums;
    foreach my $set ( @datasets ) {
        for ( 0 .. @{ $set->[0] } ) {
            $sums{ $set->[0][ $_ ] } += $set->[1][ $_ ];
        }
    }
    use warnings 'uninitialized';

    cmp_deeply(
        \@range,
        [ [ min @coords ], [ max @coords ], [ min values %sums ], [ max values %sums ] ],
        'getDataRange(cumulative) returns correct values',
    );

}

######################################################################
#
# drawBar
#
######################################################################
{
    no warnings qw{ redefine once };

    my $chart = setupDummyData();

    my ( $im, %args );
    local *Image::Magick::Draw = sub { $im = shift; %args = @_ };

    # col w h x x_off y
    my $color = $chart->getPalette->getNextColor;
    $chart->drawBar( $chart->axis->im, $color, 2, 6, 4 );
    is( $im, $chart->axis->im, 'drawBar draws on the correct image magick object' );

    my $coord = qr{\s*(\d+),(\d+)\s*};
    like( $args{ points }, qr{\s* M $coord L $coord L $coord L $coord Z \s*}x, 'drawBar produces valid closed svg path' );

    my @pairs = 
        grep    { @{ $_ } }
        map     { [ $_ =~ m{^$coord$} ] } 
        split   /[MLZ]/, $args{ points };
    
    cmp_ok( scalar( @pairs ), '==', 4, 'drawBar produces correct number of xy pairs' );

    my $orderOk = 1;
    my $prev;

    foreach my $pair ( @pairs, $pairs[0] ) {
        $orderOk = 0 unless !defined $prev || ( ( $prev->[0] != $pair->[0] ) xor ( $prev->[1] != $pair->[1] ) );
        $prev = $pair;
    }
    ok( $orderOk, 'drawBar draws lines in correct order' );

    is( $args{ stroke }, $color->getStrokeColor, 'drawBar uses correct stroke color' );
    is( $args{ fill   }, $color->getFillColor,   'drawBar uses correct fill color' );

    #TODO: test x_offset and bottom params
}

#####################################################################
#
# plot
#
#####################################################################


#--------------------------------------------------------------------
sub testData {
    my @indices = @_;
    my @data = (
        [ [ 1 .. 5 ], [   11 ..  15 ] ],
        [ [ 1 .. 5 ], [   21 ..  25 ] ],
        [ [ 1 .. 6 ], [  111 .. 116 ] ],
    );

    return @data[ @indices ] if @indices;
    return @data;
}

#--------------------------------------------------------------------
sub setupDummyData {
    my $chart = Chart::Magick::Chart::Bar->new;

    my @dummyData = testData();

    foreach ( @dummyData ) {
       $chart->addDataset( @{ $_ } );
    }
    
    my $palette = Chart::Magick::Palette->new( [
        { strokeAlpha => 0 },
        { strokeAlpha => 1 },
        { strokeAlpha => 2 },
    ] );
    $chart->setPalette( $palette );

    my $axis = Chart::Magick::Axis::Lin->new;
    $axis->addChart( $chart );
    $chart->setAxis( $axis );
    $axis->draw;

    return $chart;
}

#--------------------------------------------------------------------

=head2 processDraw

Used to keep track of all draw operations.

=cut

sub registerDraw {
    my $store   = shift;
    my $object  = shift;
    my %args    = @_;

    my $props   = {
        self    => $object,
        args    => \%args,
    };
    
    # Decode path 
    @{ $props }{ qw{ x1 y1 x2 y2 } } = $args{ points } =~ m/^\s*M\s*(\d+),(\d+)\s*L\s*(\d+),(\d+)\s*$/i;

    # Create lookup key
    my $key     = exists $args{ stroke } ? $args{ stroke } : -1;
    $key        =~ s{^#(\d+)$}{$1};
    $key        += 0; #convert to number ( 000001 => 1 )

    if ( exists $store->{ $key } ) {
        push @{ $store->{ $key } }, $props;
    }
    else {
        $store->{ $key } = [ $props ];
    }
}

#--------------------------------------------------------------------
sub isConnected {
    my $ops = shift || diag( 'empty op list' ) && return 0;

    my $prev = [];
    foreach my $op (@$ops) {
        if ( $op != $ops->[0] ) {
            return 0 unless $prev->[0] == $op->{ x1 } && $prev->[1] == $op->{ y1 };
        }
        
        $prev = [ $op->{ x2 }, $op->{ y2 } ];
    }

    return 1;
}
