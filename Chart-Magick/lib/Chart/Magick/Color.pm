package Chart::Magick::Color;

use strict;
use warnings;
use Moose;

#use Color::Calc;

sub _checkTriplet {
    my $triplet = shift;

    return '000000' unless defined $triplet;

    if ( $triplet =~ m{ ^[#]? ([0-9a-f]+) $ }xgi ) {
        return lc $1;
    }
        
    return '000000';
}

sub _checkAlpha {
    my $alpha = shift;

    return 'ff' unless defined $alpha;

    if ( $alpha =~ m{ ^ [0-9a-f]{1,2} $ }xgi ) {
        return lc $alpha;
    }

    return 'ff';
}

# TODO: Create subtypes for these attributes.
has strokeTriplet => (
    is      => 'rw',
    default => '000000',
);
has strokeAlpha => (
    is      => 'rw',
    default => 'ff',
);
has fillTriplet => (
    is      => 'rw',
    default => '000000',
);
has fillAlpha   => (
    is      => 'rw',
    default => 'ff',
);

=head1 NAME

Package Chart::Magick::Color

=head1 DESCRIPTION

Package for managing WebGUI colors.

=head1 SYNOPSIS

Colors actually consist of two colors: fill color and stroke color. Stroke color
is the color for lines and the border of areas, while the fill color is the
color that is used to fill that area. Fill color thus have no effect on lines.

Each fill and stroke color consists of a Red, Green, Blue and Alpha component.
These values are given in hexadecimal notation. A concatenation of the Red,
Greean and Blue values, prepended with a '#' sign is called a triplet. A similar
combination that also includes the Alpha values at the end is called a quartet.

Alpha value are used to define the transparency of the color. The higher the
value the more transparent the color is. If the alpha value = 00 the color is
opaque, where the color is completely invisible for an alpha value of ff.

Colors are not saved to the database by default. If you want to do this you must
do so manually using the save and/or update methods.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 copy ( )

Returns a new Chart::Magick::Color object being an exact copy of this color.
the database. To accomplish that use the save method on the copy.

=cut

sub copy {
	my $self = shift;

	return Chart::Magick::Color->new({
        fillTriplet     => $self->fillTriplet,
        fillAlpha       => $self->fillAlpha,
        strokeTriplet   => $self->strokeTriplet,
        strokeAlpha     => $self->strokeAlpha,
    } );
}

#-------------------------------------------------------------------

=head2 darken ( )

Returns a new Chart::Magick::Color object with the same properties but the
colors darkened. 

=cut

sub darken {
	my $self = shift;
	
	my $newColor = $self->copy;

    # TODO: Make this work again.
#	my $c = Color::Calc->new(OutputFormat => 'hex');
#	
#	$newColor->fillTriplet(   $c->dark( $self->fillTriplet )    );
#	$newColor->strokeTriplet( $c->dark( $self->strokeTriplet )  );

	return $newColor;
}

#-------------------------------------------------------------------

=head2 getFillColor ( )

Returns the the quartet of th fill color. The quartet consists of R, G, B and
Alpha values respectively in HTML format: '#rrggbbaa'.

=cut

sub getFillColor {
	my $self = shift;
	
	return '#' . $self->fillTriplet . $self->fillAlpha;
}

#-------------------------------------------------------------------

=head2 getStrokeColor ( a )

Returns the the quartet of the stroke color. The quartet consists of R, G, B and
Alpha values respectively in HTML format: '#rrggbbaa'.

=cut

sub getStrokeColor {
	my $self = shift;
	
	return '#' . $self->strokeTriplet . $self->strokeAlpha;
}

1;

