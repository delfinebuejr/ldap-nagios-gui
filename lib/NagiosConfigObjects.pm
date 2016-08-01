package NagiosConfigObjects;

## Author: DFIE
## Create Date: 14/07/2016
## Modified Date: 15/07/2016
## create and collect objects defined in a nagios configuration file.
## The object instance can collect one type of object defined from the nagios configuration.
## This is to reduce the complexity for searching and other things. 
## To Do: Add, Delete, and Modify objects from file

use strict;
use warnings;
use Carp qw(carp croak);
use configobjects;
use Data::Dumper;

sub new {
    my ( $class, $arg_for ) = @_;
    my $self = bless {}, $class;
    $self->_init($arg_for);
    return $self;
}

sub _init {
    my ($self, $arg_for) = @_;
    my $class = $self;
    
    my %hash = %$arg_for;

    my $file = delete $hash{file};
    my $filter = delete $hash{filter};


    unless (defined $file) {croak("no config file was specified!")};
    unless (defined $filter) {croak("filter member cannot be blank!")};
    
    unless (-e $file) {croak("The specified config file does not exist!")};

    if (my $remaining = join ",", keys %hash){
        croak("Unknown keys to $class\::keys: $remaining");
    }

    $self->set_file($file);       # target configuration file
    $self->set_filter($filter);       # comma (,) delimitted string that contains target object type
    $self->_process_file;
}

sub write_object {
    my ( $self , $objdef  ) = @_;

    open(FH, ">>" . $self->{file}) or die $!;

    print FH $objdef;

    close FH;
}

sub erase_object {
    my ( $self, $objname )  = @_;
  
    my $startline = -1;
    my $endline = -1;
 
    print $self->{file} . "\n";    

    open(FH, "<" . $self->{file}) or die $!;

    my @fileobj = <FH>;

    close FH;

    my $startdelimitter = "define " . $self->{filter} . "{";
    my $enddelimitter = "}";
    my $start_array_element = -1;
    my $counter = -1;

    foreach (@fileobj){                                # iterate each array element ( line of file )
       $counter++;
       my $type =   index($_, $self->{filter});        # check if filter exists  
       my $tname =  index($_,$objname);                # check if target object name exists

       chomp;

       if ( ($type gt -1)  and ($tname gt 1) ) {       # if filter and objectname exists in the same line
          
            my $iscommentedhash = index($_, '#');      # check if a hash is found before the filter type - meaning it is commented out.
           
            next if ( ($iscommentedhash ge 0) and ($iscommentedhash lt $type) );  
           
            $start_array_element = $counter;           # save the array index if the target object was found 

       }
    }

    if ( $start_array_element gt -1 ) {                # if the object was found in the array then process it

        print $fileobj[$start_array_element] . "\n";

        # read up and seek the $startdelimitter

        for( my $i = $start_array_element ; $i >=0  ; $i--){

            my $foundstart = index($fileobj[$i],$startdelimitter);

            next if ( $foundstart eq -1 );              # skip  unless the $startdelimitter pattern is found

            my $temp = $fileobj[$i];
            $temp  =~ s/^\s+|\s+$//g;

            next if ( index( $temp, "#" ) eq 0 );       # skip if a hash if found at the beginning of the string ( index 0 )
            
            print "$i: $temp\n";
            $startline = $i;
            last;

        }

        # read down and seek the $end delimitter

        for( my $j =  $start_array_element; $j <= scalar @fileobj ; $j++){
     
            my $foundend = index($fileobj[$j],$enddelimitter);

            next if ( $foundend eq -1 );

            my $temp = $fileobj[$j];
            $temp  =~ s/^\s+|\s+$//g;

            if (index($temp, '}') eq 0) {               # exit loop if the string starts with "}"
               
               print "$j: $temp \n";
               $endline = $j;
               last;
            }
 
        }

    }

    print "$startline -- $endline --" .  (($endline - $startline) + 1)  . " \n";

    splice @fileobj, $startline, (($endline - $startline) + 1);            # delete the elements from the array
                    
                                                                           # write the array to a file ( maybe overwrite the original file)
   
    open(FH, ">" . $self->get_file);                                       
    print "";                                                              # erase the contents of existing file file
    close FH;   

    open(FH, ">>" . $self->get_file);
 
    foreach (@fileobj) { 
        
        print FH $_ . "\n";
                
    }
    
    close FH;


    $self->_process_file;                                                     # reload the modified file
    
                                                              # winmerge/diff to validate the deletion change
}

sub _process_file {

    my ( $self ) = shift;
 
    my $file = $self->get_file;
    my $obj = $self->get_filter;

    open(FH, "<$file") or die $!;

    my @fileobj = <FH>;

    my @nosemicolon = map { (split ";" , $_)[0] } @fileobj;          # remove comments starting with a semicolon

    my @nocomments = map { (split "#" , $_)[0] } @nosemicolon;    # remove comments starting with a hash

    my $filestring = join '_new_' , @nocomments;                                # convert the clean file array to a string

    $self->_create_objects($obj, $filestring,);
    
}

sub _create_objects {

    my ($self, $obj, $filestring) = @_;

    my @allobjects;

    my @x = split "define $obj\{", $filestring;                            # start extracting the target object definition

    my @y = ();

    shift @x;                                                     #dump the first element as it is not an object definition

    foreach my $i (@x) {

        my $nagobj = configobjects->new({
                                        type => $obj,
                                       });

        my @temp = split "}", $i;                                 # complete the extraction of the target object definition

        my $temp1 = $temp[0];                                     # get the data and discard the blank array element $temp[1]

        $temp1 =~ s/_new__new_/_new_/g;                           # cleanup the object definition data

        my @definedobj = split '_new_' , $temp1;

        pop @definedobj;                                          # remove the empty first element
        shift @definedobj;                                        # remove the empty last element

        foreach (@definedobj) {

            my @directives = split '_new_', $_;

            foreach my $directive ( @directives ) {

                $directive =~ s/^\s+|\s+$//g;

                my @items = split " ", $directive;
                my $name = $items[0];

                $name =~ s/^\s+|\s+$//g;
                shift @items;

                my $value = join ' ', @items;


                $value =~ s/^\s+|\s+$//g;

                $nagobj->set_data($name, $value);

           }
        }
           push @allobjects, $nagobj;
    }

    $self->set_count(scalar @allobjects);
    $self->_set_allobjects(@allobjects)
    
}

sub get_file {
    my $self = shift;
    return $self->{file};
}

sub get_filter {
    my $self = shift;
    return $self->{filter};
}

sub _set_allobjects {
    my ($self, @data) = @_;
    $self->{allobjects} = \@data;
}

sub set_file {
    my ( $self, $file ) = @_;
    $self->{file} = $file;
}

sub set_count {
    my ($self, $count) = @_;
    $self->{count} = $count
}

sub set_filter {
    my ( $self, $filter ) = @_;
    $self->{filter} = $filter;
}

sub get_count {
    my $self = shift;
    return $self->{count};
}

sub get_allobjects {
    my ($self) = shift;
    return $self->{allobjects};
}

1;
