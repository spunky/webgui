package WebGUI::Asset::Sku;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2008 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use Tie::IxHash;
use base 'WebGUI::Asset';
use WebGUI::Shop::Cart;


=head1 NAME

Package WebGUI::Asset::Sku

=head1 DESCRIPTION

This is the base class for all products in the commerce system.

=head1 SYNOPSIS

use WebGUI::Asset::Sku;

 $self = WebGUI::Asset::Sku->newBySku($session, $sku);

 $self->addToCart;
 $self->applyOptions;
 $hashRef = $self->getOptions;
 $integer = $self->getMaxAllowedInCart;
 $float = $self->getPrice;
 $float = $self->getTaxRate;
 $boolean = $self->isShippingRequired;
 $html = $self->processStyle($output);

=head1 METHODS

These methods are available from this class:

=cut



#-------------------------------------------------------------------

=head2 addToCart ( options ) 

Adds this sku to the current session's cart.

=head3 options

A hash reference as generated by getOptions().

=cut

sub addToCart {
    my ($self, $options) = @_;
    $self->applyOptions($options);
    $self->getCart->addItem($self);
}

#-------------------------------------------------------------------

=head2 applyOptions ( options )

Accepts a configuration data hash reference that configures a sku a certain way. For example to turn "a t-shirt" into "an XL red t-shirt". See also getOptions().

=head3 options

A hash reference containing the sku options.

=cut

sub applyOptions {
    my ($self, $options) = @_;
    $self->{_skuOptions} = $options;
}

#-------------------------------------------------------------------

=head2 definition ( session, definition )

See super class.

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	my $i18n = WebGUI::International->new($session, "Asset_Sku");
	%properties = (
		description => {
			tab				=> "properties",
			fieldType		=> "HTMLArea",
			defaultValue	=> undef,
			label			=> $i18n->get("description"),
			hoverHelp		=> $i18n->get("description help")
			},
		sku => {
			tab				=> "shop",
			fieldType		=> "text",
			defaultValue	=> $session->id->generate,
			label			=> $i18n->get("sku"),
			hoverHelp		=> $i18n->get("sku help")
			},
		displayTitle => {
			tab				=> "display",
			fieldType		=> "yesNo",
			defaultValue	=> 1,
			label			=> $i18n->get("display title"),
			hoverHelp		=> $i18n->get("display title")
			},
		overrideTaxRate => {
			tab				=> "shop",
			fieldType		=> "yesNo",
			defaultValue	=> 0,
			label			=> $i18n->get("override tax rate"),
			hoverHelp		=> $i18n->get("override tax rate help")
			},
		taxRateOverride => {
			tab				=> "shop",
			fieldType		=> "float",
			defaultValue	=> 0.00,
			label			=> $i18n->get("tax rate override"),
			hoverHelp		=> $i18n->get("tax rate override help")
			},
		salesAgentId => {
			tab				=> "shop",
			fieldType		=> "hidden",
			defaultValue	=> undef,
			label			=> $i18n->get("sales agent"),
			hoverHelp		=> $i18n->get("sales agent help")
			},
	);
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		icon=>'Sku.gif',
		autoGenerateForms=>1,
		tableName=>'sku',
		className=>'WebGUI::Asset::Sku',
		properties=>\%properties
	});
	return $class->SUPER::definition($session, $definition);
}


#-------------------------------------------------------------------

=head2 getCart ( )

Returns a reference to the current session's cart.

=cut

sub getCart {
	my $self = shift;
	return WebGUI::Shop::Cart->getCartBySession($self->session);
}

#-------------------------------------------------------------------

=head2 getConfiguredTitle ( )

Returns a configured title like "Red XL T-Shirt" rather than just "T-Shirt". Needs to be overridden by subclasses to support this. Defaultly just returns getTitle().

=cut

sub getConfiguredTitle {
    my $self = shift;
    return $self->getTitle;
}


#-------------------------------------------------------------------

=head2 getEditTabs ( )

Not to be modified, just defines a new tab.

=cut

sub getEditTabs {
	my $self = shift;
	my $i18n = WebGUI::International->new($self->session,"Asset_Sku");
	return (['shop', $i18n->get('shop'), 9]);
}

#-------------------------------------------------------------------

=head2 getOptions ( )

Returns a hash reference of configuration data that can return this sku to a configured state. See also applyOptions().

=cut

sub getOptions {
    my $self = shift;
    if (ref $self->{_skuOptions} eq "HASH") {
        return $self->{_skuOptions};
    }
    return {};
}

#-------------------------------------------------------------------

=head2 getMaxAllowedInCart ( )

Returns getQuantityAvailable(). Should be overriden by subclasses that have a specific value. Subclasses that are unique should return 1. Subclasses that have an inventory count should return the amount in inventory.

=cut

sub getMaxAllowedInCart {
	my $self = shift;
    return $self->getQuantityAvailable;
}

#-------------------------------------------------------------------

=head2 getPrice ( )

Returns 0.00. Needs to be overriden by subclasses.

=cut

sub getPrice {
    return 0.00;
}

#-------------------------------------------------------------------

=head2 getQuantityAvailable ( )

Returns 99999999. Needs to be overriden by subclasses. Tells the commerce system how many of this item is on hand.

=cut

sub getQuantityAvailable {
    return 99999999;
}

#-------------------------------------------------------------------

=head2 getRecurInterval ( )

Returns the recur interval, which must be one of the following: 'Weekly', 'BiWeekly', 'FourWeekly',
'Monthly', 'Quarterly', 'HalfYearly' or 'Yearly'. Must be overriden by subclass if that is a recurring Sku.

=cut

sub getRecurInterval {
    return undef;
}

#-------------------------------------------------------------------

=head2 getTaxRate ( )

Returns undef unless the "Override tax rate?" switch is set to yes. If it is, then it returns the value of the "Tax Rate Override" field.

=cut

sub getTaxRate {
    my $self = shift;
    return ($self->get("overrideTaxRate")) ? $self->get("taxRateOverride") : undef;
}

#-------------------------------------------------------------------

=head2 getWeight ( )

Returns 0. Needs to be overriden by subclasses.

=cut

sub getWeight {
    my $self = shift;
    return 0;
}

#-------------------------------------------------------------------

=head2 indexContent ( )

Adding sku as a keyword. See WebGUI::Asset::indexContent() for additonal details. 

=cut

sub indexContent {
	my $self = shift;
	my $indexer = $self->SUPER::indexContent;
    $indexer->addKeywords($self->get('sku'));
	return $indexer;
}


#-------------------------------------------------------------------

=head2 isRecurring

Returns a boolean indicating whether this sku is recurring. Defaultly returns 0. Needs to be overriden by subclasses that do recurring transactions, because not all payment gateways can process recurring transactions.

=cut

sub isRecurring {
    return 0;
}


#-------------------------------------------------------------------

=head2 isShippingRequired

Returns a boolean indicating whether shipping is required. Defaultly returns 0. Needs to be overriden by subclasses that use shipping.

=cut

sub isShippingRequired {
    return 0;
}


#-------------------------------------------------------------------

=head2 newBySku ( session, sku )

Returns a sku subclass based upon a sku lookup.

=head3 session

A reference to the current session.

=head3 sku

The sku attached to the object you wish to instanciate.

=cut

sub newBySku {
    my ($class, $session, $sku) = @_;
    my $assetId = $session->db->quickScalar("select assetId from Sku where sku=?", [$sku]);
    return WebGUI::Asset->newByDynamicClass($session, $assetId); 
}

#-------------------------------------------------------------------

=head2 onAdjustQuantityInCart ( item, amount )

Called just after the quantity is adjusted in the cart. Should be overridden by subclasses that need to account for inventory or other bookkeeping.

=head3 item

Receives a reference to the WebGUI::Shop::CartItem so it can determine things like itemId and quantity if it needs them for book keeping purposes.

=head3 amount

The amount to be adjusted for. Could be positive if more are being added to the cart or negative if more are being removed from the cart.

=cut

sub onAdjustQuantityInCart {
	my ($self, $item, $amount) = @_;
	return undef;
}

#-------------------------------------------------------------------

=head2 onCompletePurchase ( item )

Called just after payment has been made. It allows for privileges to be given, or bookkeeping
tasks to be performed. It should be overriden by subclasses that need to do special processing after the purchase.

=head3 item

Receives a reference to the WebGUI::Shop::CartItem so it can determine things like itemId and quantity if it needs them for book keeping purposes.

=cut

sub onCompletePurchase {
	my ($self, $item) = @_;
	return undef;
}

#-------------------------------------------------------------------

=head2 onRemoveFromCart ( item )

Called by the cart just B<before> the item is removed from the cart. This allows for cleanup. Should be overridden by subclasses for inventory control or other housekeeping.

=head3 item

Receives a reference to the WebGUI::Shop::CartItem so it can determine things like itemId and quantity if it needs them for book keeping purposes.

=cut

sub onRemoveFromCart {
	my ($self, $item) = @_;
	return undef;
}

#-------------------------------------------------------------------

=head2 processStyle ( output )

Returns output parsed under the current style.

=head3 output

An HTML blob to be parsed into the current style.

=cut

sub processStyle {
	my $self = shift;
	my $output = shift;
	return $self->getParent->processStyle($output);
}

#-------------------------------------------------------------------

=head2 www_view (  )

Renders self->view based upon current style, subject to timeouts. Returns Privilege::noAccess() if canView is False.

=cut

sub www_view {
	my $self = shift;
	my $check = $self->checkView;
	return $check if (defined $check);
	$self->session->http->setLastModified($self->getContentLastModified);
	$self->session->http->sendHeader;
	$self->prepareView;
	my $style = $self->processStyle("~~~");
	my ($head, $foot) = split("~~~",$style);
	$self->session->output->print($head, 1);
	$self->session->output->print($self->view);
	$self->session->output->print($foot, 1);
	return "chunked";
}

1;
