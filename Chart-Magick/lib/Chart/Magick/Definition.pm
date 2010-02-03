package Chart::Magick::Definition;

use strict;
use warnings;

use Carp;
use Class::InsideOut qw{ :std };

private properties => my %properties;

#--------------------------------------------------------------------

=head2 get ( [ property ] )

Returns a hash ref of all properties in the Axis object. If a specific property is passed only the value belong to
that property is returned. If the value of a property is a coderef, it will be executed and the result will be
returned.

=head3 property

The property whose value should be returned.

=cut 

sub get {
    my $self        = shift;
    my $key         = shift;

    if ($key) {
        my $value   = $self->getRaw( $key );
        return 
            ref $value eq 'CODE'
                ? $value->( $self )
                : $value
                ;
    }
    else {
        # We have to process the code refs, so we cannot just return a copy of the properties hash ref.
        return { map { $_ => $self->get( $_ ) } keys %{ $self->getRaw } };
    }
}

#--------------------------------------------------------------------

=head2 getRaw ( key )

Return the raw value for the given property. This means that code ref are not automatically executed. In most cases
you'd want to use the get method. A notable exception is when storing the state temporarily with the intention of
restoring it again via C<set>.

=head3 key

The name of the property. If not given, a hashref containg all properties and their value will be returned.

=cut

sub getRaw {
    my $self        = shift;
    my $key         = shift;
    my $properties  = $properties{ id $self };

    if ($key) {
        croak "invalid key: [$key]" unless exists $properties->{ $key };
        return $properties->{ $key }
    }
    else {
        return { %{ $properties } };
    }
}

#--------------------------------------------------------------------

=head2 initializeProperties ( overrides )

=cut

sub initializeProperties {
    my $self        = shift;
    my @overrides   = @_;

    croak "$self has no definition method, which is required" unless $self->can( 'definition' );

    $properties{ id $self }  = $self->definition;
    $self->set( @overrides ) if @overrides;

    return;
}

#--------------------------------------------------------------------

=head2 set ( properties )

Applies the passed properties to this object.

head3 properties

Either a hash or a hash ref containing the property names as keys and intended values as values.

=cut

sub set {
    my $self    = shift;
    my %update  = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    my $properties  = $properties{ id $self };

    while ( my ($key, $value) = each %update ) {
        croak "Cannot set non-existing property [$key]" unless exists $properties->{ $key };

        $properties->{ $key } = $value;
    }

    return;
}

1;

