# --
# Copyright (C) 2021 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Database::RemovePID;

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
        Name        => 'pid',
        Description => "ProcessID to remove.",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/[0-9]+/smx,
    );

    $Self->AddOption(
        Name        => 'all',
        Description => "Remove all ProcessIDs",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Remove ProcessID(s)....</yellow>\n");

    my @PID = @{ $Self->GetOption('pid') || [] };
    my $All = $Self->GetOption('all');

    if ( !@PID && !$All ) {
        $Self->Print("<red>You need to pass the ProcessIDs to delete or explicitly ask to delete all PIDs.</red>\n");
        return $Self->ExitCodeError();
    }

    my $SQL = 'DELETE FROM process_id ';
    my @Bind;
    if ( @PID ) {
        $SQL .= ' WHERE process_id IN (' . (join ',', ('?') x @PID) . ')';
        @Bind = @PID;
    }

    # Delete ticket history entries from DB
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => $SQL,
        Bind => [ \(@Bind) ],
    );

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
