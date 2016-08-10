package LDAPuser;

use strict;
use warnings;

use Data::Dumper;
use Carp qw(carp croak);
use Net::LDAP;
use User;

our @ISA = qw(User);

my @ldapusers = ();

sub _init {                           
    my ( $self ) = shift; 

    push @ldapusers, $self;             # collect all created objects

}

sub set_cn {
    my ( $self, $cn ) = @_;    
    $self->{attribute}{cn} = $cn;
}

sub set_uid {
    my ($self, $uid) = @_;
    $self->{attribute}{uid} = $uid;
}

sub set_dn {
    my ( $self, $dn ) = @_;
    $self->{attribute}{dn} = $dn
}

sub set_groupMembership {
    my ( $self, $groups) = @_;
    return $self->{attribute}{groupMembership} = $groups;
}

sub get_cn {
    my ( $self ) = shift;
    return $self->{attribute}{cn};
}

sub get_uid {
    my ( $self ) = shift;
    return $self->{attribute}{uid};
}

sub get_dn {
    my ( $self ) = shift;
    return $self->{attribute}{dn};
}

sub get_ldapusers {
    return @ldapusers;
}

sub get_count {
    return scalar @ldapusers;
}

sub get_groupMembership {
    my ( $self ) = shift;
    return $self->{attribute}{groupMembership};
}


sub search_user {
    my ( $self, $targetUser, $connstring, $ldapUserBase, $ldapGroupBase ) = @_;  

    my ( $server, $user, $password ) = split "," , $connstring;

    my $required_usr_attrs = [ 'givenName', 'sn', 'cn' ,'uid', 'mail' ];
    my $required_grp_attrs = ['cn'];

    $server =~ s/^\s+|\s+$//g;
    $user =~ s/^\s+|\s+$//g;
    $password =~ s/^\s+|\s+$//g;

    my $ldap = Net::LDAP->new($server) or die "unable to connect $@";
    $ldap->bind ( $user, password => $password ) or die "unable to connect to ldap $@";

    my $ldap_user = $ldap->search(
                               base => $ldapUserBase,
                               filter => "|(cn=$targetUser)(uid=$targetUser)",
                               attrs => $required_usr_attrs
                                 );

    if ($ldap_user->entries) {

        foreach ($ldap_user->entries) {
            
            $self->set_fname($_->get_value('givenName')); 
            $self->set_lname($_->get_value('sn'));
            $self->set_cn($_->get_value('cn'));
            $self->set_uid($_->get_value('uid'));
            $self->set_email($_->get_value('mail'));           
            $self->set_dn($_->dn);

            my $dn = $self->get_dn;
            my $uid = $self->get_uid;

             my $ldap_groups = $ldap->search(
                               base => $ldapGroupBase,
                               filter => "|(member=$dn)(memberUid=$uid)",
                               attrs => $required_grp_attrs
                               );
             my @groups = ();

             foreach my $i ($ldap_groups->entries) {
                 my  $foundgroup = $i;
                
                 push @groups, $foundgroup->asn->{attributes}[0]->{vals}[0];
              }

            $self->set_groupMembership( join "," , @groups );                        
        }
    }
    else{
        return undef;
    } 
 
    $ldap->unbind; 

}

sub search_user_debug {
    my ( $self, $targetUser, $connstring, $ldapUserBase, $ldapGroupBase ) = @_;

    my ( $server, $user, $password ) = split "," , $connstring;

    $server =~ s/^\s+|\s+$//g;
    $user =~ s/^\s+|\s+$//g;
    $password =~ s/^\s+|\s+$//g;

    my $ldap = Net::LDAP->new($server) or die "unable to connect $@";
    $ldap->bind ( $user, password => $password ) or die "unable to connect to ldap $@";

    my $dn;
    my $uid;
          
    my $ldap_user = $ldap->search(
                            base => $ldapUserBase,
                            filter => "|(cn=$targetUser)(uid=$targetUser)",                        
                         );

    if ($ldap_user->entries) {

        foreach ($ldap_user->entries) {

            $_->dump;

            print "dn : "            . $_->asn->{objectName} . "\n";
            print "sn : "            . $_->get_value('sn') . "\n";
            print "cn : "            . $_->get_value('cn') . "\n";
            print "uid : "           . $_->get_value('uid') . "\n";
            print "uidNumber : "     . $_->get_value('uidNumber') . "\n";
            print "gidNumber : "     . $_->get_value('gidNumber') . "\n";
            print "homeDirectory : " . $_->get_value('homeDirectory') . "\n";
        
#            print Dumper($_);

#            $dn = $_->asn->{objectName};
            $dn = $_->dn();
            $uid = $_->get_value('uid');
        }
         
        my $ldap_groups = $ldap->search(
                             base => $ldapGroupBase,
                             filter => "|(member=$dn)(memberUid=$uid)",
                             );

        foreach ($ldap_groups->entries){
#            $_->dump;
#           print Dumper($_); 

#            my @members = $_->get_value('member') || 'none' ;  
         
             foreach ($_->get_value('member')) {
                  print " -- $_";
             }
 
#            print  $_->get_value('cn') . " : " . scalar(@members) . "\n" ;
            
        }

    }    
    else{
         print "user with cn=" . $self->{attribute}{cn} . " or uid=" .$self->{attribute}{uid} . " does not exist\n";
    }

    $ldap->unbind;
}

1;
