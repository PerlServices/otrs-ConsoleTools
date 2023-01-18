# --
# Copyright (C) 2020 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Email::SendCheck;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
);

{
    package My::CommunicationLog;

    sub new { return bless {}, shift }
    sub ObjectLog {}
}

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Check connection to SMTP server');

    $Self->AddOption(
        Name        => 'check-alternatives',
        Description => "Checks alternativs if basic check fails",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Check connection to server...</yellow>\n");

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $GenericModule = $ConfigObject->Get('SendmailModule')
        || 'Kernel::System::Email::Sendmail';

    my $Type = (split /::/, $GenericModule)[-1];

    my $Backend = $Kernel::OM->Get($GenericModule);

    if ( !$Backend->can('Check') ) {
        $Self->Print("<yellow>$Backend doesn't support the Check() method.</yellow>\n");
        return $Self->ExitCodeOk();
    }

    my $Object = My::CommunicationLog->new();

    my %Connection = $Backend->Check(
        CommunicationLogObject => $Object,
    );

    if ( !$Connection{Successful} ) {
        $Self->Print("<red>$Connection{Message}.</red>\n");

        if ( $Type =~ m{SMTP}xms && $Self->GetOption('check-alternatives') ) {
            for my $Type ( qw(SMTP SMTPS SMTPTLS) ) {
                my $Backend = $Kernel::OM->Get('Kernel::System::Email::' . $Type);

                my %Connection = $Backend->Check(
                    CommunicationLogObject => $Object,
                );

                if ( $Connection{Successful} ) {
                    $Self->Print("<green>$Type works.</green>\n");
                }
            }
        }
    } 

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
