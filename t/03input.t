#!/usr/bin/perl

use strict;

use Test::More tests => 11;

use Tickit::Test;

use Tickit::Console;

my ( $term, $win ) = mk_term_and_window;

my @lines;
my $console = Tickit::Console->new(
   on_line => sub {
      push @lines, $_[1];
   },
);

$console->set_window( $win );

my $tab = $console->add_tab( name => "Tab" );

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT("Tab",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display initially' );

is_cursorpos( 24, 0, 'Cursor position initially' );

presskey( text => $_ ) for split //, "Hello";

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT("Tab",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              [TEXT("Hello"),TEXT("")] ],
            'Display after "Hello"' );

is_cursorpos( 24, 5, 'Cursor after "Hello"' );

is( scalar @lines, 0, 'No @lines yet before Enter' );

presskey( key => "Enter" );

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT("Tab",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after Enter' );

is_cursorpos( 24, 0, 'Cursor after Enter' );

is_deeply( \@lines, [ "Hello" ], '@lines after Enter' );

my @special_lines;
my $special_tab = $console->add_tab(
   name => "Tab2",
   on_line => sub { push @special_lines, $_[1] },
);

undef @lines;

$console->activate_tab( $special_tab );

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT("Tab ",fg=>7,bg=>4),TEXT("Tab2",fg=>14,bg=>4),TEXT(" ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after ->add_tab special' );

presskey( text => $_ ) for split //, "Another";
presskey( key => "Enter" );

is_deeply( \@lines, [], '@lines empty after entry on special tab' );
is_deeply( \@special_lines, [ "Another" ], '@special_lines after entry on special tab' );
