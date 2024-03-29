use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Fault',
    VERSION           => 'z668',

    PREREQ_PM         => { qw/ Text::Wrap /  }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Fault.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Mattie <codermattie@gmail.com>') : ()),
);
