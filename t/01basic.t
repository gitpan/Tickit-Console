#!/usr/bin/perl

use strict;

use Test::More tests => 12;
use Test::Refcount;

use Tickit::Test;

use String::Tagged;

use Tickit::Console;

my ( $term, $win ) = mk_term_and_window;

my $console = Tickit::Console->new;

ok( defined $console, 'defined $console' );

is_oneref( $console, '$console has refcount 1 initially' );

$console->set_window( $win );

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(23,0),
              SETBG(4),
              ERASECH(80),
              GOTO(24,0),
              SETBG(undef),
              ERASECH(80),
              GOTO(24,0) ],
            'Termlog initially' );

is_display( [ BLANKLINES(23),
              BLANKLINE(bg=>4),
              BLANKLINE() ],
            'Display initially' );

is_cursorpos( 24, 0, 'Cursor position initially' );

my $tab = $console->add_tab( name => "Tabname" );

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT("Tabname",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after ->add_tab' );

is_cursorpos( 24, 0, 'Cursor position after ->add_tab' );

$tab->add_line( "A line of content" );

flush_tickit;

is_display( [ [TEXT("A line of content")],
              BLANKLINES(22),
              [TEXT("Tabname",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after tab->add_line' );

is_cursorpos( 24, 0, 'Cursor position after tab->add_line' );

my $text = String::Tagged->new( "Content with formatting in it" );
$text->apply_tag(  0,  7, b => 1 );
$text->apply_tag( 13, 10, u => 1 );

$tab->add_line( $text );

flush_tickit;

is_display( [ [TEXT("A line of content")],
              [TEXT("Content",b=>1),TEXT(" with "),TEXT("formatting",u=>1),TEXT(" in it")],
              BLANKLINES(21),
              [TEXT("Tabname",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after tab->add_line tagged' );

$tab->add_line( "XXXX " x 20, indent => 4 );

flush_tickit;

is_display( [ [TEXT("A line of content")],
              [TEXT("Content",b=>1),TEXT(" with "),TEXT("formatting",u=>1),TEXT(" in it")],
              [TEXT("XXXX " x 16)],
              [TEXT("    "),TEXT("XXXX " x 4),TEXT("")],
              BLANKLINES(19),
              [TEXT("Tabname",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after tab->add_line with indent' );

is_oneref( $console, '$console has refcount 1 at EOF' );
