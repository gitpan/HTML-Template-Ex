package HTML::Template::Ex;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: Ex.pm,v 1.2 2005/07/26 19:39:35 Lushe Exp $
#
use 5.004;
use strict;
# use warnings;
use base qw(HTML::Template);
use Digest::MD5 qw(md5_hex);
use Carp qw(croak);

our $VERSION = '0.03';

my $GetCharSetRegix=
 q{<meta.+?content=[\'\"]text/html\s*\;\s*charset=([A-Za-z0-9\-_]+)[\'\"].*?/?\s*>};

my $ErrstrStyle= q{background:#000; color:#FFF; font-size:13px;};
sub initStyle { $ErrstrStyle= $_[1] }

sub new {
	my $class= shift;
	my $base = shift || HTML::Template::Ex::DummyObject->new;
	my $opt  = shift || croak __PACKAGE__.'::new: There is no argument.';
	my %opt  = ref($opt) eq 'HASH'
	 ? %$opt
	 : croak __PACKAGE__.'::new: Argument is not a HASH reference.';
	##
	$opt{global_vars}= 1;
	$opt{die_on_bad_params}= $opt{strict}= $opt{file_cache}= $opt{shared_cache}= 0;
	##
	exists($opt{filter}) and do {
		ref($opt{filter}) eq 'CODE'
		 ? do { $opt{filter}= [{ format=> 'scalar', sub=> $opt{filter} }] }:
		ref($opt{filter}) eq 'HASH'
		 ? do { $opt{filter}= [$opt{filter}] }:
		ref($opt{filter}) ne 'ARRAY'
		 ? do { croak __PACKAGE__.q{::new: Bad format for 'filter'} }
		 : do {};
	 };
	my($self, %param, %mark, %order, %temp);
	$opt{_ex_params}= \%param;
	$opt{_ex_orders}= \%order;
	$opt{_ex_mark}  = \%mark;
	$opt{setup_env} and do {
		for my $key (keys %ENV)
		{ $param{"env_$key"}= sub { $ENV{$key} || "" } }
	 };
	$opt{_ex_ident}= substr(md5_hex(time(). {}. rand()), 0, 32);
	$opt{_ex_base_object}= $base;
	my $filter= $opt{exec_off}
	 ? sub { &_offFilter(\%param, @_) }
	 : sub { &_exFilter($base, \%opt, \%temp, @_) };
	push @{$opt{filter}}, { format=> 'scalar', sub=> $filter };
	eval{ $self= HTML::Template::new($class, %opt) };
	$@ and croak $@;
	$opt{cache} and $self->{_ex_charset}= pop @{$self->{parse_stack}} || "";
	$self;
}
sub output {
	my($self)= @_;
	my $parse_stack= $self->{parse_stack};
	my $param_map  = $self->{param_map};
	my $options    = $self->{options};
	my($ex_mark, $ex_param, $ex_order);
	$options->{cache} ? do {
		$ex_mark = pop @$parse_stack;
		$ex_param= pop @$parse_stack;
		$ex_order= pop @$parse_stack;
	 }: do {
		$ex_mark = $options->{_ex_mark}   || {};
		$ex_param= $options->{_ex_params} || {};
		$ex_order= $options->{_ex_orders} || {};
	 };
	$self->param($ex_mark);
	my $base = $options->{_ex_base_object};
	my %param= %$ex_param;
	my $cnt;
	for my $v (@$parse_stack) {
		ref($v) eq 'HTML::Template::VAR' and do {
			my $hash= $ex_order->{$$v} || next;
			++$cnt;
			my $result;
			eval{ $result= $hash->{function}->($base, \%param) };
			($@ && $@=~/(.+)/) ? do {
				my $errstr= $1;
				$errstr=~s{\s+in use at .+?/HTML/Template/Ex.pm line \d+} [];
				$errstr=~s{\s+<GEN0> line \d+\.\s*} []i;
				$errstr=~s{\s+\(eval \d+\)} []i;
				$param{$$v}= qq{<div style="$ErrstrStyle">}
				.  &_escape_html($errstr). qq{ from &lt;TMPL_EX($cnt)&gt;</div>};
			 }: do {
				ref($result) eq 'ARRAY' ? do {
					$param{$$v}= "";
					$hash->{key_name} and $param{$hash->{key_name}}= $result;
				 }: do {
					$param{$$v}= $hash->{hidden} ? "": ($result || "");
					$hash->{key_name} and $param{$hash->{key_name}}= $result;
				 };
			 };
		 };
	}
	HTML::Template::param($self, \%param);
	my $result= HTML::Template::output(@_);
	$options->{cache} and do {
		push @$parse_stack, $ex_order;
		push @$parse_stack, $ex_param;
		push @$parse_stack, $ex_mark;
		push @$parse_stack, ($self->{_ex_charset} || "");
	 };
	$result;
}
sub charset { $_[0]->{_ex_charset} || "" }

sub _escape_html {
	local($_)= @_;
	# straight from the CGI.pm bible.
	s/&/&amp;/g;
	s/\"/&quot;/g; #"
	s/>/&gt;/g;
	s/</&lt;/g;
	s/'/&#39;/g; #'
	$_;
}
sub _call_filters {
	my($self, $html)= @_;
	$self->{options}{encoder} and $self->{options}{encoder}->($html);
	$$html=~m{$GetCharSetRegix}i and $self->{_ex_charset}= $1;
	HTML::Template::_call_filters(@_);
}
sub _exFilter {
	my($base, $opt, $temp, $text)= @_;
	$$text=~s{<tmpl_ex(\s+[^>]+\s*)?>(.+?)</tmpl_ex[^>]*>}
	         [&_replaceEx($1, $2, $base, $opt, $temp)]isge;
	$$text=~m{(?:<tmpl_ex[^>]*>|</tmpl_ex[^>]*>)}
	  and croak q{At least one <TMPL_EX> not terminated at end of file!};
	$$text=~s{<tmpl_set([^>]+)>} [&_replaceSet($1, $opt->{_ex_params})]isge;
}
sub _offFilter {
	my($param, $text)= @_;
	$$text=~s{<tmpl_ex\s+[^>]+\s*?>.+?</tmpl_ex[^>]*>} []isg;
	$$text=~s{(?:<tmpl_ex[^>]*>|</tmpl_ex[^>]*>)} []isg;
	$$text=~s{<tmpl_set([^>]+)>} [&_replaceSet($1, $param)]isge;
}
sub _replaceSet {
	my $opt  = shift || return "[ tmpl_set Error!! ]";
	my $param= shift || return "[ tmpl_set Error!! ]";
	my $name = ($opt=~/name=\s*[\'\"]?([^\s\'\"]+)/)[0]
	        || return "[ tmpl_set Error!! ]";
	my $value= ($opt=~/value=\s*[\'\"](.+?)[\'\"]/)[0]
	        || ($opt=~/value=\s*([^\s]+)/)[0]
	        || return "[ tmpl_set Error!! ('$name') ]";
	$value and $param->{$name}= $value;
	"";
}
sub _replaceEx {
	my($tag, $code, $base, $opt, $temp)= @_;
	my($exec, %attr);
	my $escape= my $default= "";
	$tag and do {
		$tag=~/name=[\"\']?([^\s\"\']+)/    and $attr{key_name}= lc($1);
		$tag=~/hidden=[\"\']?([^\s\"\']+)/  and $attr{hidden}= 1;
		$tag=~/escape=[\"\']?([^\s\"\']+)/  and $escape = qq{ escape="$1"};
		$tag=~/default=[\"\']?([^\s\"\']+)/ and $default= qq{ default="$1"};
	 };
	my $ident= qq{__\$ex_$opt->{_ex_ident}\$}. (++$temp->{count}). q{$__};
	eval"\$exec= sub { $code }";
	$attr{function}= sub { $exec->(@_) || "" };
	$opt->{_ex_orders}{$ident}= \%attr;
	$opt->{_ex_mark}{$ident}  = $ident;
	qq{<tmpl_var name="$ident"$escape$default>};
}
sub _commit_to_cache {
	my($self)= @_;
	push @{$self->{parse_stack}}, $self->{options}{_ex_orders};
	push @{$self->{parse_stack}}, $self->{options}{_ex_params};
	push @{$self->{parse_stack}}, $self->{options}{_ex_mark};
	push @{$self->{parse_stack}}, ($self->{_ex_charset} || "");
	HTML::Template::_commit_to_cache(@_);
}

package HTML::Template::Ex::DummyObject;
sub new { bless {}, shift }


1;

__END__


=head1 NAME

 HTML::Template::Ex - The Perl code is executed in HTML::Template.


=head1 SYNOPSIS

 package MyProject;
 use CGI;
 use Jcode;
 use HTML::Template::Ex;

 my $cgi = CGI->new;
 my $self= bless { cgi=> cgi }, __PACKAGE__;

 my $template= <<END_OF_TEMPLATE;
 <html>
 <head><title><tmpl_var name="title"></title></head>
 <body>
 <tmpl_set name="title" value="HTML::Template::Ex">

 <h1><tmpl_var name="page_title"></h1>

 <div style="margin:10; background:#DDD;">
 <tmpl_ex>
   my($self, $param)= @_;
   $param->{page_title}= 'My Page Title';
   return $self->{cgi}->param('name') || 'It doesn't receive it.';
 </tmpl_ex>
 </div>

 <div style="margin:10; background:#DDD;">
 <tmpl_loop name="users">
  <div>
  <tmpl_var name="u_name" escape="html">
  : <tmpl_var name="email" escape="html">
   </div>
 </tmpl_loop>
 </div>

 <tmpl_ex name="users">
   return [
    { u_name=> 'foo', email=> 'foo@mydomain'    },
    { u_name=> 'boo', email=> 'boo@localdomain' },
    ];
 </tmpl_ex>

 <tmpl_var name="env_remote_addr">

 <body></html>
 END_OF_TEMPLATE

 my $tmpl= HTML::Template::Ex->new($self, {
  setup_env=> 1,
  scalarref=> \$template,
  encoder  => sub { Jcode->new($_[0])->euc },
  # ... other 'HTML::Template' options.
  });

 print STDOUT $cgi->header, $tmpl->output;


=head1 DESCRIPTION

=head2 <tmpl_ex> ... </tmpl_ex> (EX-Code)

B<T>he character string enclosed with <tmpl_ex> ... </tmpl_ex> (Hereafter, it is written as EX-Code) is evaluated as Perl code and executed.

=over 4

=item *

B<T>he HASH reference for the definition of the parameter of the object and the template of the first argument given to the constructor of HTML::Template::Ex is passed to the code. 
The value substituted for the HASH for the parameter definition can be referred to by using <tmpl_var *NAME>.

B<Example of template.>

  <tmpl_ex>
    my($self, $param)= @_;
    $param->{banban}= '<b>banban</b>';
    "My Object = ". ref($self)
  </tmpl_ex>
  --- <tmpl_var name="banban"> ---

B<When you do output.>

  My Object = *OBJECT-NAME
  --- <b>banban</b> ---

=item *

B<I>f the return value of the code is an array and doesn't exist, <tmpl_var *NAME> to bury the return value under the position is put.

B<Example of template.>

  <tmpl_ex> "<h1>result string.</h1>"; </tmpl_ex>

B<When you do output.>

  <h1>result string.</h1>

=item *

B<T>he name of the variable for which the return value of the code is substituted can be specified. 
B<P>lease use and refer to <tmpl_var *NAME> for the substituted value.

B<Example of template.>

  <tmpl_ex name="foge"> "<b>result string.</b>"; </tmpl_ex>
  --- <tmpl_var name="foge"> ---

B<When you do output.>

  <b>result string.</b>
  --- <b>result string.</b> ---

=item *

B<W>hen the thing that the return value is buried under the position is not hoped as stated above, the hidden option is made effective. 

B<Example of template.>

  <tmpl_ex name="foge" hidden="1"> "<b>result string.</b>"; </tmpl_ex>
  --- <tmpl_var name="foge"> ---

B<When you do output.>

  --- <b>result string.</b> ---

=item *

B<W>hen the code returns the ARRAY reference, it substitutes for the parameter specified by the name option and it ends.
B<P>lease use and refer to <tmpl_loop *NAME> for this value. 

B<Example of template.>

  <tmpl_ex name="array">
    my @array= ({ name=> 'name1' }, { name=> 'name2' });
    return \@array;
  </tmpl>
  <tmpl_loop name="array"><div>name: <tmpl_var name="name"></div></tmpl_loop>

B<When you do output.>

  <div>name: name1</div>
  <div>name: name2</div>

=item *

B<T>he escape option to hand to HTML::Template to output it after it escapes in the return value of the code can be specified.

B<Example of template.>

  <tmpl_ex escape="html"> "<h1>result string.</h1>"; </tmpl_ex>

B<When you do output.>

  &lt;result string.&gt;

=back

=head2 <tmpl_set name='...' value='...'>

=over 4

=item *

B<T>he parameter value of the template inside can be set with <tmpl_set name='...' value='...'>.

B<Example of template.>

  <tmpl_set name="page_title" value="my page title">
  <h1><tmpl_var name="page_title"></h1>

B<When you do output.>

  <h1>my page title</h1>

=back

=head2 <tmpl_var name='env_*[ Environment variable name. ]'>

=over 4

=item *

B<T>he parameter to call the environment variable when the setup_env option is made effective when the constructor is called is prepared.
 To refer to the prepared value, the name of the environment variable that wants to refer following env_ is specified.

B<Example of template.>

  <div>HTTP_REFERER: <tmpl_var name="env_http_referer"></div>
  <div>REMOTE_ADDR : <tmpl_var name="env_remote_addr"></div>

B<When you do output.>

  <div>HTTP_REFERER: http://....... </div>
  <div>REMOTE_ADDR : 0.0.0.0</div>

=back


=head1 METHOD

=head2 new

=over 4

=item *

B<I>t is a constructor. 
B<P>lease pass in the first argument and pass the option to a suitable object and the second argument with HAHS reference.

B<Example of code.>

  my $self= bless {}, __PACKAGE__;
  my $ex= HTML::Template::Ex
          -> new ($self, { filename=> 'foooo.tmpl', setup_env=> 1 });

=back

=head3 Parameter of option

=over 4

=item *

B<A>nother for HTML::Template can specify the option to evaluate to following original HTML::Template::Ex in the option.

Z<>

=over 4

=item *

B<setup_env>

... It is made to prepare of refer to the environment variable with <tmpl_var *NAME>.

=item *

B<exec_off>

... To invalidate EX-Code temporarily, it keeps effective.

B<encoder>

... The CODE reference to keep the character-code of the template to be constant can be defined.

* When the template made from a different character-code exists together, it finds it useful.

=back

=back

=head2 charset

=over 4

=item *

The value can be referred to when charset can be acquired from <meta ... content="text/html; charset=[Character set]"> in the template read. 

=back

=head2 other

=over 4

=item *

B<O>ther methods succeed the one of HTML::Template.

Please refer to the document of HTML::Template for details.

=back


=head1 NOTES

=over 4

=item *

B<A>bout the option to give to the constructor.

global_vars, compulsorily becomes effective.
die_on_bad_params, strict, file_cache, shared_cache, compulsorily becomes invalid.
It came to be able to specify cache from v0.03.

=item *

B<A>bout order by which EX-Code is evaluated.

This problem had been improved from v0.03 before though the processing order became complex when <TMPL_INCLUDE *NAME> existed.

Processing is done in order of <TMPL_EX>'s appearing regardless of the presence of <TMPL_INCLUDE *NAME>.

=item *

B<S>trict code is demanded EX-Code.  Otherwise, the error is output or even if the error is not output, the record will remain in the error log of HTTPD. 

=item *

B<T>here is no restriction in the Perl code that can be written in EX-Code.
B<T>here is a possibility of causing an unpleasant situation because anything passes. 
B<W>hen the code that especially accepts the input from the visitor is written, close attention is necessary for the user.
B<M>oreover, please do not write the code that does exit on the way. Because it doesn't understand what happens....
B<L>et's have it not put on the place where the template is seen from WEB though it is a thing that not is to saying as it....

=back


=head1 WARNING

This module aims only at convenience, is made, and the thing concerning security is not considered. 
Please give enough security countermeasures on the project code side when actually using it. 


=head1 BUGS

When you find a bug, please email me (L<mizunoE<64>beeflag.com>) with a light heart.


=head1 SEE ALSO

L<HTML::Template>.


=head1 COPYRIGHT

Copyright 2005 Bee Flag, Corp. <L<http://beeflag.com/>>, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.


=head1 AUTHOR

Masatoshi Mizuno, <mizunoE<64>beeflagE<46>com>

=cut
