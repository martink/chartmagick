package Chart::Magick::Definition;

use strict;
use warnings;

use Carp;
use Class::InsideOut qw{ :std };

private properties => my %properties;

#--------------------------------------------------------------------

=head2 get ( [ property ] )

Returns a hash ref of all properties in the Axis object. If a specific property is passed only the value belong to
that property is returned.

=head3 property

The property whose value should be returned.

=cut 

sub get {
    my $self        = shift;
    my $key         = shift;
    my $properties  = $properties{ id $self };

    if ($key) {
        #### TODO: handle error and don't croak?
        croak "invalid key: [$key]" unless exists $properties->{ $key };

        return 
            ref $properties->{ $key } eq 'CODE'
                ? $properties->{ $key }->( $self )
                : $properties->{ $key }
                ;
    }
    else {
        # We have to process the code refs, so we cannot just return a copy of the properties hash ref.
        return { map { $_ => $self->get( $_ ) } keys %{ $properties } };
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

