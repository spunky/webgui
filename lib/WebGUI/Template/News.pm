package WebGUI::Template::News;

our $namespace = "News";

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2002 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------


use strict;
use WebGUI::International;


#-------------------------------------------------------------------
sub generate {
	my ($output, $content);
	$content = $_[0];
	$output = '<table cellpadding="3" cellspacing="0" border="0" width="100%"><tr>';
	$output .= '<td valign="top" class="content" colspan="2" width="100%">'.${$content}{A}.'</td></tr><tr>';
	$output .= '<td valign="top" class="content" width="50%">'.${$content}{B}.'</td>';
	$output .= '<td valign="top" class="content" width="50%">'.${$content}{C}.'</td>';
	$output .= '</tr><tr><td valign="top" class="content" colspan="2" width="100%">'.${$content}{D}.'</td></tr>';
	$output .= '</table>';
	return $output;
}

#-------------------------------------------------------------------
sub name {
        return WebGUI::International::get(357);
}

#-------------------------------------------------------------------
sub getPositions {
        return WebGUI::Template::calculatePositions('D');
}

1;

