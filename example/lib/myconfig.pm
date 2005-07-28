package myconfig;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: myconfig.pm,v 1.2 2005/07/28 09:55:12 Lushe Exp $
#
use strict;

my $Prefix= '/home/exbase';
my $VRsite= "$Prefix/vrsite";

my %ConvertCodes= (
 'utf-8'      => 'utf8',
 'shift_jis'  => 'sjis',
 'x-sjis'     => 'sjis',
 'jis'        => 'jis',
 'iso-2022-jp'=> 'jis',
 );

my %C= (
 language => 'ja',
 charset  => 'euc-jp',
 title    => 'ExBase',
 siteRoot => '/',
 indexName=> 'index.html',
 options  => {
#  encoder=> 1,
  cache=> 1,
  path => ["$Prefix/plugins", "$Prefix/template"],
  },
 deflateOk  => 0,
 deflateSize=> 2048,
 #
 prefix   => $Prefix,
 VRsite   => $VRsite,
 convCodes=> \%ConvertCodes,
 );

sub config { \%C }

1;


