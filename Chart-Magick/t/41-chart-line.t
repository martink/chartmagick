#!perl 

use strict;

use Test::Deep          qw{ !all    };  # Prevent import of Test::Deep::all, since we'll import List::MoreUtils::all
use Scalar::Util        qw{ refaddr };
use List::MoreUtils     qw{ all     };
use List::Util          qw{ sum min };
use Chart::Magick::Axis::Lin;

use Test::More tests => 9 + 1;
use Test::NoWarnings;

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
# plot
#
#####################################################################
{
    no warnings 'redefine';

    my $chart = Chart::Magick::Chart::Line->new;
    setupDummyData( $chart );

    my $drawOrder = 0;
    my %drawStack;
    local *Image::Magick::Draw =  sub { registerDraw( \%drawStack, @_, drawOrder => $drawOrder++ ) };

    my %markers;
    local *Chart::Magick::Marker::draw = sub { shift; $markers{ "$_[0],$_[1]" } = $drawOrder++ };
    local *Chart::Magick::Marker::createMarkerFromDefault = sub { };    # prevent this sub from doing draw ops

    my $canvas = Chart::Magick::ImageMagick->new( size => '1x1' );
    $canvas->Read( 'xc:white' );

    $chart->plot( $canvas );

    # check if the lines are plotted correctly
    cmp_bag(
        [ keys %drawStack ],
        [ 0, 1, 2 ],
        'plot draws the correct number of datasets',
    );

    cmp_deeply(
        { map { $_ => scalar @{ $drawStack{$_}->{ points }  } } ( 0 .. 2 ) },
        { map { $_ => scalar @{ testData( $_ )->[0]         } } ( 0 .. 2 ) },
        'plot draws the correct number of datapoints in the correct color for each dataset',
    );

    # check if markers are drawn correctly
    %drawStack = %markers = ();
    $drawOrder = 0;
    $chart->setMarker( 0, 'square' );
    $chart->setMarker( 2, 'triangle' );
    $chart->plot( $canvas );

    cmp_ok( 
        scalar keys %markers, '==', sum( map { scalar @{ $_->[0] } } testData(0, 2) ),
        'plot draws the correct number of  markers',
    );

    cmp_bag(
        [ keys %markers ],
        [ map { ( @{$drawStack{ $_ }->{ points }} ) } (0,2)  ],
        'plot draws markers at the right coords'
    );

    # check if markers are drawn on top of lines
    my $onTopOk;
    foreach ( values %drawStack ) {
        my @points = @{ $_->{ points } };
        
        next unless scalar @markers{ @points };

        $onTopOk = ( $_->{ drawOrder } || 0 ) < min @markers{ @points };
        last unless $onTopOk;
    }
    ok( $onTopOk, 'plot draws markers on top of line segments' );
}

#--------------------------------------------------------------------
sub testData {
    my @indices = @_;
    my @data = (
        [ [   1 ..   5 ], [   11 ..  15 ] ],
        [ [  11 ..  16 ], [   21 ..  26 ] ],
        [ [ 101 .. 107 ], [  111 .. 117 ] ],
    );

    return @data[ @indices ] if @indices;
    return @data;
}

#--------------------------------------------------------------------
sub setupDummyData {
    my $chart = shift;

    my @dummyData = testData();

    foreach ( @dummyData ) {
       $chart->addDataset( @{ $_ } );
    }
    
    my $palette = Chart::Magick::Palette->new( [
        { strokeAlpha => '0' },
        { strokeAlpha => '1' },
        { strokeAlpha => '2' },
    ] );
    $chart->palette( $palette );

    my $axis = Chart::Magick::Axis::Lin->new;
    $axis->addChart( $chart );
    $chart->axis( $axis );
    $axis->draw;
}

#--------------------------------------------------------------------

=head2 registerDraw

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
#    @{ $props }{ qw{ x1 y1 x2 y2 } } = $args{ points } =~ m/^\s*M\s*(\d+),(\d+)\s*L\s*(\d+),(\d+)\s*$/i;
    $props->{ points } = [ split / /, $args{points} ];

    # Create lookup key
    my $key     = exists $args{ stroke } ? $args{ stroke } : -1;
    $key        =~ s{^#(\d+)$}{$1}i;
    $key        += 0; #convert to number ( 000001 => 1 )

    $store->{ $key } = $props;

#    if ( exists $store->{ $key } ) {
#        push @{ $store->{ $key } }, $props;
#    }
#    else {
#        $store->{ $key } = [ $props ];
#    }
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
