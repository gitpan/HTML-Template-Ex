#!/usr/bin/perl -w
package ExBase;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: base.cgi,v 1.2 2005/07/21 16:12:28 Lushe Exp $
#
# Usage:
#
#  http://myhost/cgi-bin/base.cgi
#    or
#  http://myhost/cgi-bin/base.cgi?/index.html
#
# * The file under the control of $C{VRsite} is processed by this as a template.
#
use strict;
# use lib qw(/home/exbase/lib);

my $Prefix  = '/home/exbase';
my $VRsite  = '/home/exbase/vrsite';
my $REVISION= q$Id: base.cgi,v 1.2 2005/07/21 16:12:28 Lushe Exp $;

my %C= (
 title    => 'ExBase',
 cgiPath  => '/base.cgi',
 siteRoot => '/',
 charset  => 'euc-jp',
 prefix   => $Prefix,
 VRsite   => $VRsite,
 indexName=> 'index.html',
 options  => {
  path=> ["$Prefix/plugins"],
  },
 REVISION => $REVISION,
 );

my $apr= shift || undef;
# $apr= undef; ## It might have to be 'undef' for mod_perl2.
ExBase::Core->run($apr, %C);


package ExBase::Core;
use strict;
use CGI;
use Jcode;
use FileHandle;
use HTML::Template::Ex;

sub cgi { $_[0]->{cgi} }
sub eucConv { defined($_[1]) ? Jcode->new($_[1])->euc: "" }

sub run {
	my($class, $apr, %conf)= @_;
	my $cgi = $conf{cgi}= CGI->new($apr);
	my $base= bless \%conf, $class;
	my($path, $file)=
	  ($ENV{QUERY_STRING} && $ENV{QUERY_STRING}=~/^([^\&\;]+)/) ? $base->pathCuter($1):
	  $cgi->param('path') ? $base->pathCuter($cgi->param('path'))
	                      : ('/', $base->{indexName});
	$cgi->charset($conf{charset});
	(-e "$base->{VRsite}$path$file" && -f _)
	 ? do { $base->execute($cgi, $path, $file) }
	 : do { print $cgi->header. q{<h1>404 File Not Found.</h1>} };
}
sub execute {
	my($base, $cgi, $path, $file)= @_;
	$base->{currentPath}= "$path$file";
	$base->{currentUri} = "$base->{cgiPath}?$base->{currentPath}";
	my $Vars= $cgi->Vars;
	while (my($name, $value)= each %$Vars) {
		$value=~tr/\t/ /;
		$value=~s{\r\n?} [\n]sg;
		$Vars->{$name}= $base->eucConv($value);
	}
	my @path= ("$base->{VRsite}$path", @{$base->{options}{path}});
	$base->{___tpOptions}=
	{ path=> \@path, filename => $file, associate=> [$cgi] };
	my $tmpl;
	eval{ $tmpl= HTML::Template::Ex->new($base, $base->{___tpOptions}) };
	print $cgi->header;
	$@ ? do {
		print "Internal Server Error: $@";
	 }: do {
		$tmpl->param({
		 title=> $base->{title},
		 cgiPath=> $base->{cgiPath},
		 siteRoot=> $base->{siteRoot},
		 currentUri=> $base->{currentUri},
		 currentPath=> $base->{currentPath},
		 scriptVersion=> sub { $base->scriptVersion },
		 supportURL=> 'http://luuu.net/exbase/',
		 });
		print $tmpl->output;
	 };
}
sub fileOpen {
	my $base= shift;
	my $file= shift || return 0;
	FileHandle->new($file) || 0;
}
sub pathCuter {
	my $base= shift;
	my $path= shift || return ("/", $base->{indexName});
	my($dir, $file)=
	  $path=~m{^(/.*?)([^/]+)$} ? ($1, $2): ($path, $base->{indexName});
	(($dir || '/'), $file);
}
sub scriptVersion { $_[0]->{REVISION}=~/v\s+([\.\d]+)/; "ExBase V$1" }

1;

#-------------------------------------------------------------------------------

=pod

=head1 NAME

ExBase - It is CGI sample that used HTML::Template::Ex.


=head1 NOTES

The latest version of this script can be downloaded from the following site. 

http://luuu.net/exbase/

=head1 COPYRIGHT

Copyright 2004 Bee Flag, Corp. <L<http://beeflag.com/>>, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.


=head1 AUTHOR

Masatoshi Mizuno, <mizunoE<64>beeflagE<46>com>

=cut
