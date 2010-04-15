package Chart::Magick::Palette;

use strict;
use warnings;
use Moose;

use Chart::Magick::Color;
use Carp;

has colors => (
    is      => 'rw',
    isa     => 'ArrayRef[Chart::Magick::Color]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        getColors           => 'elements',
        addColor            => 'push',
        getNumberOfColors   => 'count',
        removeColor         => 'delete',
#        setColor            => 'set',
    },
);

has paletteIndex => (
    is      => 'rw',
    default => undef,
);

#-------------------------------------------------------------------
around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;
    my @params  = @_;

    if ( @params == 1 && ref $params[0] eq 'ARRAY' ) {
        my @colors = 
            map     { ref $_ eq 'HASH' ? Chart::Magick::Color->new( $_ ) : $_ }
                    @{ $params[0] }
            ;

        return $class->$orig( { colors => \@colors } );
    }
    
    return $class->$orig( @_ );
};

#-------------------------------------------------------------------

=head2 getColor ( [ index ] )

Returns the color at the specified index in the palette.

=head3 index

The index of the color. Defaults to the current palette index.

=cut

sub getColor {
	my $self    = shift;
	my $index   = shift || $self->getPaletteIndex;

	return ( $self->getColors )[ $index ];
}

#-------------------------------------------------------------------

=head2 getNextColor ( )

Returns the next color in the palette relative to the internal palette index
counter, and increases this counter to that color. If the counter already is at
the last color in the palette it will cycle around to the first color in the
palette.

=cut

sub getNextColor {
	my $self = shift;

	my $index   = $self->getPaletteIndex( 1 );
    $index      = -1 if !defined $index || $index >= $self->getNumberOfColors - 1;

	$self->setPaletteIndex( $index + 1);
    
	return $self->getColor;
}

#-------------------------------------------------------------------

=head2 getPaletteIndex ( )

Returns the index the internal palette index counter is set to. Ie. it returns
the current color index.

=cut

sub getPaletteIndex {
	my $self        = shift;
    my $canBeUndef  = shift;

    my $index       = $self->paletteIndex;
    $index          = 0 unless defined $index || $canBeUndef;

    return $index;
}

#-------------------------------------------------------------------

=head2 getPreviousColor ( )

Returns the previous color in the palette relative to the internal palette index
counter, and decreases this counter to that color. If the counter already is at
the first color in the palette it will cycle around to the last color in the
palette.

=cut

sub getPreviousColor {
	my $self = shift;
    
    my $colorCount = $self->getNumberOfColors;

	my $index   = $self->getPaletteIndex( 1 );
    $index      = $colorCount if !defined $index || $index <= 0;

	$self->setPaletteIndex( $index - 1);

	return $self->getColor;
}

#-------------------------------------------------------------------

=head2 setColor ( index, color )

Sets palette position index to color. This method will automatically save or
update the color. Index must be within the current palette. To add additional
colors use the addColor method.

=head3 index

The index within the palette where you want to put the color.

=head3 color

The Chart::Magick::Color object.

=cut

sub setColor {
	my $self = shift;
	my $color = shift;
	my $index = shift;

    # Make sure the index is within bounds
	return if $index >= $self->getNumberOfColors;
	return if $index < 0;
	return unless defined $index;
	return unless defined $color;

    $self->colors->[ $index ] = $color;

    return;
}

#-------------------------------------------------------------------

=head2 setPaletteIndex ( index )

Set the current palette index to the given value. If an index too low or too heigh is passed the index will be set
to the first or the last color respectively.

=cut

sub setPaletteIndex {
    my $self = shift;
    my $index = shift;
	
    return unless (defined $index);
	
    $index = ($self->getNumberOfColors - 1) if ($index >= $self->getNumberOfColors);
    $index = 0 if ($index < 0);
	
    $self->paletteIndex( $index );

    return;
}

#-------------------------------------------------------------------

=head2 swapColors ( firstIndex, secondIndex )

Swaps the position of two colors within the palette.

=head3 firstIndex

The index of one of the colors to swap.

=head3 secondIndex

The index of the other color to swap.

=cut

sub swapColors {
	my $self = shift;
	my $indexA = shift;
	my $indexB = shift;

	my $colorA = $self->getColor( $indexA );
	my $colorB = $self->getColor( $indexB );

	$self->setColor($colorB, $indexA );
	$self->setColor($colorA, $indexB );

    return;
}

1;

