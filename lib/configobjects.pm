package configobjects;

use strict;
use warnings;

use Carp qw(carp croak);

#my @allobjects;

sub new {
    my ( $class, $arg_for) = @_;

    my $self = bless {}, $class;
    $self->_init($arg_for);
    return $self;
}

sub _init {
    my ( $self, $arg_for ) = @_;

    my %hash = %$arg_for;

    my $type = delete $hash{type}; 

    unless (defined $type) {croak("undefined member - type");}
 
    $self->set_type($type);
    
#    push @allobjects, $self;
}

sub set_type {
    my ( $self, $type) = @_;
    $self->{attribute}{type} = $type;
}

sub set_data {                                   ## create a member dynamically
    my ( $self, $name, $value ) = @_;
    $self->{attribute}{$name} = $value;
}

sub get_type {
    my ($self) = shift;
    return $self->{attribute}{type};
}

sub get_data {
    my ($self, $name) = shift;
    return $self->{attribute}{$name};
}

#sub get_allobjects {
#    return @allobjects;
#}

1;
