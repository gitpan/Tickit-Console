#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Tickit::Console;

use strict;
use warnings;
use base qw( Tickit::Widget::VBox );

our $VERSION = '0.04';

use Tickit::Widget::Entry;
use Tickit::Widget::Scroller 0.04;
use Tickit::Widget::Tabbed 0.003;

use Scalar::Util qw( weaken );

=head1 NAME

C<Tickit::Console> - build full-screen console-style applications

=cut

=head1 CONSTRUCTOR

=cut

=head2 $console = Tickit::Console->new( %args )

Returns a new instance of a C<Tickit::Console>. Takes the following named
arguments:

=over 8

=item on_line => CODE

Callback to invoke when a line of text is entered in the entry widget.

 $on_line->( $console, $text )

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $on_line = delete $args{on_line};

   my $self = $class->SUPER::new( %args );

   $self->add(
      $self->{tabbed} = Tickit::Widget::Tabbed->new(
         tab_position => "bottom",
         tab_class    => "Tickit::Console::Tab",
      ),
      expand => 1,
   );

   $self->add(
      $self->{entry} = Tickit::Widget::Entry->new
   );

   weaken( my $weakself = $self );
   $self->{entry}->set_on_enter( sub {
      return unless $weakself;
      my ( $entry ) = @_;
      my $line = $entry->text;
      $entry->set_text( "" );

      my $tab = $weakself->active_tab;
      if( $tab->{on_line} ) {
         $tab->{on_line}->( $weakself, $line );
      }
      else {
         $on_line->( $weakself, $line );
      }
   } );

   return $self;
}

=head1 METHODS

=cut

=head2 $tab = $console->add_tab( %args )

Adds a new tab to the console, and returns an object representing it.

Takes the following named arguments:

=over 8

=item name => STRING

Name for the tab.

=item on_line => CODE

Optional. Provides a different callback to invoke when a line of text is
entered while this tab is active. Invoked the same way as above.

=back

See L</TAB OBJECTS> below for more information about the returned object.

=cut

sub add_tab
{
   my $self = shift;
   my %args = @_;

   my $tab = $self->{tabbed}->add_tab(
      Tickit::Widget::Scroller->new( gravity => "bottom" ),
      label => $args{name}
   );

   $tab->{on_line} = delete $args{on_line};

   return $tab;
}

=head2 $index = $console->active_tab_index

=head2 $tab = $console->active_tab

=head2 $console->activate_tab( $tab_or_index )

=head2 $console->next_tab

=head2 $console->prev_tab

These methods are all passed through to the underlying
L<Tickit::Widget::Tabbed> object.

=cut

foreach my $method (qw( active_tab_index active_tab activate_tab next_tab prev_tab )) {
   no strict 'refs';
   *$method = sub {
      my $self = shift;
      $self->{tabbed}->$method( @_ );
   };
}

=head1 TAB OBJECTS

=cut

package Tickit::Console::Tab;
use base qw( Tickit::Widget::Tabbed::Tab );

use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::Scroller::Item::RichText;

=head2 $name = $tab->name

=head2 $tab->set_name( $name )

Returns or sets the tab name text

=cut

sub name
{
   my $self = shift;
   return $self->label;
}

sub set_name
{
   my $self = shift;
   my ( $name ) = @_;
   $self->set_label( $name );
}

=head2 $tab->add_line( $string, %opts )

Appends a line of text to the tab. C<$string> may either be a plain perl
string, or an instance of L<String::Tagged> containing formatting tags, as
specified by L<Tickit::Widget::Scroller>. Options will be passed to the
L<Tickit::Widget::Scroller::Item::Line> used to contain the string.

=cut

sub add_line
{
   my $self = shift;
   my ( $string, %opts ) = @_;

   my $item;
   if( eval { $string->isa( "String::Tagged" ) } ) {
      $item = Tickit::Widget::Scroller::Item::RichText->new( $string, %opts );
   }
   else {
      $item = Tickit::Widget::Scroller::Item::Text->new( $string, %opts );
   }

   $self->widget->push( $item );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
