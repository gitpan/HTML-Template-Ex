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
# $Id: base.cgi,v 1.2 2005/07/26 19:46:03 Lushe Exp $
#
use strict;
use lib qw(/home/exbase/lib);
use ExBase::Core;

my $Prefix  = '/home/exbase';
my $VRsite  = '/home/exbase/vrsite';

# Please keep effective when you set mod_rewrite of $Prefix/apache/example-httpd.conf.
my $ReWrite = 0;
#

my %C= (
 charset  => 'euc-jp',
 title    => __PACKAGE__,
 cgiPath  => '/base.cgi',
 siteRoot => '/',
 prefix   => $Prefix,
 VRsite   => $VRsite,
 rewrite  => $ReWrite,
 indexName=> 'index.html',
 deflateOk  => 0,
 deflateSize=> 2048,
 options  => {
  path=> ["$Prefix/plugins", "$Prefix/template"],
  },
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
