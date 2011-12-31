#!/usr/bin/perl -w

use strict;

use Tickit::Async;
use Tickit::Console;

use IO::Async::Loop;
use String::Tagged;

my $loop = IO::Async::Loop->new();

my $globaltab;
my $warntab;

my $timercount = 0;
my $timerid;

sub timerfunc
{
   $globaltab->add_line( "<TIMER>: Hello $timercount", indent => 9 );
   $timercount++;

   $timerid = $loop->enqueue_timer( delay => 1, code => \&timerfunc );
}

my $console = Tickit::Console->new(
   on_line => sub {
      my ( $self, $line ) = @_;

      if( $line eq "quit" ) {
         $loop->loop_stop();
         return;
      }
      elsif( $line eq "start" ) {
         $loop->cancel_timer( $timerid ) if defined $timerid;
         $timercount = 0;
         timerfunc();
      }
      elsif( $line eq "stop" ) {
         $loop->cancel_timer( $timerid ) if defined $timerid;
         undef $timerid;
      }
      else {
         $globaltab->add_line( "<INPUT>: $line", indent => 9 );
      }
   },

   on_key => sub {
      my ( $self, $type, $str, $key ) = @_;

      # Encode nicely
      $str =~ s/\//\\\\/g;
      $str =~ s/\n/\\n/g;
      $str =~ s/\r/\\r/g;
      $str =~ s/\e/\\e/g;
      $str =~ s{([^\x20-\x7e])}{sprintf "\\x%02x", ord $1}eg;

      $globaltab->add_line( "<KEY>: $type => $str", indent => 7 );
   },
);

$globaltab = $console->add_tab( name => "GLOBAL" );
$warntab   = $console->add_tab( name => "WARN" );

$SIG{__WARN__} = sub {
   return unless defined $warntab;
   $warntab->add_line( "WARN: $_[0]", 6 );
};

my $tickit = Tickit::Async->new;
$loop->add( $tickit );

$tickit->set_root_widget( $console );

# Create some inital content so the tab has something interesting to scroll around
for ( 1 .. 50 ) {
   my $text = String::Tagged->new( "<Rand>: " );
   my %pen = (
   );
   for ( 0 .. rand( 30 ) + 3 ) {
      $text->append_tagged( chr( rand( 26 ) + 0x40 ) x ( rand( 10 ) + 5 ),
                            fg => int( rand( 7 ) + 1 ),
                            b  => rand > 0.8,
                            u  => rand > 0.8,
                            i  => rand > 0.8,
                          );
      $text->append( " " );
   }

   $globaltab->add_line( $text, indent => 8 );
}

eval { $tickit->run };

undef $console;

die "$@" if $@;
