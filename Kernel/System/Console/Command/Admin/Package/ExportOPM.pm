# --
# Copyright (C) 2021 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Package::ExportOPM;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

use MIME::Base64 qw(decode_base64);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::DB',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Infos about a ticket.');
    $Self->AddOption(
        Name        => 'name',
        Description => "package name.",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'all',
        Description => "export all packages",
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddOption(
        Name        => 'target',
        Description => "directory where the packages are exported to.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Export package(s)...</yellow>\n");

    my @Names = @{ $Self->GetOption('name') || [] };
    my $All   = $Self->GetOption('all');

    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    if ( !$All && !@Names ) {
        $Self->Print("<red>Need either 'name'(s) or 'all'.</red>\n");
        return $Self->ExitCodeError();
    }

    my $SQL = q~
        SELECT name, version, content FROM package_repository
    ~;

    my @Binds;
    if ( @Names ) {
        $SQL .= ' WHERE name IN (' . ( join ', ', ('?') x @Names ) . ')';
        @Binds = \(@Names);
    }

    $SQL .= ' ORDER BY name, version';

    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Binds,
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $Filename = sprintf "%s-%s.opm", $Row[0], $Row[1];
        my $Dir      = $Self->GetOption('target') || '.';

        $Self->Print("<green>Export $Row[0] to $Dir/$Filename</green>\n");
        $MainObject->FileWrite(
            Directory => $Dir,
            Filename  => $Filename,
            Content   => \( decode_base64 $Row[2] ),
        );
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
