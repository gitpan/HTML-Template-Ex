use Module::Build;

my $builder = Module::Build->new(
  module_name => 'HTML::Template::Ex',
  license => 'perl',
  dist_author => 'Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>',
  dist_version_from=> 'lib/HTML/Template/Ex.pm',
  requires => {
    'HTML::Template'   => '2.9';
    'HTML::Entities'   => '3.5';
    'Digest::MD5'      => '2.3';
    'Devel::StackTrace'=> '1.1';
    'Test::More' => 0,
    'Test::Pod'  => 0,
    },
  );

$builder->create_build_script();
