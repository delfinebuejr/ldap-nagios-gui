requires "Dancer2" => "0.201000";

requires "CGI::Fast"          => "0";
requires "Config::Simple"     => "0";
requires "Data::Dumper"       => "0";
requires "Dancer2::Plugin::Auth::Extensible"     => "0";
requires "Net::LDAP"          => "0";
requires "Template"           => "0";
recommends "YAML"             => "0";
recommends "URL::Encode::XS"  => "0";
recommends "CGI::Deurl::XS"   => "0";
recommends "HTTP::Parser::XS" => "0";



on "test" => sub {
    requires "Test::More"            => "0";
    requires "HTTP::Request::Common" => "0";
};
