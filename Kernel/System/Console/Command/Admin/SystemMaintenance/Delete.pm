# --
# Copyright (C) 2021 Perl-Services.de, https://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::SystemMaintenance::Delete;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::SystemMaintenance',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Delete system maintenance entries.');
    $Self->AddOption(
        Name        => 'id',
        Description => "ID of the system maintenance entry",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/[0-9]+/xms,
    );
    $Self->AddOption(
        Name        => 'all',
        Description => "Delete all system maintenance entries",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Delete a system maintenance entry...</yellow>\n");

    my $MaintenanceObject = $Kernel::OM->Get('Kernel::System::SystemMaintenance');

    my @IDs = @{ $Self->GetOption('id') || [] };

    my $All = $Self->GetOption('all');
    if ( $All ) {
        @IDs = keys %{
            $MaintenanceObject->SystemMaintenanceList(
                UserID => 1,
            ) || {}
        };
    }

    if ( !@IDs && !$All ) {
        $Self->PrintError("Need either an 'id' or 'all'");
        return $Self->ExitCodeError();
    }

    my $Success;
    for my $ID ( @IDs ) {
        $Success++ if $MaintenanceObject->SystemMaintenanceDelete(
            ID     => $ID,
            UserID => 1,
        );
    }

    if ( !$Success ) {
        $Self->PrintError("Can't delete system maintenance(s).");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
