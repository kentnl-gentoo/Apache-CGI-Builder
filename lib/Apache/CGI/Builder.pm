package Apache::CGI::Builder ;
$VERSION = 1.2 ;

; use strict
; $Carp::Internal{+__PACKAGE__}++
; use mod_perl
; use constant MP2 => $mod_perl::VERSION >= 1.99
; our $usage = qq(Apache::CGI::Builder should be used INSTEAD of CGI::Builder )
             . qq(and should not be included as an extension)

; BEGIN
   { require File::Basename
   ; if ( MP2 )
      { require Apache::RequestRec
      ; require Apache::Response
      ; require Apache::Const
      ; Apache::Const->import( -compile => 'OK' )
      ; *handler = sub : method
                    { shift()->Apache::CGI::Builder::_::process(@_)
                    }
      }
     else
      { require Apache::Constants
      ; Apache::Constants->import( 'OK' )
      ; *handler = sub ($$)
                    { shift()->Apache::CGI::Builder::_::process(@_)
                    }
      }
   }
   
; sub import
   { undef $usage
   ; require CGI::Builder
   ; unshift @_, 'CGI::Builder'
   ; goto &CGI::Builder::import
   }

; use Class::props
        { name       => 'no_page_content_status'
        , default    => '404 Not Found'
        }

; use Object::props
      ( { name     => 'r'
        , allowed  => qr/^Apache::CGI::Builder::_::process$/
        }
      )

; sub Apache::CGI::Builder::_::process
   { my ($s, $r) = @_
   ; my ( $PN
        , $path
        , $sfx
        )
        = File::Basename::fileparse( $r->filename
                                   , qr/\.[^.]+$/
                                   )
   ; $s = $s->new( page_path   => $path
                 , page_name   => $PN
                 , page_suffix => $sfx
                 , r           => $r
                 ) unless ref $s
   ; $s->process()
   ; MP2 ? Apache::OK : Apache::Constants::OK
   }

; 1


__END__

=head1 NAME

Apache::CGI::Builder - CGI::Builder and Apache/mod_perl integration

=head1 VERSION 1.2

The latest versions changes are reported in the F<Changes> file in this distribution. To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    Apache/mod_perl 1 or 2
    CGI::Builder >= 1.2

=item CPAN

    perl -MCPAN -e 'install Apache::CGI::Builder'

If you want to install all the extensions and prerequisites of the CBF, all in one easy step:

    perl -MCPAN -e 'install Bundle::CGI::Builder::Complete'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

   # use instead of the CGI::Builder
   use Apache::CGI::Builder
   qw| ... other inclusions ...
     |;
   
   # deprecated way of inclusion still working
   use CGI::Builder
   qw| Apache::CGI::Builder
       ... other inclusions ...
     |;
   
   # direct interaction with the Apache request object
   $r = $self->r ;
   %headers = $self->r->headers_in ;
   
   # virtual pages: instead of using this
   http://www.yourdomain.com/cgi-bin/IScript.cgi?p=a_page
   
   # you can use this
   http://www.yourdomain.com/a_page

=head1 DESCRIPTION

This module is a subclass of C<CGI::Builder> that supply a perl handler to integrate your CBB with the Apache/mod_perl server.

You should use this module B<instead of CGI::Builder> if your application can take advantage from accessing the Apache request object (available as the C<r> property), and/or to run your application in a handy and alternative way. If you don't need any of the above features, you can use the C<CGI::Builder> module that is however fully mod_perl 1 and 2 compatible.

B<Note>: most of the interesting reading about how to organize your application module are in L<CGI::Builder>.

B<Note>: An extremely powerful combination with this extension is the L<CGI::Builder::Magic|CGI::Builder::Magic>, that can easily implement a sort of L<Perl Side Include|CGI::Builder::Magic/"Perl Side Include"> (sort of easier, more powerful and flexible "Server Side Include").

=head2 No Instance Script needed

A regular CGI::Builder application, uses an Instance Script to make an instance of the CBB. With C<Apache::CGI::Builder> the Apache/mod_perl server uses the CBB directly (throug the perl handler supplied by this module), without the need of any Instance Script.

=head2 The Perl Handler

This module provide a mod_perl 1 and 2 compatible handler that internally creates the CBB object and produce the output page, after setting the following properties:

=over

=item * r

This property is set to the Apache request object. Use it to interact directly with all the Apache/mod_perl internal methods.

=item * page_name

The default page_name is set to the base name of the requested filename (e.g. being the requested filename F</path/to/file.mhtml>, the default page_name will be set to 'file'). This is an alternative and handy way to avoid to pass the page_name with the query.

=item * page_path

The default C<page_path> property is set to the directory that contains the requested file.

=item * page_suffix

The default C<page_suffix> property is set to the suffix of the requested filename (e.g. being the requested filename F</path/to/file.mhtml>, the default page_suffix will be set to '.mhtml').

=back

B<Note>: Usually you don't need to use neither the perl handler nor these properties, because they are all internally managed.

=head3 How to pass the page_name

In a regular CBA the page_name usually comes from a query parameter or from code inside your application (if you have overridden the get_page_name() method). Both ways are still working with this extension, but you have another way: use the base filename of your links as the page_name.

E.g.: Providing that the RootDirectory of C<'yourdomain.com'> has been correctly configured to be handled by your CBB:

Instead of using this (good for any regular CBA):

    http://www.yourdomain.com/cgi-bin/IScript.pl?p=a_page

You can use this:

    http://www.yourdomain.com/a_page

Same thing with more query parameters:

    http://www.yourdomain.com/cgi-bin/IScript.pl?p=a_page&myField=aValue
    http://www.yourdomain.com/a_page?myField=aValue

B<Note>: Remember that this technique utilize the default page_name. Default means that it is overridable by setting explicitly the page_name inside your code, or passing an explicit 'p' query parameter. (i.e. if you want to use the provided default, you have just to avoid to set it explicitly).

B<Warning>: This extension sets the C<page_name> property to the basename of the Apache filename variable, which is the result of the C<< URI -> filename >> translation. For this reason, on some systems, the C<page_name> could be not exactly the basename of the requested URI, and it could result in a string composed by all small caps characters, even if the requested URI was composed by all upper caps characters.

For example this URI:

    http:://www.yourdomain.com/aPage.html

could generate a C<page_name> equal to 'apage' which probably does not match with your C<SH_aPage> C<PH_aPage> handlers, so in order to avoid possible problems, I would suggest the most simple and compatible solution, which is: always use all small caps for page names, templates names, page and switch handlers, URLs, ...

=head2 Apache configuration

The Apache configuration for mod-perl 1 or 2 is extremely simple. In order to use e.g. your F<FooBar.pm> CBB, you have to follow these steps:

=over

=item 1 tell mod_perl to load FooBar.pm

You can do this in several ways.

In the F<startup.pl> file (or equivalent) you can simply add:

    use FooBar () ;

or you can tell mod_perl to load it from inside any configuration files:

    PerlModule FooBar

or if your F<FooBar.pm> file is not in the mod_perl C<@INC> this will work as well from any Apache configuration file:

   PerlRequire /path/to/FooBar.pm

=item 2 tell mod_perl to use it as a (response) handler

In F<.htaccess> file

For mod_perl 1:

    SetHandler perl-script
    PerlHandler FooBar

For mod_perl 2:

    SetHandler perl-script
    PerlResponseHandler FooBar

B<Note>: In order to use this extension, the only difference between mod_perl 1 and 2 configuration, is the mod_perl handler name C<'PerlHandler'> that becomes C<'PerlResponseHandler'> for the version 2.

=item 3 restrict its use to fit your needs

Use the Apache configuration sections C<Location>, C<Directory>, C<DirectoryMatch>, C<Files>, C<FilesMatch> etc. to restrict the use of the handler (see also the Apache Directive documentation)

   # example 1: httpd.conf
   # only if runs under mod_perl
   <IfModule mod_perl.c>
        PerlModule FooBar
        # limited to the dir /some/path
        <Directory /some/path>
            SetHandler perl-script
            PerlHandler FooBar
        </Directory>
   </IfModule>

   # example 2: /some/path/.htaccess file
   # only if runs under mod_perl
   <IfModule mod_perl.c>
        PerlModule FooBar
        SetHandler perl-script
        PerlHandler FooBar
   </IfModule>

=back

B<Note>: see also the F</magic_examples/perl_side_include/.htaccess> file in this distribution.

=head2 Useful links

=over

=item *

A simple and useful navigation system between the various CBF extensions is available at this URL: http://perl.4pro.net

=item *

More practical topics are probably discussed in the mailing list at this URL: http://lists.sourceforge.net/lists/listinfo/cgi-builder-users

=back

=head1 PROPERTY ACCESSORS

This module adds just one property to the standard C<CGI::Builder> properties.

=head2 r

This property allows you to access the request Apache object.

=head1 CBF overridden properties

=head2 no_page_content_status

This extension overrides this class property by just changing the '204 No Content' (that the CBF sets when no page_content has been produced by the process), with a more consistent '404 Not Found' status. It does so because the client is requesting a simple not found page, which is a very different situation from a found CGI script that does not send any content (204 No Content).

=head1 SUPPORT

Support for all the modules of the CBF is via the mailing list. The list is used for general support on the use of the CBF, announcements, bug reports, patches, suggestions for improvements or new features. The API to the CBF is stable, but if you use the CBF in a production environment, it's probably a good idea to keep a watch on the list.

You can join the CBF mailing list at this url:

http://lists.sourceforge.net/lists/listinfo/cgi-builder-users

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (http://perl.4pro.net)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

