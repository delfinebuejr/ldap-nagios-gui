package NagiosContact;

use strict;
use warnings;

use User;

our @ISA = qw(User);

my @nagioscontacts;

sub _init {                              # override parent class's "_init" method to exted the functionality
    my ( $self, $arg_for ) = @_;

    my %hash = %$arg_for;

    my $contactType = delete $hash{contactType};
    my $contactGroup = delete $hash{contactGroup};
    my $uid = delete $hash{uid};
    my $cn = delete $hash{cn};

    unless (defined $contactType) { croak("member contactType not found"); }
    unless (defined $contactGroup) { croak("member contactGroup not found"); }

    $self->set_contactGroup($contactGroup);
    $self->set_contactType($contactType);
    $self->set_uid($uid);
    $self->set_cn($cn);


    $self->SUPER::_init(\%hash);    # call "_init" method from parent class then pass the remaining members in the hash
                                          # for processing

    push @nagioscontacts, $self;

}

sub set_cn {
    my ( $self, $cn ) = @_;
    $self->{attribute}{cn} = $cn;
}

sub set_uid {
    my ( $self, $uid ) = @_;
    $self->{attribute}{uid} = $uid;
}

sub set_contactGroup {
    my ( $self, $contactGroup ) = @_;
    $self->{attribute}{contactGroup} = $contactGroup;
}

sub set_contactType {
    my ( $self, $contactType ) = @_;
    $self->{attribute}{contactType} = $contactType;
}

sub nagioscontact_count {
    return scalar @nagioscontacts;
}

sub get_nagioscontacts {
    return @nagioscontacts;
}

sub get_contactGroup {
    my ($self) = shift;
    return $self->{attribute}{contactGroup};
}

sub get_contactType {
    my ($self) = shift;
    return $self->{attribute}{contactType};
}

sub get_cn {
    my $self = shift;
    return $self->{attribute}{cn};
}

sub get_uid {
   my $self = shift;
   return $self->{attribute}{uid};
}

sub create_nagiosContact {
    my ($self) = shift;

    my $uid = $self->get_uid;
    my $cn  = $self->get_cn;
    my $contactType = $self->get_contactType;
    my $contactGroups = $self->get_contactGroup;
    my $email         = $self->get_email;

my $contact = << "END_MESSAGE";

define contact{
    contact_name       $uid
    use                $contactType
    alias              $cn
    contactgroups      $contactGroups
    email              $email
}

END_MESSAGE
    return $contact;
}

1;
