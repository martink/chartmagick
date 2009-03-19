package Chart::Magick::Color;

use strict;
use Color::Calc;
use Class::InsideOut qw{ :std };

public  strokeTriplet   => my %strokeTriplet;
public  strokeAlpha     => my %strokeAlpha;
public  fillTriplet     => my %fillTriplet;
public  fillAlpha       => my %fillAlpha;


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
combination that also includes the Alpha values at the end is called a quarted.

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

Returns a new Chart::Magick::Color object being an exact copy of this color,
except for the persistency. This means that the new copy will not be stored in
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
colors darkened. This object will not be saved to the database automatically.
Use the save method on it if you want to do so.

=cut

sub darken {
	my $self = shift;
	
	my $newColor = $self->copy;

	my $c = Color::Calc->new(OutputFormat => 'hex');
	
	$newColor->fillTriplet('#'.$c->dark($self->fillTriplet));
	$newColor->strokeTriplet('#'.$c->dark($self->strokeTriplet));

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

=head2 getStrokeColor ( )

Returns the the quartet of the stroke color. The quartet consists of R, G, B and
Alpha values respectively in HTML format: '#rrggbbaa'.

=cut

sub getStrokeColor {
	my $self = shift;
	
	return '#' . $self->strokeTriplet . $self->strokeAlpha;
}

#-------------------------------------------------------------------
=head2 new ( [ properties ] )

Constructor for this class.

=head3 properties

A hashref containing configuration options to set this object to. All are also
available through methods.

=head4 fillTriplet

The RGB triplet for the fill color. See setFillTriplet.

=head4 fillAlpha

The alpha value for the fill color. See setFillAlpha.

=head4 strokeTriplet

The RGB triplet for the stroke color. See setStrokeTriplet.

=head4 strokeAlpha

The alpha value for the stroke color. See setStrokeAlpha.

=cut

sub new {
	my $class       = shift;
	my $properties  = shift || {};
    my $self        = {};

    bless    $self, $class;
    register $self;

    my $id = id $self;

#	$fillTriplet{ $id }     => $properties->{ fillTriplet   } || '#000000';
#	$fillAlpha{ $id }       => $properties->{ fillAlpha     } || '00';
#	$strokeTriplet{ $id }   => $properties->{ strokeTriplet } || '#000000';
#	$strokeAlpha{ $id }     => $properties->{ strokeAlpha   } || '00';

	$self->fillTriplet(   $properties->{ fillTriplet   } || '000000'  );
	$self->fillAlpha(     $properties->{ fillAlpha     } || '00'       );
	$self->strokeTriplet( $properties->{ strokeTriplet } || '000000'  );
	$self->strokeAlpha(   $properties->{ strokeAlpha   } || '00'       );
		
    return $self;
}

#sub setFillColor {
#	my $self = shift;
#	my $color = shift;
#
#	if ($color =~ m/^(#[\da-f]{6})([\da-f]{2})?$/i) {
#		$self->setFillTriplet($1);
#		$self->setFillAlpha($2 || '00');
#	} else {
#		$self->session->errorHandler->fatal("Invalid fill color: ($color)");
#	}
#}

1;

