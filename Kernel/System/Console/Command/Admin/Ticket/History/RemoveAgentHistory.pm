# --
# Copyright (C) 2020 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Ticket::History::RemoveAgentHistory;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Remove entries that user has read it from a ticket\'s history.');
    $Self->AddOption(
        Name        => 'login',
        Description => "user login.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.+/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Remove entries that user has read it from a ticket's history....</yellow>\n");

    my $UserLogin = $Self->GetOption('login');

    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my %List = $UserObject->UserSearch(
        UserLogin => $UserLogin,
        Limit     => 1,
    );

    if (!%List) {
        $Self->Print("<red>There is no user with a login '$UserLogin'.</red>\n");
        return $Self->ExitCodeOk();
    }

    my @UserIDs = keys %List;
    my $UserID = $UserIDs[0];
    $Self->Print("<yellow>User '$UserLogin' has id $UserID.</yellow>\n");

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # Delete ticket history entries from DB
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM ticket_history WHERE create_by = ?',
        Bind => [
            \$UserID,
        ],
    );

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
