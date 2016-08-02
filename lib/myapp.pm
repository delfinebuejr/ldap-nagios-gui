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
#   my $out = session('cnt');

    my $logged_in_user = session('logged_in_user');
             
    template 'ldap-nagios', {
                              'logged_in_user' => $logged_in_user
                            };
};

get '/ldapquery' => require_role Admins => sub {

    my $logged_in_user = session('logged_in_user');

    my $targetUser = request->param('username');      # catch $env variables
    my $cfg = new Config::Simple('../ldapnagios.cfg');

    my $connstring = $cfg->param('connstring');
    my $ldapUserBase = $cfg->param('ldapUserBase');
    my $ldapGroupBase = $cfg->param('ldapGroupBase');

    my $objldapuser = LDAPuser->new;
    $objldapuser->search_user( $targetUser, $connstring, $ldapUserBase, $ldapGroupBase );

    if ($objldapuser->get_dn) {
    
        template 'display-ldap-query-result', { 
                                                'logged_in_user' => $logged_in_user,
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

    my $logged_in_user = session('logged_in_user');

    my $cfg = new Config::Simple('../ldapnagios.cfg');

    my $configFile = $cfg->param('configFile');
    my $objectType = $cfg->param('objectType');

    my $svn_local_workspace = $cfg->param('svn_local_workspace');
    $svn_local_workspace .= "/$logged_in_user";

    my $svn_url = $cfg->param('svn_url');

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

##
## ADD CONTACT GROUP OBJECT HERE

    for(my $i = 0; $i <= $objconfigfile->get_count -1 ; $i++) {            # run the fullName against the config file objects to ensure that it does not exist yet

        if ($contact->get_fullName eq $objconfigfile->get_allobjects->[$i]->{attribute}->{contact_name}) {
            return $contact->get_fullName . " nagios contact already exists. Nothing to do.";
        }
    }

    $objconfigfile->write_object($contact->create_nagiosContact);

    $client->commit("$svn_local_workspace/$configFile",0);

    return "Successfully updated $svn_local_workspace/$configFile";

};

get '/show_objects' => require_role Admins => sub {

    my $logged_in_user = session('logged_in_user');
    my $svn_url = request->param('svnurl');
    my $objectType = request->param('objectType');

    if($svn_url){
                                                                                   # prepare local workspace
        my $cfg = new Config::Simple('../ldapnagios.cfg'); 

        my $svn_local_workspace = $cfg->param('svn_local_workspace');
        $svn_local_workspace .= "/$logged_in_user";
        
        if ( -e $svn_local_workspace ) {                                           # clean-up local workspace
            unlink glob "$svn_local_workspace/*";
        }
                                                                                    # prepare svn client for checkout
        my $client = new SVN::Client(
            auth => [
                      SVN::Client::get_simple_provider(),
                      SVN::Client::get_simple_prompt_provider(\&simple_prompt,2),
                      SVN::Client::get_username_provider()
                    ]);

        $client->checkout($svn_url,$svn_local_workspace,'HEAD',1);                  # checkout the config file

        opendir (my $dh, $svn_local_workspace);

        my @cfg = grep { /\.cfg/ } readdir($dh);

        my @arr = map { { 'name' => $_ } } @cfg;

        closedir $dh;

#        my @filename = split '/' , $svn_url ;
#        debug( Dumper(@filename));                                                                                   # create the config file object
#        debug( "file: $filename[$#filename]" );
#        debug( "Load File: $svn_local_workspace/$filename[$#filename]" );
#        my $objconfigfile = NagiosConfigObjects->new({
#                                   file => "$svn_local_workspace/$targetfile",
#                                   filter => $objectType
#                                });
#        debug( Dumper($objconfigfile->get_allobjects()) );        
        
        my %var = (
                    'logged_in_user' => $logged_in_user,
                    'sw_select'      => 1,
                    'select_options' => \@arr,
                    'objtype'        => $objectType,
                    'svnurl'         => $svn_url,
                  );

        debug(Dumper(%var));
                    
        template 'show-objects', \%var;
    }
    else{
        template 'show-objects', {
                                    'logged_in_user' => $logged_in_user,
                                    'sw_select' => 0,
                                  };

    }
};


#### UTILITY FUNCTIONS

sub simple_prompt {
    my ($cred, $realm, $default_username, $may_save, $pool) = @_;

    my $cfg = new Config::Simple->new('../ldapnagios.cfg');

    my $svn_username = $cfg->param('svn_username');
    my $svn_password = $cfg->param('svn_password');

    chomp($svn_username);
    $cred->username($svn_username);
    chomp($svn_password);
    $cred->password($svn_password);
}

true;
