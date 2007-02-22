use inc::Module::Install;
name 'HTML-Template-Ex';
author 'Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>';
all_from 'lib/HTML/Template/Ex.pm';
version_from 'lib/HTML/Template/Ex.pm';

requires 'HTML::Template';
requires 'HTML::Entities';
requires 'Digest::MD5';
requires 'Devel::StackTrace';

build_requires 'Test::More';
build_requires 'Test::Pod';

use_test_base;
auto_include;
WriteAll;
