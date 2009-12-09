#!perl 

use strict;

use Test::Deep;
use Scalar::Util qw{ refaddr };

use Chart::Magick::Axis;

use Test::More tests => 90;
BEGIN {
    use_ok( 'Chart::Magick::Axis::Lin', 'Chart::Magick::Axis::Lin can be used' );
}

# These methods are very hard to test...
# optimizeMargins
# calcBaseMargins
# preprocessData

#####################################################################
#
# new
#
#####################################################################
{
    my $axis;
    eval { $axis = Chart::Magick::Axis::Lin->new; };
    ok( !$@, 'new can be called' );
    is( ref $axis, 'Chart::Magick::Axis::Lin', 'new returns an object of correct class' );
    isa_ok( $axis, 'Chart::Magick::Axis', 'new returns an object that inherits from Chart::Magick::Axis' );
}

#####################################################################
#
# definition
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    my $def = $axis->definition;
    is( ref $def, 'HASH', 'definition returns a hash ref' );

    my $superDef    = Chart::Magick::Axis->new->definition;
    my $hasAllKeys  = !scalar(  grep { !exists $def->{$_} } keys %{ $superDef } );
    ok( $hasAllKeys, 'definition includes properties from super class' );

}

#####################################################################
#
# getCoordDimension / getValueDimension
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    cmp_ok( $axis->getCoordDimension, '==', 1, 'getCoordDimension returns 1' );
    cmp_ok( $axis->getValueDimension, '==', 1, 'getValueDimension returns 1' );
}

#####################################################################
#
# getTickLabel
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    $axis->addLabels( {   1 => 'one',     3.5 => 'threeish' }, 0 );
    $axis->addLabels( { -10 => 'notmuch', 100 => 'much'     }, 1 );
    $axis->set(
        xLabelFormat    => undef,
        xLabelUnits     => undef,
        yLabelFormat    => undef,
        yLabelUnits     => undef,
    );

    is( $axis->getTickLabel( 3.5, 0 ), 'threeish', 'getTickLabel returns a text label on the x axis when there is one' );
    is( $axis->getTickLabel( -10, 1 ), 'notmuch',  'getTickLabel returns a text label on the y axis when there is one' );
   
    is( $axis->getTickLabel( 1.23456789, 0 ), '1.23456789', 'getTickLabel handles undef formatting and units on x correctly' );
    is( $axis->getTickLabel( 1.23456789, 1 ), '1.23456789', 'getTickLabel handles undef formatting and units on y correctly' );
    
    $axis->set(
        xLabelFormat    => '%.3f',
        yLabelFormat    => '%.1f',
    );

    is( $axis->getTickLabel( 1.23456789, 0 ), '1.235', 'getTickLabel formats x ticks using xLabelFormat' );
    is( $axis->getTickLabel( 1.23456789, 1 ), '1.2',   'getTickLabel formats y ticks using yLabelFormat' );

    $axis->set(
        xLabelUnits     => 2.5,
        yLabelUnits     => 3,
    );

    is( $axis->getTickLabel( 10, 0 ), '4.000', 'getTickLabel normalizes x ticks to xLabelUnits' );
    is( $axis->getTickLabel( 10, 1 ), '3.3',   'getTickLabel normalizes x tixks to yLabelUnits' );
}

#####################################################################
#
# generateTicks
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    my $ticks = $axis->generateTicks( 1, 10, 1 );
    is( ref $ticks, 'ARRAY', 'generateTicks returns an array ref' );

    cmp_deeply(
        $axis->generateTicks( -0.5, 0.5, 1),
        [ -1, 0, 1 ],
        'generateTicks aligns ticks to zero, adapts limits accordingly and still covers the requested range',
    );
    cmp_deeply(
        $axis->generateTicks( -0.5, 0.5, 0.3 ),
        [ -0.6, -0.3, 0, 0.3, 0.6 ],
        'generateTicks aligns ticks correctly when a non-aligned spacing is passed',
    );
    cmp_deeply(
        $axis->generateTicks( 0.5, 1, 1),
        [ 0, 1 ],
        'generateTicks returns correct ticks for 0.5, 1, 1',
    );
    cmp_deeply(
        $axis->generateTicks( 1, 10, 1),
        [ 1 .. 10 ],
        'generateTicks returns correct ticks for purely positive range',
    );
    cmp_deeply(
        $axis->generateTicks( -10, -1, 1),
        [ -10 .. -1 ],
        'generateTicks returns correct ticks for purely negative range',
    );
}

#####################################################################
#
# generateSubticks
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    my $subs = $axis->generateSubticks;
    is( ref $subs, 'ARRAY', 'generateSubticks returns an array ref when called with no ticks and count' );
    cmp_deeply( $subs, [],  'generateSubticks returns no subticks when called with no ticks and count' );

    $subs = $axis->generateSubticks( [ 0, 1 ] );
    is( ref $subs, 'ARRAY', 'generateSubticks returns an array ref when called with no count' );
    cmp_deeply( $subs, [],  'generateSubticks returns no subticks when called with no count' );

    $subs = $axis->generateSubticks( [ 0, 1 ], 0 );
    is( ref $subs, 'ARRAY', 'generateSubticks returns an array ref when called with zero count' );
    cmp_deeply( $subs, [],  'generateSubticks returns no subticks when called with zero count' );

    $subs = $axis->generateSubticks( [ 0, 1 ], -1 );
    is( ref $subs, 'ARRAY', 'generateSubticks returns an array ref when called with negative count' );
    cmp_deeply( $subs, [],  'generateSubticks returns no subticks when called with negative count' );

    $subs = $axis->generateSubticks( [ 0, 1 ], 1 );
    is( ref $subs, 'ARRAY',      'generateSubticks returns an array ref' );
    cmp_deeply( $subs, [ ],  'generateSubticks returns no subticks when the interval count is one ' );
    
    $subs = $axis->generateSubticks( [ 0, 1 ], 2 );
    is( ref $subs, 'ARRAY',      'generateSubticks returns an array ref' );
    cmp_deeply( $subs, [ 0.5 ],  'generateSubticks returns correct values for single tick interval' );
    
    $subs = $axis->generateSubticks( [ 0, 1, 2, 3 ], 2 );
    is( ref $subs, 'ARRAY',      'generateSubticks returns an array ref' );
    cmp_deeply( $subs, [ 0.5, 1.5, 2.5 ],  'generateSubticks returns correct values for multiple positive tick intervals of equal length' );

    $subs = $axis->generateSubticks( [ -2, 2 ], 2 );
    cmp_deeply( $subs, [ 0 ], 'generateSubticks returns correct values for single zero crossing tick intervals of equal length' );

    $subs = $axis->generateSubticks( [ -2, 0, 2, ], 2 );
    cmp_deeply( $subs, [ -1, 1 ], 'generateSubticks returns correct values for multiple zero crossing tick intervals of equal length' );

    $subs = $axis->generateSubticks( [ -2, -1 ], 2 );
    cmp_deeply( $subs, [ -1.5 ], 'generateSubticks returns correct values for single negative tick intervals of equal length' );

    $subs = $axis->generateSubticks( [ -3, -2, -1 ], 2 );
    cmp_deeply( $subs, [ -2.5, -1.5 ], 'generateSubticks returns correct values for multiple negative tick intervals of equal length' );

    $subs = $axis->generateSubticks( [ 0, 1, 10 ], 2  );
    cmp_deeply( 
        $subs, 
        [ 0.5, 5.5 ], 
        'generateSubticks returns correct values for multiple tick intervals of different length',
    );

}

#####################################################################
#
# getXTicks / getYTicks
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;
    
    cmp_deeply( $axis->getXTicks, [], 'initially no x ticks are set' );

    $axis->set( 'xTicks', [ 0, 1, 2, 3 ] );
    my $xTicks = $axis->getXTicks;
    cmp_deeply( $xTicks, [ 0, 1, 2, 3], 'getXticks returns the contents of the xTicks property' );

    $xTicks->[1] = 200;
    cmp_deeply( $axis->getXTicks, [ 0, 1, 2, 3], 'getXticks returns a safe copy' );

    # y ticks
    cmp_deeply( $axis->getYTicks, [], 'initially no y ticks are set' );

    $axis->set( 'yTicks', [ 5, 6, 7, 8 ] );
    my $yTicks = $axis->getYTicks;
    cmp_deeply( $yTicks, [ 5, 6, 7, 8 ], 'getXticks returns the contents of the yTicks property' );

    $yTicks->[1] = 200;
    cmp_deeply( $axis->getYTicks, [ 5, 6, 7, 8 ], 'getYticks returns a safe copy' );
}

#####################################################################
#
# getXSubticks / getYSubticks
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    $axis->set( 'xTicks', [ 0, 1, 2, 3 ] );
    cmp_deeply( $axis->getXSubticks, [], 'initially no x subticks are set' );

    $axis->set( 'xSubtickCount', 2 );
    cmp_deeply( $axis->getXSubticks, [ 0.5, 1.5, 2.5 ], 'getXSubticks looks at xTicks and xSubtickCount' );
    
    # y subticks
    $axis->set( 'yTicks', [ 5, 6, 7, 8 ] );
    cmp_deeply( $axis->getYSubticks, [], 'initially no y subticks are set' );

    $axis->set( 'ySubtickCount', 2 );
    cmp_deeply( $axis->getYSubticks, [ 5.5, 6.5, 7.5 ], 'getYSubticks looks at yTicks and ySubtickCount' );
}

# calcTickWidth {
#

#####################################################################
#
# getPxPerXUnit / getPxPerYUnit / getChartWidth / getChartHeight
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    foreach ( qw{ xPxPerUnit  yPxPerUnit  chartWidth  chartHeight } ) {
        $axis->plotOption( $_  => "__$_" );
    }
   
    is( $axis->getPxPerXUnit,  '__xPxPerUnit',  'getPxPerXUnit returns the xPxPerUnit plot option' );
    is( $axis->getPxPerYUnit,  '__yPxPerUnit',  'getPxPerYUnit returns the yPxPerUnit plot option' );
    is( $axis->getChartWidth,  '__chartWidth',  'getChartWidth returns the chartWidth plot option' );
    is( $axis->getChartHeight, '__chartHeight', 'getChartHeight returns the chartHeight plot option' );
}

#####################################################################
#
# plotAxes
#
#####################################################################
{
    no warnings 'redefine';
    
    my $axis = Chart::Magick::Axis::Lin->new;

    my ($class, %args);
    local *Image::Magick::Draw = sub { $class = shift; %args = @_ };

    $axis->addChart( DummyChart->new );
    $axis->set( 'axisColor', '#123456' );
    $axis->preprocessData;
    $axis->plotAxes;

    is( $class, $axis->im, 'plotAxes draw onto the im of the axis object' );
    is( $args{ stroke }, '#123456', 'plotAxes uses the stroke color set by axisColor' );
    is( $args{ fill   }, 'none',    'plotAxes uses no fill color' );

    # TODO: Figure out how to test the path correctly
}

#####################################################################
#
# plotAxisTitles
#
#####################################################################
{
    no warnings 'redefine';

    my @invocations;
    local *Chart::Magick::Axis::text = sub { push @invocations, { class => shift, args => { @_ } } };

    my $axis = Chart::Magick::Axis::Lin->new;
    foreach ( qw{ Title TitleFontSize TitleColor TitleFont } ) {
        $axis->set( 
            "x$_"   => "__x$_",
            "y$_"   => "__y$_",
        );
    }
    $axis->set( 'axisColor', '#123456' );
    $axis->addChart( DummyChart->new );
    $axis->preprocessData;
    $axis->plotAxisTitles;

    cmp_ok( scalar @invocations, '==', 2, 'plotAxisTitles calls text twice.' );

    for my $index ( 0, 1 ) {
        my $class = $invocations[ $index ]->{ class };
        my %args  = %{ $invocations[ $index ]->{ args } };

        my $name    = $index ? 'y' : 'x';
        my $font    = $name.'TitleFont';
        my $color   = $name.'TitleColor';
        my $size    = $name.'TitleFontSize';
        my $text    = $name.'Title';

        is( $args{ text      }, $axis->get( $text ),  "plotAxisTitles plots the correct title for the $name axis" );
        is( $args{ fill      }, $axis->get( $color ), "plotAxisTitles uses the fill color set by $color" );
        is( $args{ font      }, $axis->get( $font  ), "plotAxisTitles uses the font set by $font" );
        is( $args{ pointsize }, $axis->get( $size ),  "plotAxisTitles uses the fontsize set by $size" );
        is( $args{ halign    }, 'center',             "plotAxisTitles uses the correct halign for the $name axis" );
        is( 
            $args{ valign    }, 
            $name eq 'x' ? 'bottom' : 'top', 
            "plotAxisTitles uses the correct valign for the $name axis",
        );
        cmp_ok( 
            $args{ rotate }, '==', $name eq 'x' ? 0 : -90,
            "plotAxisTitles uses the correct rotation for the $name axis",
        );       
    }

    # TODO: Test the coords.
}

#####################################################################
#
# plotBox
#
#####################################################################
{
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::Lin->new;
    $axis->set( 'boxColor', '#123456' );

    my ($class, %args);
    local *Image::Magick::Draw = sub { $class = shift; %args = @_ };

    $axis->addChart( DummyChart->new );
    $axis->preprocessData;
    $axis->plotBox;

    is( $class, $axis->im, 'plotBox draws onto the im of the axis object' );
    is( $args{ stroke }, '#123456', 'plotAxes uses the stroke color set by axisColor' );
    is( $args{ fill   }, 'none',    'plotAxes uses no fill color' );

    # TODO: Figure out how to test the path correctly
}

# plotRulers {

#####################################################################
#
# plotTicks {
#
#####################################################################
{
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::Lin->new;
    my $chart = DummyChart->new( dataRange => [ [ 0 ], [ 2 ], [ 5 ], [ 7 ] ] );
    $axis->addChart( $chart );

    my ( @text, @draw );
    local *Chart::Magick::Axis::text = sub { shift; push @text, { @_ } };
    local *Image::Magick::Draw       = sub { shift; push @draw, { @_ } };

    my %expectText = (
        font        => '__labelFont',
        halign      => 'center',
        valign      => 'top',
        align       => 'Center',
        pointsize   => '__labelFontSize',
        style       => 'Normal',
        fill        => '__labelColor',
        x           => ignore(),
        y           => ignore(),
        wrapWidth   => ignore(),
    );
    my %expectDraw = (
        primitive   => ignore(),
        stroke      => '__xTickColor',
        points      => ignore(),
        fill        => 'none',
    );

    $axis->preprocessData;
    $axis->set( 
        xTicks  => [],
        yTicks  => [],
        xSubtickCount   => 0,
        ySubtickCount   => 0,
        labelFont       => '__labelFont',
        labelFontSize   => '__labelFontSize',
        labelColor      => '__labelColor',
        xTickColor      => '__xTickColor',
        yTickColor      => '__yTickColor',
        xSubtickColor   => '__xSubtickColor',
        ySubtickColor   => '__ySubtickColor',
    );

    $axis->plotTicks;
    cmp_ok( scalar @text, '==', 0, 'plotTicks does not draw labels when there are no ticks' );
    cmp_ok( scalar @draw, '==', 0, 'plotTicks does not draw ticks when there are none' );

    # x
    @text = @draw = ();
    $axis->set( xTicks => [ 0, 1, 2 ] );
    $axis->plotTicks;
    cmp_deeply(
        \@draw,
        [ map { { %expectDraw } } (0, 1, 2) ],
        'plotTicks draws ticks for each x tick in the right color', 
    );
    cmp_deeply(
        \@text,
        [ map { superhashof( { %expectText, text => $axis->getTickLabel( $_, 0) } )  } ( 0, 1, 2) ],
        'plotTicks draws labels with correct value and layout for each x tick'
    );
    @draw = @text = ();
    $axis->set( xSubtickCount => 3 );
    $axis->plotTicks;
    $expectDraw{ stroke } = '__xSubtickColor';
    cmp_deeply(
        [ grep { $_->{ stroke } eq '__xSubtickColor' } @draw ],
        [ map { { %expectDraw } } ( 1 .. 4 ) ],
        'plotTicks draws the correct number of x axis sub ticks in the correct color',
    );

    # y 
    @text = @draw = ();
    $axis->set( xTicks => [], yTicks => [ 5, 6, 7 ], xSubtickCount => 0 );
    $axis->plotTicks;
    $expectDraw{ stroke } = '__yTickColor';
    cmp_deeply(
        \@draw,
        [ map { { %expectDraw } } (5, 6, 7) ],
        'plotTicks draws ticks for each x tick in the right color', 
    );

    @draw = @text = ();
    $expectDraw{ stroke } = '__ySubtickColor';
    $axis->set( ySubtickCount => 4 );
    $axis->plotTicks;
    cmp_deeply(
        [ grep { $_->{ stroke } eq '__ySubtickColor' } @draw ],
        [ map { { %expectDraw } } ( 1 .. 6 ) ],
        'plotTicks draws the correct number of sub ticks in the correct color',
    );
        
    $expectText{ valign } = 'center';
    $expectText{ halign } = 'right';
    $expectText{ align  } = 'Right';
    cmp_deeply(
        \@text,
        [ map { { %expectText, text => $axis->getTickLabel( $_, 1) }  } ( 5, 6, 7) ],
        'plotTicks draws labels with correct value and layout for each x tick'
    );

    
    #TODO: Test subticks!
}

#####################################################################
#
# plotFirst / plotLast
#
#####################################################################
{
    no strict 'refs';
    no warnings 'redefine';

    my $axis = Chart::Magick::Axis::Lin->new;

    # Make these plot methods report their call order, rather than actually plotting anything. Cannot use local
    # here since the for forms it's own block. So, store the original sub ref so we can put it back when finished
    # testing.
    my ( %original, @callOrder );
    for my $method ( qw{ plotRulers plotAxes plotTicks plotBox plotAxisTitles } ) {
        $original{ $method } = *{ "Chart::Magick::Axis::Lin::$method" }{ CODE };

        *{ "Chart::Magick::Axis::Lin::$method" } = sub { push @callOrder, $method };
    }

    $axis->addChart( DummyChart->new );
    $axis->preprocessData;
    $axis->set( plotBox => 0, plotAxes => 0 );
    $axis->plotFirst;
    cmp_deeply(
        \@callOrder,
        [ qw{ plotRulers plotTicks } ],
        'plotFirst calls the right methods in the correct order',
    );
    
    @callOrder = ();
    $axis->set( plotBox => 1 );
    $axis->plotFirst;
    cmp_deeply(
        \@callOrder,
        [ qw{ plotRulers plotTicks plotBox } ],
        'plotFirst takes into account the plotBox property',
    );

    @callOrder = ();
    $axis->set( plotAxes => 1 );
    $axis->plotFirst;
    cmp_deeply(
        \@callOrder,
        [ qw{ plotRulers plotAxes plotTicks plotBox } ],
        'plotFirst calls the right methods in the correct order',
    );
    
    @callOrder = ();
    $axis->plotLast;
    cmp_deeply(
        \@callOrder,
        [ qw{ plotAxisTitles } ],
        'plotFirst calls the right methods in the correct order',
    );

    # restore behaviour of overriden methods.
    for my $method ( qw{ plotRulers plotAxes plotTicks plotBox plotAxisTitles } ) {
        *{ "Chart::Magick::Axis::Lin::$method" } = $original{ $method };
    }
}

# getLabelDimensions {

#####################################################################
#
# transformX / transformY
#
#####################################################################
{
    my $axis = Chart::Magick::Axis::Lin->new;

    my $xOk = 1;
    my $yOk = 1;

    for ( -100 .. 100 ) {
        $xOk = 0 if $axis->transformX( $_ ) != $_;
        $yOk = 0 if $axis->transformY( $_ ) != $_;
    }

    ok( $xOk, 'transformX transforms correctly' );
    ok( $yOk, 'transformY transforms correctly' );
}


# toPxX {
# toPxY {
# project {

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

sub new { 
    my $class   = shift; 
    my %prop    = @_;
    my $self    = $class->SUPER::new;

    $self->{ _dataRange } = $prop{ dataRange } || [ [0], [1], [0], [1] ];
    return $self;
}

sub plot { };

1;




