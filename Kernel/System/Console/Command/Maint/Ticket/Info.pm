# --
# Copyright (C) 2017 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Ticket::Info;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Infos about a ticket.');
    $Self->AddOption(
        Name        => 'id',
        Description => "ticket id.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'number',
        Description => "ticket number",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Infos about a ticket...</yellow>\n");

    my $TicketID = $Self->GetOption('id');
    my $TicketNr = $Self->GetOption('number');

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    if ( !$TicketID && !$TicketNr ) {
        $Self->Print("<red>Need either 'id' or 'number'.</red>\n");
        return $Self->ExitCodeError();
    }

    if ( !$TicketID ) {
        $TicketID = $TicketObject->TicketCheckNumber(
            Tn => $TicketNr,
        );
    }

    if ( !$TicketID ) {
        $Self->Print("<red>No valid ticket number.</red>\n");
        return $Self->ExitCodeError();
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $TicketID,
    );

    if ( !%Ticket ) {
        $Self->Print("<red>No ticket found.</red>\n");
        return $Self->ExitCodeError();
    }

    my $Text = sprintf qq~TicketID: %s
Ticket#: %s
Title: %s
State: %s
Owner: %s
Priority: %s
Queue: %s
    ~,
    @Ticket{ qw/TicketID TicketNumber Title State Owner Priority Queue/ };

    $Self->Print( $Text );

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
