#----------------------------------------------------------------------
# Fault::Cascade.pm
# written by: Mike Mattie
# copyright: (2006) Mike Mattie
# license: LGPL
#----------------------------------------------------------------------

# An error cascade usefull for constructing a usefull error report
# from exceptions by adding error information or diagnostics at each
# handler and then re-throwing the object. It is not a stack trace, it
# is an exception unwind trace.

# cascade has been improved greatly by adding a head with a current
# fault code at the head of the report stack.

package Fault::Cascade;

use Fault::Report;
use Fault::Dump;

use Text::Wrap;

#----------------------------------------------------------------------
# cascade tuning
#----------------------------------------------------------------------

our $indent = 2;
our $line_limit = 80;

our $technical_contact = 'technical contact not set';
our $support_contact = 'support contact not set';

our $prefix = undef;
our $order = undef;

sub import {
  shift();

  return unless ( @_ );

  my %args = @_;

  our $technical_contact = $args{'technical'} if ( exists $args{'technical'} );
  our $support_contact = $args{'support'} if ( exists $args{'support'} );

  our $prefix = $args{'prefix'} if ( exists $args{'prefix'} );
  our $order = $args{'order'} if ( exists $args{'order'} );
}

#----------------------------------------------------------------------
# create/modify
#----------------------------------------------------------------------

sub new {

  # a fault is required, reports are not. multiple reports can be submitted in a single call.

  my $class = shift();
  my %args = @_;

  my $self = bless {
    reports => [],
  } , $class;

  $self->set_context( defined( $args{'context'} )
			? $args{'context'}
		        : caller() );

  $self->set_fault( $args{'fault'} );

  $self->update( @{ $args{'reports'} } ) if ( exists $args{'reports'} );

  return $self;
}

sub set_context {
  my $self = shift();
  $self->{'default_context'} = shift();
}

sub set_fault {
  my ( $self , $fault ) = @_;

  $self->{'fault'} = ( 'Fault' eq ref $fault )
    ? $fault
    : new Fault ( $fault );

  my @fault_messages = Fault::reports( $self->{'fault'} );

  $self->report( @fault_messages ) if ( @fault_messages );
}

sub update {
  # update the fault code and/or add reports. the last fault given
  # replaces any previous fault code. Reports are appended.

  my $self = shift();

  map {
    # TODO
    # this needs to white-list append the objects , if it isn't
    # the object assume it's a un-blessed fault
    if ( 'Fault' eq ref $_ ) {
      $self->set_fault( $_ );
    }
    else {
      push @{ $self->{'reports'} } , $_;
    }
  } @_;

  # some old OO style, make it chainable by returning self.
  return $self;
}

#----------------------------------------------------------------------
# helpers that use the default_context value
#----------------------------------------------------------------------

sub report {
  my $self = shift();

  $self->update(
    new Fault::Report ( context => $self->{'default_context'} , @_  ),
   );

  return $self;
}

sub data {
  my $self = shift();

  $self->update(
    new Fault::Dump ( context => $self->{'default_context'} ,
			description => $_[0],
		        data => $_[1]),
   );

  return $self;
}

#----------------------------------------------------------------------
# conveinance accessors
#----------------------------------------------------------------------

# some conveinant accessors to get at the class and code of the current fault object.

sub status {
  my $self = shift();
  die "fault cascade is missing a fault code, failed sanity: aborting now"
    unless exists ( $self->{'fault'} );

  return $self->{'fault'}->status();
}

sub code {
  my $self = shift();

  die "fault cascade is missing a fault code, failed sanity: aborting now"
    unless exists ( $self->{'fault'} );

  return $self->{'fault'}->code();
}

#----------------------------------------------------------------------
# report generation
#----------------------------------------------------------------------

sub summary {
  my $self = shift();
  $self->chrono_summary();
}


#----------------------------------------------------------------------
# formatting
#----------------------------------------------------------------------

sub chrono_format {
  my ( $report , $tag ) = splice @_, 0, 2;

  my $leader = join('' ,
		    ( $tag )
		      ? $tag
		      : '?' ,
		    '> ' );

  local $Text::Wrap::collumns = $line_limit;

  wrap( ( $indent_flag) ? ' ' x $indent : '' , ' ' x length($leader),
	join('' , $leader, @_ ));
}

sub chrono_report {
  my $report = $_;

  if ( 'Fault::Report' eq ref $report ) {
      (
	( exists $report->{'operator'} )
	  ? chrono_format( $report , 'Operator' , $report->unwrap( 'operator' ) )
	  : (),

	( exists $report->{'expert'} )
	  ? chrono_format( $report , 'Fault', $report->unwrap( 'expert' ))
	  : (),
     )
    }
  elsif ( 'Fault::Dump' eq ref $report ) {
    my $data = $report->{'data'};

    # TODO , get this to wrap right and/or do the appendices
    # $data =~ tr/\n/ /;

    chrono_format( $report , 'Data',
		   join('' , $report->{'description'} , ': "', $data  , '"'));
#     push @{ collate_list( $_->{'context'} ) } , appendice_reference( $_ );
    }
  else {
    die "Fault::Cascade unkown report type " . ref $report;
  }
}

sub chrono_summary {
  our $prefix;
  my $self = shift();

    join("\n\n",
	 "$prefix -_Error Report_-",

	 map {
	   our $indent_flag = ( @{ $$_[1] } > 1 ) ? 1 : 0;

	   join( ( @{ $$_[1] } > 1 ) ? "\n" : '',
		'[' . $$_[0] . ']' ,
		map( chrono_report , @{ $$_[1] } )
	       );
	 } reverse $self->collate_by_context(),
	 );
}

#----------------------------------------------------------------------
# collation
#----------------------------------------------------------------------

# collate_list is called with a key string. A list for collating by that
# key is returned for use with the standard list functions.

# TODO: this is a very general sort of function, isolate the core from the
#       specifics of the data.

{
  my @order_context;    # used to preserve the chronology of the expert reports
  my %collate_context;  # used to collate expert reports by context

  sub collate_list {
    my $context = shift();

    unless ( exists $collate_context{ $context } ) {
      $collate_context{ $context } = [];
      push @order_context , $context;
    }

    return $collate_context{ $context };
  }

  sub collate_ordered {
    # return the list but do not clear it.

    return () unless( @order_context );

    # walk through the list replacing the context keys with a context,report-array pair.

    map {
      [ $_ , $collate_context{ $_ } ]
    } @order_context;
  }

  sub collate_clear {
    # return the collated data, and clear it.
    my @collate = collate_ordered();

    @order_context = ();
    %collate_context = ();

    return @collate;
  }
}

sub split_reports {
  my $report = shift();

  return $report if ( 'Fault::Report' ne ref $report );

  return $report unless ( exists $report->{'expert'} && exists $report->{'operator'}  );

  my %oper = %$report;
  delete $oper{'expert'};
  delete $report->{'operator'};

  ( bless( \%oper , Fault::Report ) , $report );
}

sub collate_by_context {

  # the cascade. The reports are collated by the context , and returned in
  # chronological order, oldest to newest.

  # returns a empty list if there are no reports for the consumer.

  # otherwise returns a array in chronological order of pairs:
  # [ context , array of report strings ]

  # TODO: it may be more usable if the order is reversed

  my $self = shift();

  return () unless ( @{ $self->{'reports'} } > 0 );

  map {
    push @{ collate_list( $_->{'context'} ) } , split_reports($_);
  } @{ $self->{'reports'} };

  collate_ordered();
}

#----------------------------------------------------------------------
# appendices
#----------------------------------------------------------------------

# appendice_reference is called with a Fault::Dump object. A placeholder
# string including a reference to the dump will be returned to take
# the place of the data.

# appendice_list when processing the cascade list is complete  will
# return the data from the Fault::Dump objects in the order they were
# referenced.

# appendice_clear should be called before a new traversal of the cascade
# list where the appendice_ functions will be used.

# TODO: this is a very general sort of function, isolate the core from the
#       specifics of the data.

sub text_appendices {
  my $indice = 1;

  join("\n",
       '===> data appendices',

       map {

         join("\n",
              'dump(' . $indice++ . '): ' . $_->{'description'},
              $_->{'data'}) if ('Fault::Dump' eq ref $_);

       } appendice_list()
      );
}

{
  my $appendice = 1;
  my @dumps = ();

  sub appendice_clear {
    $appendice = 1;
    @dumps = ();
  }

  sub appendice_reference {

    # the object given is placed on the appendice list

    my $dump = shift();
    push @dumps , $dump;

    return join('',
                "data dump(" , $appendice++ , "): ",
                $dump->{'description'});
  }

  sub appendice_list {
    return @dumps;
  }
}

1;
