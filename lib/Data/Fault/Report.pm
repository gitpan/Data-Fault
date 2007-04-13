#----------------------------------------------------------------------
# written by: Mike Mattie
# copyright: 2007
# license: LGPL
#----------------------------------------------------------------------

package Fault::Report;

# call with operator => "string" , expert => 'string' for the two categories of information

# with an expert string a context string can be added describing the
# region from which the report issued.

# This is a glorified hash, made a object only for easy and
# transparent runtime type dispatch

sub new {
  my $class = shift();

  my %info = @_;

  if ( exists $info{'expert'} ) {
    # always ensure there is a context for expert reports

    unless ( exists $info{'context'} ) {
      $info{'context'} = caller();
    }
  }

  map { die join(" ",
                 "[Fault::Report] invalid key \"$_\" given in namespace:",
                 caller(),
                 "\n") unless ( /operator|expert|context/ ); } ( keys %info );

  bless \%info , $class;
}

sub unwrap {
  my ( $self , $consumer ) = @_;

  my $scribble = ( 'ARRAY' eq ref $self->{ $consumer } )
    ? join( " " , @{ $self->{ $consumer} } )
    : $self->{ $consumer };

  $scribble =~ tr/\n/ /;

  return $scribble;
}

1;

