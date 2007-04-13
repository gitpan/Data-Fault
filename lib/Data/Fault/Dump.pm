#----------------------------------------------------------------------
# written by: Mike Mattie
# copyright: 2007
# license: LGPL
#----------------------------------------------------------------------

package Fault::Dump;

use Data::Dumper;

# call with description => "string" , data => string

# a dump is raw data, no re-formatting will be done by higher level routines.
# as a convienance if the data key is a 'REF' hard reference a text dumping
# routine will dump the variable or structure.

# This is a glorified hash, made a object only for easy and
# transparent runtime type dispatch

sub new {
  my $class = shift();

  my %info = @_;

  # always ensure there is a context

  unless ( exists $info{'context'} ) {
    $info{'context'} = caller();
  }

  map { die join(" ",
                 "[Fault::Dump] invalid key \"$_\" given in namespace:",
                 caller(),
                 "\n") unless ( /description|data|context/ ); } ( keys %info );

  if ( '' ne ref $info{'data'} ) {
    $info{'data'} = Dumper( $info{'data'} );
  }

  bless \%info , $class;
}

1;
