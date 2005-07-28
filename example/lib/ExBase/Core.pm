package ExBase::Core;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: Ex.pm,v 1.1 2005/07/21 15:13:10 Lushe Exp $
#
use strict;
use CGI;
use Jcode;
use FileHandle;
use HTML::Template::Ex;

our $VERSION = q$0.04$;
our $REVISION= q$Id: base.cgi,v 1.2 2005/07/21 16:12:28 Lushe Exp $;

sub REVISION { $REVISION }
sub eucConv  { defined($_[1]) ? Jcode->new($_[1])->euc: "" }
sub cgi { $_[0]->{cgi} }

sub run {
	my($class, $conf, $apr)= @_;
	my $base= bless $conf, $class;
	my $cgi = $base->{cgi}= CGI->new($apr);
	$base->{options}{encoder}
	  and $base->{options}{encoder}= sub { $base->eucConv(@_) };
	my($path, $file);
	$conf->{___ApacheHandler} ? do {
		($path, $file)= $base->pathCuter($ENV{REQUEST_URI});
	 }: do {
		($path, $file)=
		 $cgi->param('path') ? $base->pathCuter($cgi->param('path')):
		 ($ENV{QUERY_STRING} && $ENV{QUERY_STRING}=~/^([^\&\;]+)/)
		 ? $base->pathCuter($1): ('/', $base->{indexName});
	 };
	$file=~s{\.htm$} [.html];
	(-e "$base->{VRsite}$path$file" && -f _)
	 ? do { $base->execute($cgi, $path, $file) }
	 : do { print $cgi->header. q{<h1>404 File Not Found.</h1>} };
}
sub execute {
	my($base, $cgi, $path, $file)= @_;
	my $send= $base->{deflateOk} ? \&sendContent: \&sendContent;
	$base->{currentPage}= "$path$file";
	$base->{rewrite} ? do {
		$base->{baseRoot}  = $base->{siteRoot};
		$base->{currentUri}= $base->{currentPage};
	 }: do {
		$base->{baseRoot}  = "$base->{cgiPath}?$base->{siteRoot}";
		$base->{currentUri}= "$base->{cgiPath}?$base->{currentPage}";
	 };
	my $Vars= $cgi->Vars;
	while (my($name, $value)= each %$Vars) {
		$value=~tr/\t/ /;
		$value=~s{\r\n?} [\n]sg;
		$Vars->{$name}= $base->eucConv($value);
	}
	my @path= ("$base->{VRsite}$path", @{$base->{options}{path}});
	my %options= %{$base->{options}};
	$options{path}     = \@path;
	$options{filename} = $file;
	$options{associate}= [$cgi];
	my $tmpl;
	eval{ $tmpl= HTML::Template::Ex->new($base, \%options) };
	$@ ? do {
		$cgi->charset($base->{charset});
		print $cgi->header, "Internal Server Error: $@";
	 }: do {
		$base->{sendCharset}= $tmpl->charset || $base->{charset};
		$cgi->charset($base->{sendCharset});
		$tmpl->param({
		 title=> $base->{title},
		 cgiPath => $base->{cgiPath},
		 baseRoot=> $base->{baseRoot},
		 siteRoot=> $base->{siteRoot},
		 currentUri    => $base->{currentUri},
		 currentPage   => $base->{currentPage},
		 scriptVersion => sub { $base->scriptVersion },
		 supportURL    => 'http://exbase.luuu.net/',
		 publishCharset => $base->{sendCharset},
		 publishLanguage=> $base->{language},
		 });
		$send->($base, $cgi, $tmpl);
	 };
}
sub sendContent {
	my($base, $cgi, $tmpl)= @_;
	my $code= $base->{convCodes}{lc($base->{sendCharset})}
	|| do { return print $cgi->header, $tmpl->output };
	print $cgi->header, Jcode->new($tmpl->output, 'euc')->$code;
}
sub sendDeflateContent {
}
sub fileOpen {
	my $base= shift;
	my $file= shift || return 0;
	FileHandle->new($file) || 0;
}
sub pathCuter {
	my $base= shift;
	my $path= shift || return ("/", $base->{indexName});
	$path=~s/\?.+//;
	my($dir, $file)=
	  $path=~m{^(/.*?)([^/]+)$} ? ($1, $2): ($path, $base->{indexName});
	(($dir || '/'), $file);
}
sub scriptVersion { $REVISION=~/v\s+([\.\d]+)/; __PACKAGE__." V$1" }

1;

