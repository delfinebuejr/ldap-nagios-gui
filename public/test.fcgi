#!/usr/bin/perl -wT

use strict;
use vars qw( $count );
use FCGI;

local $count = 0;

while ( FCGI::Accept >= 0 ) {
    $count++;
    print "Content-type: text/plain\n\n";
    print "You are request number $count. Have a good day!\n";
}
