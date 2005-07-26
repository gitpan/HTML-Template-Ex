package ExBase::ApacheHandler;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: ApacheHandler.pm,v 1.1 2005/07/26 19:44:44 Lushe Exp $
#
use strict;
use ExBase::Core;

my $Prefix= '/home/exbase';
my $VRsite= '/home/exbase/vrsite';

sub handler {
	my($r)= @_;
	my $config= $r->dir_config;
	my %option= ();
	$config->{ExTemplateOption} and do {
		for (split /\s*\,\s*/, $config->{ExTemplateOption})
		{ /^([a-z_]+)\s*=>\s*([^\s]+)/ and $option{$1}= $2 }
	 };
	my @path= $config->{ExTemplatePath}
	 ? (split / +/, $config->{ExTemplatePath})
	 : ("$Prefix/plugins", "$Prefix/template");
	$option{path}= \@path;
	my %C= (
	 prefix   => $config->{ExPrefix}   || $Prefix,
	 VRsite   => $config->{ExHTdocs}   || $VRsite,
	 charset  => $config->{ExCharset}  || 'euc-jp',
	 title    => $config->{ExTitle}    || 'ExBase',
	 siteRoot => $config->{ExSiteRoot} || '/',
	 deflateOk  => $config->{ExDeflateOk}   || 0,
	 deflateSize=> $config->{ExDeflateSize} || 2048,
	 indexName=> 'index.html',
	 options  => \%option,
	 cgiPath  => '/base.cgi',
	 rewrite  => 1,
	 ___ApacheHandler=> 1,
	 );
	ExBase::Core->run(\%C);
}

1;


#	ref($Tpopt{path}) ne 'ARRAY' and $Tpopt{path}= [$Tpopt{path}];
