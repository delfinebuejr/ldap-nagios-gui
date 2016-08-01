package User;

use strict;
use warnings;

use Data::Dumper;
use Carp qw(carp croak);

my @everyone = ();

sub new {
    my ( $class, $arg_for ) = @_; 
    my $self = bless {} , $class;
    $self->_init( $arg_for );
    return $self;  
}

sub _init {
    my ( $self, $arg_for ) = @_;
    
    my %hash = %$arg_for;
    
    my $fname = delete $hash{fname};
    my $lname = delete $hash{lname};
    my $email = delete $hash{email};

#    unless (defined $fname){croak("member fname is not defined")};
#    unless (defined $lname){croak("member lname is not defined")};
#    unless (defined $email){croak("member email is not defined")};

    if ( my $remaining = join "," , keys %hash ) {
        croak("unknown members $self\::new: $remaining");
    }

    $self->set_fname($fname);
    $self->set_lname($lname);
    $self->set_email($email);

    push @everyone, $self;

}

## SETTER

sub set_fname {
    my ( $self, $fname ) = @_;
    $self->{attribute}{fname} = $fname;
}

sub set_lname {
    my ( $self, $lname ) = @_;
    $self->{attribute}{lname} = $lname;
}

sub set_email {
    my ( $self, $email ) = @_;
    $self->{attribute}{email} = $email;
}

## GETTER

sub get_fullName {
    my ( $self ) = shift;
    return $self->{attribute}{fname} . " " . $self->{attribute}{lname};
}

sub get_fname {
    my ( $self ) = @_;
    return $self->{attribute}{fname};
}

sub get_lname {
    my ( $self ) = @_;
    return $self->{attribute}{lname};
}

sub get_email {
    my ( $self ) = @_;
    return $self->{attribute}{email};
}

sub get_everyone {
    return @everyone;
}

sub get_count {
   return scalar @everyone;

}

1;
