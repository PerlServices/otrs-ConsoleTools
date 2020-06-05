# --
# Copyright (C) 2020 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::TicketChecklistFreePro;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Package',
    'Kernel::System::TicketChecklist',
    'Kernel::System::Main',
    'Kernel::System::JSON',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Upgrade TicketChecklist from Free to Pro.');
    $Self->AddOption(
        Name        => 'json-dir',
        Description => "Directory where to save the json file to",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'opm',
        Description => "The TicketChecklis Pro module",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'step',
        Description => "The step to run",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Upgrade TicketChecklist from Free to Pro...</yellow>\n");

    my $Step = $Self->GetOption('step');

    if ( !$Step || $Step eq 'dump' ) {
        my $Return = $Self->DumpChecklists;
        if ( !$Return ) {
            return $Self->ExitCodeError();
        }
    }

    if ( !$Step || $Step eq 'uninstall' ) {
        my $Return = $Self->UninstallTicketChecklist;
        if ( !$Return ) {
            return $Self->ExitCodeError();
        }
    }

    if ( !$Step || $Step eq 'install' ) {
        my $Return = $Self->InstallTicketChecklist;
        if ( !$Return ) {
            return $Self->ExitCodeError();
        }
    }

    if ( !$Step || $Step eq 'recover' ) {
        my $Return = $Self->RecoverChecklists;
        if ( !$Return ) {
            return $Self->ExitCodeError();
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

sub DumpChecklists {
    my ($Self) = @_;

    my $TicketChecklistObject = $Kernel::OM->Get('Kernel::System::TicketChecklist');
    my $StatusObject          = $Kernel::OM->Get('Kernel::System::TicketChecklistStatus');
    my $MainObject            = $Kernel::OM->Get('Kernel::System::Main');
    my $DBObject              = $Kernel::OM->Get('Kernel::System::DB');
    my $JSONObject            = $Kernel::OM->Get('Kernel::System::JSON');

    $Self->Print("<yellow>Dump checklists and checklist status to JSON...</yellow>\n");
    my $SQL = q~SELECT id FROM ps_ticketchecklist~;
    if ( !$DBObject->Prepare( SQL => $SQL ) ) {
        $Self->PrintError("No TicketChecklist installed.");
        return;
    }

    my @ChecklistIDs;
    while ( my ($ID) = $DBObject->FetchrowArray() ) {
        push @ChecklistIDs, $ID;
    }

    my @Checklists;
    for my $ID ( @ChecklistIDs ) {
        push @Checklists, +{
            $TicketChecklistObject->TicketChecklistGet( ID => $ID )
        };
    }

    my %StatusList = $StatusObject->TicketChecklistStatusList();

    my @Status;
    for my $StatusID ( keys %StatusList ) {
        push @Status, +{
            $StatusObject->TicketChecklistStatusGet( ID => $StatusID )
        };
    }

    my $JSON = $JSONObject->Encode(
        Data => {
            Checklists => \@Checklists,
            Status     => \@Status,
        },
    );

    $MainObject->FileWrite(
        Directory => $Self->GetOption('json-dir'),
        Filename  => 'TicketChecklistDump.json',
        Content   => \$JSON,
    );

    return 1;
}

sub UninstallTicketChecklist {
    my ($Self) = @_;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    $Self->Print("<yellow>Uninstall TicketChecklist...</yellow>\n");
    my @Packages = $PackageObject->RepositoryList(
        Result => 'short',
    );

    my ($TicketChecklistPackage) = grep { $_->{Name} eq 'TicketChecklist' } @Packages;

    if ( !$TicketChecklistPackage ) {
        $Self->PrintError("No TicketChecklist installed.");
        return;
    }

    my $Package = $PackageObject->RepositoryGet(
        Name    => 'TicketChecklist',
        Version => $TicketChecklistPackage->{Version},
        Result  => 'SCALAR',
    );

    $PackageObject->PackageUninstall( String => $Package )

    return 1;
}

sub InstallTicketChecklist {
    my ($Self) = @_;

    my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');
    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    $Self->Print("<yellow>Install TicketChecklist Pro...</yellow>\n");

    my $OPMContent = $MainObject->FileRead(
        Location => $Self->GetOption('opm'),
    );

    my $Success $PackageObject->PackageInstall(
        String => ${$OPMContent},
    );

    if ( !$Success ) {
        $Self->PrintError("Package installation failed.");
        return;
    }

    return 1;
}

sub RecoverChecklist {
    my ($Self) = @_;

    my $TicketChecklistObject = $Kernel::OM->Get('Kernel::System::TicketChecklist');
    my $StatusObject          = $Kernel::OM->Get('Kernel::System::TicketChecklistStatus');
    my $MainObject            = $Kernel::OM->Get('Kernel::System::Main');
    my $DBObject              = $Kernel::OM->Get('Kernel::System::DB');
    my $JSONObject            = $Kernel::OM->Get('Kernel::System::JSON');

    $Self->Print("<yellow>Recover checklists...</yellow>\n");

    my $JSONContent = $MainObject->FileRead(
        Directory => $Self->GetOption('json-dir'),
        Filename  => 'TicketChecklistDump.json',
    );

    my $Data = $JSONObject->Decode(
        Data => ${$JSONContent},
    );

    my $SQL = q~DELETE FROM ps_ticketchecklist_status~;

    for my $Status ( @{ $Data->{Status} || [] } ) {
        $StatusObject->TicketChecklistStatusAdd(
            %{ $Status },
            UserID => $Status->{CreateBy},
        );
    }

    for my $Checklist ( @{ $Data->{Checklists} || [] } ) {
        my %ChecklistData = %{ $Checklist || {} };
        delete $ChecklistData{qw/StatusID/};

        $ChecklistData{UserID} = $ChecklistData{CreateBy};

        $TicketChecklistObject->TicketChecklistAdd(
            %ChecklistData,
        );
    }

    return 1;
}

1;
