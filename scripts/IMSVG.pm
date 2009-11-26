use strict;
use Scalar::Util qw{ refaddr };
use Data::Dumper;
use Image::Magick;

my %blah;

my $orig = *Image::Magick::Draw{ CODE };
*Image::Magick::Draw = sub {
    my $self = shift;
    $blah{ refaddr $self } = [] unless exists $blah{ refaddr $self };

    push @{ $blah{ refaddr $self } }, { @_ };
    return $self->$orig( @_ );
};

*Image::Magick::Composite = sub {
    my $self = shift;

    $blah{ refaddr $self } = [] unless exists $blah{ refaddr $self };
    
    my %args = @_;
    $args{im} = refaddr $args{im};
    push @{ $blah{ refaddr $self } }, { %args };
};

*Image::Magick::DumpStack = sub {
    print Dumper \%blah;
};

