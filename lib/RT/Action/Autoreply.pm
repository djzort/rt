# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2022 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

package RT::Action::Autoreply;

use strict;
use warnings;

use base qw(RT::Action::SendEmail);

=head2 Prepare

Set up the relevant recipients, then call our parent.

=cut


sub Prepare {
    my $self = shift;
    $self->SetRecipients();
    $self->SUPER::Prepare();
}


=head2 SetRecipients

Sets the recipients of this message to this ticket's Requestor.

=cut


sub SetRecipients {
    my $self=shift;

    push(@{$self->{'To'}}, $self->TicketObj->Requestors->MemberEmailAddresses);
    
    return(1);
}




=head2 SetReturnAddress

Set this message's return address to the apropriate queue address

=cut

sub SetReturnAddress {
    my $self = shift;

    my $friendly_name;

    if (RT->Config->Get('UseFriendlyFromLine')) {
        $friendly_name = $self->TicketObj->QueueObj->Description ||
            $self->TicketObj->QueueObj->Name;
    }

    $self->SUPER::SetReturnAddress( @_, friendly_name => $friendly_name );

}



=head2 SetRTSpecialHeaders

Set the C<Auto-Generated> header to C<auto-replied>, in accordance
with RFC3834.

=cut

sub SetRTSpecialHeaders {
    my $self = shift;
    $self->SUPER::SetRTSpecialHeaders(@_);
    $self->SetHeader( 'Auto-Submitted', 'auto-replied' );
}


RT::Base->_ImportOverlays();

1;
