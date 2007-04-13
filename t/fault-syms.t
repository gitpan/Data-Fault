#! /usr/bin/perl

no warnings;

use Test::More tests => 4;

use Fault( boom => 'fatal' , bam => [ 'fault' , 'chkpt' ] );

# test the interface for specifying error codes and exporting them as symbols.

ok( !defined $FALSIFIED,
    "falsify okay" );

ok( defined $BOOM_FATAL,
    "single class code defined" );

ok( defined $BAM_FAULT ,
    "multi-class code defined" );

ok( defined $BAM_CHKPT ,
    "multi-class code defined" );
