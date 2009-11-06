#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };
use Chart::Magick::Axis::Lin;

use Test::More tests => 40;


BEGIN {
    use_ok( 'Chart::Magick::Chart::Line', 'Chart::Magick::Chart::Line can be used' );
}

#####################################################################
#
# new 
#
#####################################################################
{
    my $chart = Chart::Magick::Chart::Line->new();
    ok( !$@, 'new can be called' );
    is( ref $chart, 'Chart::Magick::Chart::Line', 'new returns an object of correct class' );
    isa_ok( $chart, 'Chart::Magick::Chart', 'new returns an object that inherits from Chart::Magick::Chart' );
}

#####################################################################
#
# definition
#
#####################################################################
{
    my $chart = Chart::Magick::Chart::Line->new();
   
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
            plotMarkers => ignore(),
            markerSize  => ignore(),
        } ),
        'definition adds the correct properties',
    );
}

#####################################################################
#
# plot
#
#####################################################################
{
    no warnings 'redefine';

    my $chart = Chart::Magick::Chart::Line->new;
    setupDummyData( $chart );

    my %drawStack;
    local *Image::Magick::Draw =  sub { registerDraw( \%drawStack, @_ ) };

    my @markerStack;
    local *Chart::Magick::Marker::draw = sub { shift; push @markerStack, [ @_ ] };

    $chart->plot;

    cmp_bag(
        [ keys %drawStack ],
        [ 0, 1, 2 ],
        'plot uses the appropriate colors',
    );

    
    ok( 
           isConnected( $drawStack{ 0 } )
        && isConnected( $drawStack{ 1 } )
        && isConnected( $drawStack{ 2 } ),
        'no gaps in lines' 
    );
}

#--------------------------------------------------------------------
sub setupDummyData {
    my $chart = shift;

    my @dummyData = (
        [ [   1 ..   5 ], [   11 ..  15 ] ],
        [ [  11 ..  16 ], [   21 ..  26 ] ],
        [ [ 101 .. 107 ], [  111 .. 117 ] ],
    );

    foreach ( @dummyData ) {
       $chart->addDataset( @{ $_ } );
       print "===>", $chart->dataset->datasetCount,"\n";
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
}


=head2 processDraw

Used to keep track of all draw operations.

=cut

sub registerDraw {
    my $store   = shift;
    my $object  = shift;
    my %args    = @_;

    my $key     = exists $args{ stroke } ? $args{ stroke } : -1;
    $key        =~ s{^#(\d+)$}{\1};
    $key += 0;
    my $props   = {
        self    => $object,
        args    => \%args,
    };

    if ( exists $store->{ $key } ) {
        push @{ $store->{ $key } }, $props;
    }
    else {
        $store->{ $key } = [ $props ];
    }
}

sub isConnected {
    my $ops = shift || diag( 'empty op list' ) && return 0;

    my $prev = [];
    foreach my $op (@$ops) {
        my ($x1,$y1,$x2,$y2) = $op->{ points } =~ m/^\s*M\s*(\d+),(\d+)\s*L\s*(\d+),(\d+)\s*$/i;

        if ( $op != $ops->[0] ) {
        print "tsjak";
            return 0 unless $prev->[0] == $x1 && $prev->[1] == $y1;
        }
        
        $prev = [ $x2, $y2 ];
    }

    return 1;
}
