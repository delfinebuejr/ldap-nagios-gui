package myapp;
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Config::Simple;
use Data::Dumper;
use LDAPuser;
use NagiosContact;
use NagiosConfigObjects;
use SVN::Client;

our $VERSION = '0.1';

get '/' => sub {
    session( 'cnt' => 1 );
    template 'index';
};

get '/ldapnagios' => require_role Admins => sub {
    my $counter = session('cnt') || 0;
    $counter++;
    debug("Counter: $counter");
    session( 'cnt' => $counter );
    my $out = session('cnt');
    
    template 'ldap-nagios';
};

get '/ldapquery' => require_role Admins => sub {

    my $targetUser = request->param('username');      # catch $env variables
    my $cfg = new Config::Simple('../ldapnagios.cfg');

    my $connstring = $cfg->param('connstring');
    my $ldapUserBase = $cfg->param('ldapUserBase');
    my $ldapGroupBase = $cfg->param('ldapGroupBase');

    debug("targetUser: $targetUser");
    debug("connstring: $connstring");
    debug("ldapUserBase: $ldapUserBase");
    debug("ldapGroupBase: $ldapGroupBase");

    my $objldapuser = LDAPuser->new;
    $objldapuser->search_user( $targetUser, $connstring, $ldapUserBase, $ldapGroupBase );

    debug( Dumper($objldapuser));

    if ($objldapuser->get_dn) {
    
        template 'display-ldap-query-result', {
            'fname' => $objldapuser->get_fname,
            'lname' => $objldapuser->get_lname,
            'email' => $objldapuser->get_email,
            'contactGroup' => 'testGroup',
            'contactType' => 'testType',
        };
    }
    else{
        return "$targetUser not found in LDAP";
    }
};

get '/add_contact' => require_role Admins => sub {

    my $cfg = new Config::Simple('../ldapnagios.cfg');

    my $svn_local_workspace = $cfg->param('');

    my $contact = NagiosContact->new({
                                   fname => request->param('fname'),
                                   lname => request->param('lname'),
                                   email => request->param('email'),
                                   contactGroup => request->param('contactGroup'),
                                   contactType => request->param('contactGroup')
                                });

    my $client = new SVN::Client(
      auth => [
          SVN::Client::get_simple_provider(),
          SVN::Client::get_simple_prompt_provider(\&simple_prompt,2),
          SVN::Client::get_username_provider()
      ]);    

    if ( -e $svn_local_workspace ) {
        unlink glob "$svn_local_workspace/*";
    }

    $client->checkout($svn_url,$svn_local_workspace,'HEAD',1);

    my $objconfigfile = NagiosConfigObjects->new({
                                              file => "$svn_local_workspace/$configFile",
                                              filter => $objectType
                                             });

    for(my $i = 0; $i <= $objconfigfile->get_count -1 ; $i++) {            # run the fullName against the config file objects to ensure that it does not exist yet
        print Dumper($objconfigfile->get_allobjects->[$i]->{attribute}->{contact_name});

        if ($contact->get_fullName eq $objconfigfile->get_allobjects->[$i]->{attribute}->{contact_name}) {
            return $contact->get_fullName . " nagios contact already exists. Nothing to do.";
        }
    }

    $objconfigfile->write_object($contact->create_nagiosContact);

    $client->commit("$svn_local_workspace/$configFile",0);

    return "Successfully updated $svn_local_workspace/$configFile";

}

sub simple_prompt {
    my ($cred, $realm, $default_username, $may_save, $pool) = @_;

    chomp($svn_username);
    $cred->username($svn_username);
    chomp($svn_password);
    $cred->password($svn_password);
}

true;
