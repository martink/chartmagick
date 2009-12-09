package Chart::Magick::Palette;

use strict;
use warnings;

use Chart::Magick::Color;
use Class::InsideOut qw{ :std };
use Carp;

private     colors          => my %colors;
public      paletteIndex    => my %paletteIndex;

#-------------------------------------------------------------------

=head2 addColor ( color )

Adds a color to the end of the palette.

=head3 color

The Chart::Magick::Color object that should be added.

=cut

sub addColor {
	my $self    = shift;
	my $color   = shift;
	
	push @{ $colors{ id $self } }, $color;

    return;
}

#-------------------------------------------------------------------

=head2 getColor ( [ index ] )

Returns the color at the specified index in the palette.

=head3 index

The index of the color. Defaults to the current palette index.

=cut

sub getColor {
	my $self    = shift;
	my $index   = shift || $self->getPaletteIndex;

	return $colors{ id $self }->[ $index ];
}

#-------------------------------------------------------------------

=head2 getColorIndex ( color )

Returns the index of color. If the color is not in the palette it will return
undef.

=head3 color

A Chart::Magick::Color object.

=cut


#### TODO: Do we need this anyway?
sub getColorIndex {
	my $self    = shift;
	my $color   = shift;
	
	my @palette = @{ $self->getColorsInPalette };
	
    #### TODO: Possibly 
	for my $index (0 .. scalar( @palette ) - 1) {
		return $index if ( $self->getColor( $index ) eq $color );
	}

	return;
}

#-------------------------------------------------------------------

=head2 getColorsInPalette ( )

Returns a arrayref containing all color objects in the palette.

=cut

sub getColorsInPalette {
	my $self = shift;

	# Copy ref so people cannot overwrite 
	return [ @{ $colors{ id $self } } ];
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

=head2 getNumberOfColors ( )

Returns the number of colors in the palette.

=cut

sub getNumberOfColors {
	my $self = shift;

	return scalar @{ $colors{ id $self } };
}

#-------------------------------------------------------------------

=head2 getPaletteIndex ( )

Returns the index the internal palette index counter is set to. Ie. it returns
the current color index.

=cut

sub getPaletteIndex {
	my $self        = shift;
    my $canBeUndef  = shift;

    my $index       = $paletteIndex{ id $self };
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

=head2 new ( )

Constructor for this class. 

=cut

sub new {
	my $class   = shift;
    my $colors  = shift || [];
    
    my $self    = {};
    bless $self, $class;

    register( $self );

    $colors{ id $self }         = [
        map { ref $_ eq 'HASH' ? Chart::Magick::Color->new( $_ ) : $_ } @{ $colors }
    ];
    $paletteIndex{ id $self }   = undef;

    return $self;
}

#-------------------------------------------------------------------

=head2 removeColor ( index )

Removes color at index.

=head3 index

The index of the color you want to remove. If not given nothing will happen.

=cut

sub removeColor {
	my $self    = shift;
	my $index   = shift;

    # Check index
	return if !defined $index || $index < 0 || $index >= $self->getNumberOfColors;
	
    # Remove color from array
	splice @{ $colors{ id $self } }, $index, 1;

    # Adjust palette index if necessary.
    if ( $self->getNumberOfColors <= $self->getPaletteIndex ) {
        $self->setPaletteIndex( $self->getNumberOfColors - 1 );
    }

    return;
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

	$colors{ id $self }->[ $index ] = $color;

    return;
}

#### TODO: Sanitiy checks
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
	
    $paletteIndex{ id $self } = $index;

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

