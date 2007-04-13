#! /usr/bin/perl

#----------------------------------------------------------------------
# fault-axioms.t
# written by: Mike Mattie
# copyright: 2007
# License: GPLv2
#----------------------------------------------------------------------

no warnings;
use Test::More tests => 2;

use Fault( boom => 'fatal' , bam => [ 'fault' , 'chkpt' ] );

#----------------------------------------------------------------------
# establish some axioms for using fault.pm defined error symbols
#----------------------------------------------------------------------

# axiom 1: an error+classification exported as a symbol is a unique entity.
#          note how the string comparison operators are used.

#          using the numeric comparison operators will produce a incorrect
#          result.

ok( $BOOM_FATAL != $BAM_FAULT ,
    "error symbols are unique A != B" );

#  1.1: fault symbols retain identity when copied.
#
#

my $copy = $BOOM_FAULT;
ok ( $copy == $BOOM_FAULT,
   "copied error symbols retain identity");
