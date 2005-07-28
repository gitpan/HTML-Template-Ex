#!/usr/bin/perl -w
package ExBase;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# Usage:
#
#  http://myhost/cgi-bin/base.cgi
#    or
#  http://myhost/cgi-bin/base.cgi?/index.html
#
# * The file under the control of $C{VRsite} is processed by this as a template.
#
# $Id: base.cgi,v 1.3 2005/07/28 09:55:17 Lushe Exp $
#
use strict;
use lib qw(/home/exbase2/lib);
use ExBase::Core;

my $Prefix  = '/home/exbase2';
my $VRsite  = '/home/exbase2/vrsite';

# Please keep effective when you set mod_rewrite of $Prefix/apache/example-httpd.conf.
my $ReWrite = 0;
#

my %ConvertCodes= (
 'utf-8'      => 'utf8',
 'shift_jis'  => 'sjis',
 'x-sjis'     => 'sjis',
 'jis'        => 'jis',
 'iso-2022-jp'=> 'jis',
 );

my %C= (
 title    => __PACKAGE__,
 language => 'ja',
 charset  => 'euc-jp',
 siteRoot => '/',
 cgiPath  => '/base.cgi',
 indexName=> 'index.html',
 options  => {
#  encoder=> 1,
  path=> ["$Prefix/plugins", "$Prefix/template"],
  },
 convCodes=> \%ConvertCodes,
 prefix   => $Prefix,
 VRsite   => $VRsite,
 rewrite  => $ReWrite,
 );
my $apr= shift || undef;
$apr= undef; ## It might have to be 'undef' for mod_perl2.
ExBase::Core->run(\%C, $apr);

1;

#-------------------------------------------------------------------------------

=pod

=head1 NAME

ExBase - It is CGI sample that used HTML::Template::Ex.


=head1 
=head1 NOTES

The latest version of this script can be downloaded from the following site. 

http://exbase.luuu.net/


=head1 COPYRIGHT

Copyright 2004 Bee Flag, Corp. <L<http://beeflag.com/>>, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.


=head1 AUTHOR

Masatoshi Mizuno, <mizunoE<64>beeflagE<46>com>


=cut
