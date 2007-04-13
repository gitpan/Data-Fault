#! /usr/bin/perl

no warnings;

use Test::More tests => 2;

use Fault( boom => 'fault' );

$faulty = new Fault ( $BOOM_FAULT );

is( $faulty->status() , $Fault::FAULT ,
   "status accessor works" );

is( $faulty->code() , $BOOM_ERROR ,
   "code accessor works" );
