#! /usr/bin/perl

no warnings;

use Test::More tests => 4;
use Test::Deep;

sub listref {
  return \@_;
}

use Fault(
    boom => {
      expert => 'something blew up',
      status => 'fatal',
    },

    bam => {
      operator => 'operator BAM!',
      expert => 'experts?',
      status => [ 'fault' , 'chkpt' ],
    },
);

ok( defined $BOOM_FATAL,
    "single class code in hash defined" );

ok( defined $BAM_FAULT ,
    "multi-class code defined (1)" );

ok( defined $BAM_CHKPT ,
    "multi-class code defined (2)" );

$ok = cmp_deeply(  listref( Fault::reports( $BAM_FAULT ) ),
		   bag(
			operator => 'operator BAM!',
			expert => '(BAM) experts?',
		       ),

		   "messages ok",
		  );

