package ExBase::ApacheHandler;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: Ex.pm,v 1.1 2005/07/21 15:13:10 Lushe Exp $
#
use strict;
use ExBase::Core;

my $Config= 'myconfig';

sub handler {
	my($r)= @_;
	my $config= $r->dir_config->{ExConfig} || $Config;
	eval"require $config";
	my %option= %{$config->config};
	$option{cgiPath}= '/base.cgi';
	$option{rewrite}= $option{___ApacheHandler}= 1;
	ExBase::Core->run(\%option);
}

1;
