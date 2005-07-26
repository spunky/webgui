package WebGUI::Form::codearea;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2005 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Form::text';
use WebGUI::International;
use WebGUI::Session;
use WebGUI::Style;

=head1 NAME

Package WebGUI::Form::codearea

=head1 DESCRIPTION

Creates a code area form field, which is just like a text area except stretches to fit it's space and allows tabs in it's content.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::textarea.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut


#-------------------------------------------------------------------

=head2 getName ()

Returns the human readable name or type of this form control.

=cut

sub getName {
        return WebGUI::International::get("codearea","WebGUI");
}


#-------------------------------------------------------------------

=head2 toHtml ( )

Renders a code area field.

=cut

sub toHtml {
	my $self = shift;
	WebGUI::Style::setScript($session{config}{extrasURL}.'/TabFix.js',{type=>"text/javascript"});
	$self->{extras} .= ' style="width: 99%; min-width: 440px; height: 400px" onkeypress="return TabFix_keyPress(event)" onkeydown="return TabFix_keyDown(event)"';	
	return $self->SUPER::toHtml;
}


1;

