#!perl -w
; package AA1
; use strict
; use Test::More tests => 2
; use CGI


; use CGI::Builder
  qw| Apache::CGI::Builder
    |

# index.tmpl
; my $ap1 = AA1->new()
; ok( $ap1->can('handler') )
; ok( AA1->can('handler') )
    



