#! /usr/bin/perl

no warnings;


use Test::More tests => 6;

use Fault ();

# constants

# Ensure that the enumeration of class values has been defined.

ok( defined $Fault::FAULT ,
   "status constants defined");

# class_code

# class_code looks up a fault classification and returns the array
# indice as a coding. it should be case insensitive, and return
# undef for invalid values.

is( Fault::status_encode('fatal') , 0 ,
    "class_code first element" );

is( Fault::status_encode('CHKPT') , 2 ,
    "class_code middle element" );

# pack_fault

# pack_fault combines the class and code into a compact scalar. If it is reversable it works.

my ( $up_code , $up_status ) = Fault::split_fault( Fault::combine_fault( 1 , Fault::status_encode('fault') ) );

is( $up_status , 3 ,
    "fault combine/split class reversable"  );

is( $up_code , 1 ,
    "fault combine/split code reversable"  );

# symbol exporting

Fault::export_target( 'main' );
Fault::export_fault_symbol( "FOO" , 666 );

is( $FOO , 666 ,
   "export_fault_symbol - beastly" );
