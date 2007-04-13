#----------------------------------------------------------------------
# Fault.pm
# written by: Mike Mattie
# Copyright: Mike Mattie 2007
# License: LGPL
#----------------------------------------------------------------------

package Fault;

=head1 Fault

=head1 Synopsis

Fault.pm generates and exports fault (error) symbols. These symbols
are a combination of fault classification and a globally unique fault
ID.

=head1 Description

Fault symbols are scalar whole numbers with encode/decode functions to
combine and split the classification and the assigned code.

These error symbols are called faults to distinguish capturing a
unexpected outcome ( such as a system error-code or null value ), from
the computational failure; the more common use of the term error.

Combining an internal code with a general classification of the
component's ability to further function cleanly promotes an
implementation issue (white-box) to an abstract fault when it
propagates outside of the name-space that defines it (black-box).

The distinction between fault and error allows lightweight handling of
simple responses: choosing protocol responses through an API for
example.

Complex cases such as selecting fall-back or repair responses can be
cleanly implemented with separation between detection, diagnostics,
and error handling. Handling unavailable services or corrupted state
are examples of the more complex scenarios.

=cut

#----------------------------------------------------------------------
# fault classification
#----------------------------------------------------------------------

=head1 Classification of faults

Classification of faults is by how the unexpected behavior has altered
the state between operations, or it's ability to continue.

when a error code propagates outside of the black-box in which it is
defined the specificity of the error code is no longer meaningful
outside of that black-box.

The catching/receiving context can use the classification minimally
or the code specifically depending on how tight the coupling between
the components is.

=head2 Definition

The classification values are defined with names within fault so that
classification can be determined by comparison.

=cut

our @status = (

  'fatal',

  'reject',

  'chkpt',

  'fault',
 );

INIT {
  # create the classification constants to compare against

  my $status_code = 0;
  export_target( 'Fault' );

  map { export_fault_symbol( uc( $_ ) , $status_code++ ) } @status;
}

=over 4

=item $Fault::FATAL

unrecoverable error, value 0 for an easy test.

=item $Fault::REJECT

recoverable; no state changed (example: input validation failed)

=item $Fault::CHKPT

recoverable; state is checkpoint-ed

=item $Fault::FAULT

recoverable; unknown state

=back

=cut

#----------------------------------------------------------------------
# fault layout/encoding
#----------------------------------------------------------------------

sub status_encode {
  my $status_symbol = lc( shift() );

  my $status_code = 0;
  ++$status_code while ( $status_code < @status
                           && $status_symbol ne $status[$status_code] );

  return $status_code if ( $status_code < @status );

  die "Fault.pm invalid status associated with a fault symbol: \"$status_symbol\" is wrong.";
}

my $mask_bits = 4;
my $mask_status = 0xf;

sub combine_fault {
  my ( $code , $status ) = @_;

  return $status | $code << $mask_bits;
}

sub split_fault {
  my $fault = shift();

  return ( $fault >> $mask_bits , $fault & $mask_status );
}

{
  #----------------------------------------------------------------------
  # guid allocator for fault codes
  #----------------------------------------------------------------------

  my $code_GUID = 0;

  sub allocate_new_code {
    return ++$code_GUID;
  }

  sub allocated_code {
    return $code_GUID;
  }
}

#----------------------------------------------------------------------
#
#----------------------------------------------------------------------

our @messages = ();

sub reports {
  my $fault = shift();

  my $index = ( 'Fault' eq ref $fault )
    ? $fault->code()
    : ( split_fault( $fault ) )[0];

  if ( defined( $messages[ $index ] ) ) {

    my %tmp = %{ $messages[ $index ] };

    $tmp{'expert'} = join('' ,
			  "(" ,
			  ( exists $tmp{'symbol'} )
			    ? $tmp{'symbol'}
			    : '?',
			  ")",

			  ( exists $tmp{'expert'} )
			    ? (' ' , $tmp{'expert'} )
			    : (),
			  );

    delete $tmp{'symbol'};

    return ( %tmp );
  }

  return ();
}

#----------------------------------------------------------------------
# symbol interface
#----------------------------------------------------------------------

=head1 Defining fault symbols

The Fault.pm interface for creating fault symbols is import, ie
the 'use' directive.

To define (import) fault symbols list the fault names, followed by
a single classification or an array of multiple classifications
separated with: ',' or '=>'

    use Fault ( burning => [ fatal, fault ] , stabbing => fatal ); # import fault symbols

fault will create scalars in your package symbol table that can be
used like this:

    $BURNING_FATAL , $BURNING_FAULT , $BURNING_ERROR
    $STABBING_FATAL , $STABBING_ERROR

The code is always on the left, with the classification on the right;
matching the declaration pattern for intuitive mapping from import to
referencing of the symbols.

the _ERROR export is the globally unique error id by itself. This is
created automatically per-fault.

=head2 w/o importing

When using the module (definitions) without importing any fault symbols
use empty parentheses.

    use Fault();                                                   # use the module without generating symbols

=cut

{
  #----------------------------------------------------------------------
  # exporting
  #----------------------------------------------------------------------

  my $export_ns;

  sub export_target {
    $export_ns = shift();
  }

  sub export_fault_symbol {
    my ( $symbol , $data ) = @_;

    ${ join("::", $export_ns , $symbol )  } = $data;
  }

  #----------------------------------------------------------------------
  # helpers for forming symbols table entries
  #----------------------------------------------------------------------

  sub form_ERROR_symbol {
    join("",
         uc( shift() )  , "_" , 'ERROR' );
  }

  sub form_FAULT_symbol {
    my ( $name , $status ) = @_;

    join("",
         uc( $name )  , "_" , uc( $status ) );
  }

  sub import {

    # guard against forgetting () for no fault defs
    shift();
    return unless ( @_ );

    # set the target names-pace for the symbol formation helpers.

    $export_ns = caller;
    my %spec = @_;

    my $kind;
    my $status;

    foreach $kind ( keys %spec ) {

      export_fault_symbol( form_ERROR_symbol( $kind ),
                           allocate_new_code() );

      if ( 'HASH' eq ref $spec{$kind} ) {
	$status = $spec{$kind}->{'status'};

	delete $spec{$kind}->{'status'};
	$messages[ allocated_code() ] = $spec{$kind};
      } else {
	$status = $spec{$kind};
	$messages[ allocated_code() ] = {};
      }

      $messages[ allocated_code() ]->{'symbol'} = uc( $kind );

      map {
        export_fault_symbol( form_FAULT_symbol( $kind , $_ ),
                             combine_fault( allocated_code() , status_encode( $_ )) );

      } @{
        if ( 'ARRAY' eq ref $status ) {
          $status;
        }
        elsif ( '' eq ref $status ) {
          [ $status ];
        }
      };
    }
  }
}

=head1 Using fault symbols internally (white-box)

Fault symbols can be used within the module they are defined by
treating them as named simple ( whole ) numbers. Simple comparison
operations are all that is needed.

   eval {
      die $BURNING_FAULT if ( some_error() );   // detect here
   };

   if ( $@ == $BURNING_FAULT ) {
      // recover here
   }

=over

=item Fault::code()

the Fault::code() function returns the code of the component. This is
useful when the specific error without the classification is needed.

=back

  if( Fault::code( $BURNING_FATAL  ) != $BURNING_ERROR ) {
    print "imploded !";
    exit 1;
  }

=cut

sub code {
  my $self = shift();

  ( split_fault( $$self ) )[0];
}

=head1 Using fault symbols externally (black-box)

Fault symbols that propagate outside the defining name-space
are usable with the classification component only.

=over

=item Fault::status()

the Fault::status() function returns the classification component of a
fault symbol. This can be compared against the named values
Fault::FATAL,...

    if ( Fault::status( $@ ) == $Fault::REJECT ) {
       goto do_over;
    }

    if ( Fault::status( $@ ) == $Fault::FATAL ) {
       print "died horribly\n";
       exit 1;
    }

=back

=cut

sub status {
  my $self = shift();

  ( split_fault( $$self ) )[1];
}

#----------------------------------------------------------------------
# OO bless
#----------------------------------------------------------------------

=head1 blessed fault symbols

it is very useful to bless fault symbols to disambiguate them
from standard exceptions.

    die new Fault ( $BURNING_FATAL );

    if ( ref $@ eq 'Fault' ) {
        exit 1 if ( $@->status() == $Fault::FATAL );
    }

=cut

sub new {
  my $classname = shift();

  bless \shift() , $classname;
}

sub fault {
  # untested , this may be a useful accessor through

  my $self = shift();
  return $$self;
}

=head1 See Also

=head1 Author

Mike Mattie email = codermattie@gmail.com

=head1 copyright

Copyright Mike Mattie 2007. All Rights reserved.

=head1 License

LGPL.

=head1 TODO

=over

=item intergrate with Fault unaware code

Essentially the fault symbols need to stringify in a string context.
This should cover most of the error traps.

=item improve examples

The Fault::code() example is a punt, come up with a better scenario

=item add strategies

Document strategies for using Fault effectively.

=back

=cut

1;
