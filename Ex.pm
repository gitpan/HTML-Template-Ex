package HTML::Template::Ex;
#
# Copyright 2004 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@beeflag.com>
#
# $Id: FormField.pm,v 1.11 2004/08/16 00:32:33 Lushe Exp $
#
use 5.004;
use strict;
# use warnings;
use base qw(HTML::Template);
use Carp qw(croak);

our $VERSION = '0.01';

my $ErrstrStyle= q{background:#000; color:#FFF; font-size:13px;};
sub initStyle { $ErrstrStyle= $_[1] }

sub new {
	my $class= shift;
	my $base = shift || HTML::Template::Ex::DummyObject->new;
	my $opt= shift || croak __PACKAGE__.'::new: There is no argument.';
	my %opt= ref($opt) eq 'HASH'
	 ? %$opt
	 : croak __PACKAGE__.'::new: Argument is not a HASH reference.';
	##
	$opt{cache}= 0; ## Because it has not corresponded to the 'cache' mode yet.
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
	my($self, %param, %temp);
	$opt{_ex_params}= \%param;
	$opt->{setup_env} and do {
		for my $key (keys %ENV)
		{ $param{"env_$key"}= sub { $ENV{$key} || "" } }
	 };
	my $filter= $opt{exec_off}
	 ? sub { &_offFilter(\%param, @_) }
	 : sub { &_exFilter($base, \%param, \%temp, @_) };
	push @{$opt{filter}}, { format=> 'scalar', sub=> $filter };
	eval{ $self= HTML::Template::new($class, %opt) };
	$@ ? croak $@: $self;
}
sub output {
	$_[0]->{options}{_ex_params}
	  and HTML::Template::param($_[0], $_[0]->{options}{_ex_params});
	HTML::Template::output(@_);
}
sub _exFilter {
	my($base, $param, $temp, $text)= @_;
	$$text=~s{<tmpl_ex(\s+[^>]+\s*)?>(.+?)</tmpl_ex[^>]*>}
	         [&_replaceEx($base, $2, $1, $param, $temp)]isge;
	$$text=~m{(?:<tmpl_ex[^>]*>|</tmpl_ex[^>]*>)}
	  and croak q{At least one <TMPL_EX> not terminated at end of file!};
	$$text=~s{<tmpl_set([^>]+)>} [&_replaceSet($1, $param)]isge;
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
	my($base, $code, $opt, $param, $temp)= @_;
	my($name, $hidden); my $escape= "";
	$opt and do {
		$opt=~/name=[\"\']?([^\s\"\']+)/   and $name  = lc($1);
		$opt=~/escape=[\"\']?([^\s\"\']+)/ and $escape= qq{ escape="$1"};
		$opt=~/hidden=[\"\']?([^\s\"\']+)/ and $hidden= 1;
	 };
	++$temp->{count};
	$name ||= "__execute$temp->{count}";
	eval{
		my $exec;
		eval"\$exec= sub { $code }";
		$param->{$name}= $exec->($base, $param) || "";
	 };
	($@ && $@=~/(.+)/) ? do {
		my $errstr= $1;
		$errstr=~s{ in use at .+?/HTML/Template/Ex.pm line \d+} [];
		return qq{<div style="$ErrstrStyle">}
		     . qq{ $errstr &lt;TMPL_EX($temp->{count})&gt;}
		     . qq{</div>};
	 }: do {
		return (ref($param->{$name}) eq 'ARRAY' || $hidden)
		  ? "": qq{<tmpl_var name="$name"$escape>};
	 };
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
    <tmpl_loop><div>name: <tmpl_var name="name"></div></tmpl_loop>

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

=back

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
    cache, is being compulsorily invalidated now. 

=item *

B<A>bout order by which EX-Code is evaluated.

Though it is sequentially evaluated on usually. The priority level lowers more than EX-Code in the template that is included, and read mainly described when included as for <tmpl_include *NAME>.

B<Example of template(1).>
    <div><tmpl_ex> "tmpl-1: ". ++$_[0]->{mycount} </tmpl_ex></div>
    <tmpl_include name="template(2)">
    <div><tmpl_ex> "tmpl-2: ". ++$_[0]->{mycount} </tmpl_ex></div>

B<Example of template(2).>

    <div><tmpl_ex> "inc-1: ". ++$_[0]->{mycount} </tmpl_ex></div>

B<When you do output.>

    <div>tmpl-1: 1</div>
    <div>inc-1: 3</div>
    <div>tmpl-2: 2</div>

=item *

B<s>trict code is demanded EX-Code.  Otherwise, the error is output or even if the error is not output, the record will remain in the error log of HTTPD. 

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
