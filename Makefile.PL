use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
 NAME        => 'HTML::Template::Ex',
 VERSION_FROM=> 'Ex.pm', # finds $VERSION
 PREREQ_PM   => { 'HTML::Template'=> '2.0' },
 );

