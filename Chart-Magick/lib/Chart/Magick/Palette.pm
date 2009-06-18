package Chart::Magick::Palette;

use strict;
use Chart::Magick::Color;
use Class::InsideOut qw{ :std };

private     colors          => my %colors;
public      paletteIndex    => my %paletteIndex;

#-------------------------------------------------------------------
sub addColor {
	my $self    = shift;
	my $color   = shift;
	
	push @{ $colors{ id $self } }, $color;
}

#-------------------------------------------------------------------
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
		return $index if ( $self->getColor( $index )->getId eq $color->getId );
	}

	return undef;
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

	my $index   = $self->getPaletteIndex + 1;
	$index      = 0 if ( $index >= $self->getNumberOfColors );

	$self->setPaletteIndex( $index );
    
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

##-------------------------------------------------------------------
#
#=head2 getPaletteIndex ( )
#
#Returns the index the internal palette index counter is set to. Ie. it returns
#the current color.
#
#=cut
#
sub getPaletteIndex {
	my $self = shift;

	return $paletteIndex{ id $self } || 0;
}

#-------------------------------------------------------------------


=head2 getPreviousColor ( )

Returns the previous color in the palette relative to the internal palette index
counter, and decreases this counter to that color. If the counter already is at
the first color in the palette it will cycle around to the last color in the
palette.

=cut

sub previousColor {
	my $self = shift;

	my $index = $self->getPaletteIndex - 1;
	$index = $self->getNumberOfColors - 1 if ($index < 0);

	$self->setPaletteIndex( $index );
	return $self->getColor($index);
}

#-------------------------------------------------------------------

=head2 new ( )

Constructor for this class. 

=cut

sub new {
	my $class   = shift;
    
    my $self    = {};
    bless $self, $class;

    register( $self );

    $colors{ id $self }         = [ ];
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

	return undef unless defined $index;
	
	splice @{ $colors{ id $self } }, $index, 1;

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
	my $index = shift;
	my $color = shift;

    # Make sure the index is within bounds
	return undef if $index >= $self->getNumberOfColors;
	return undef if $index < 0;
	return undef unless defined $index;
	return undef unless defined $color;

	$colors{ id $self }->[ $index ] = $color;
}

#### TODO: Sanitiy checks
#-------------------------------------------------------------------

sub setPaletteIndex {
    my $self = shift;
    my $index = shift;
	
    return undef unless (defined $index);
	
    $index = ($self->getNumberOfColors - 1) if ($index >= $self->getNumberOfColors);
    $index = 0 if ($index < 0);
	
    $paletteIndex{ id $self } = $index;
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

	$self->setColor($indexA, $colorB);
	$self->setColor($indexB, $colorA);
}

1;

