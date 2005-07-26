package myconfig;
#
# $Id: myconfig.pm,v 1.1 2005/07/26 19:44:28 Lushe Exp $
#
use strict;

my $Prefix= '/home/exbase';
my $VRsite= "$Prefix/vrsite";

my %C= (
 language => 'ja',
 charset  => 'euc-jp',
 title    => 'ExBase',
 siteRoot => '/',
 indexName=> 'index.html',
 options  => {
  cache=> 1,
  path=> ["$Prefix/plugins", "$Prefix/template"],
  },
 deflateOk=> 0,
 deflateSize=> 2048,
 #
 prefix=> $Prefix,
 VRsite=> $VRsite,
 );

sub config { \%C }

1;
