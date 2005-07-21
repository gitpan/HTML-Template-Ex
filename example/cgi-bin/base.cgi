#!/usr/bin/perl -w
package ExBase;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: FormField.pm,v 1.11 2004/08/16 00:32:33 Lushe Exp $
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

my $Prefix= '/home/exbase';
my $VRsite= '/home/exbase/vrsite';

my %C= (
 title    => 'ExBase',
 cgiPath  => '/cgi-bin/base.cgi',
 siteRoot => '/',
 prefix   => $Prefix,
 VRsite   => $VRsite,
 indexName=> 'index.html',
 charset  => 'euc-jp',
 options  => {
  path=> ["$Prefix/plugins"],
  },
 );

ExBase::Core->run(%C);


package ExBase::Core;
use strict;
use CGI;
use Jcode;
use FileHandle;
use HTML::Template::Ex;

local $^W = 0;

sub cgi { $_[0]->{cgi} }
sub eucConv { defined($_[1]) ? Jcode->new($_[1])->euc: "" }

sub run {
	my($class, %conf)= @_;
	my $cgi = $conf{cgi}= CGI->new;
	my $base= bless \%conf, $class;
	my($path, $file)=
	  ($ENV{QUERY_STRING} && $ENV{QUERY_STRING}=~/^([^\&\;]+)/)
	    ? $base->pathCuter($1): ('/', $base->{indexName});
	$cgi->charset($conf{charset});
	(-e "$base->{VRsite}$path$file" && -f _)
	 ? do { $base->execute($cgi, $path, $file) }
	 : do { print $cgi->header. q{<h1>404 File Not Found.</h1>} };
}
sub execute {
	my($base, $cgi, $path, $file)= @_;
	$base->{currentUri} = "$base->{cgiPath}?$path$file";
	my $Vars= $cgi->Vars;
	while (my($name, $value)= each %$Vars) {
		$value=~tr/\t/ /;
		$value=~s{\r\n?} [\n]sg;
		$Vars->{$name}= $base->eucConv($value);
	}
	my @path= ("$base->{VRsite}$path", @{$base->{options}{path}});
	$base->{___tpOptions}=
	{ path=> \@path, filename => $file, assosiate=> [$cgi] };
	my $tmpl;
	eval{ $tmpl= HTML::Template::Ex->new($base, $base->{___tpOptions}) };
	print $cgi->header;
	$@ ? do {
		print "Internal Server Error: $@";
	 }: do {
		$tmpl->param({
		 title     => $base->{title},
		 cgiPath   => $base->{cgiPath},
		 siteRoot  => $base->{siteRoot},
		 currentUri=> $base->{currentUri},
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

1;

__END__

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
