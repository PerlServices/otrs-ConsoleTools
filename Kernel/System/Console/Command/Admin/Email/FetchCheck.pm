# --
# Copyright (C) 2021 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Email::FetchCheck;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::',
    'Kernel::System::MailAccount',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Search for users.');

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

    $Self->Print("<yellow>Check email accounts...</yellow>\n");

    my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');

    my @MailAccounts = $MailAccountObject->MailAccountGetAll();

    MAILACCOUNT:
    for my $MailAccount ( @MailAccounts ) {
        $Self->Print( '<yellow>' . (sprintf "Check %s/%s", $MailAccount->{Login}, $MailAccount->{Host} ) . "</yellow>\n" );

        my %Result = $MailAccountObject->MailAccountCheck(
            %{$MailAccount},
            Timeout => 30,
            Debug   => 0,
        );

        if ( $Result{Successful} ) {
            $Self->Print("<green>Ok.</green>\n");
        }
        else {
            $Self->Print("<red>$Result{Message}.</red>\n");

            if ( $Self->GetOption('check-alternatives') ) {
                my $WorkingTypeFound;

                for my $Type ( qw/POP3 POP3S POP3TLS IMAP IMAPS IMAPTLS/ ) {
                    my %AltResult = $MailAccountObject->MailAccountCheck(
                        %{$MailAccount},
                        Timeout => 30,
                        Debug   => 0,
                        Type    => $Type,
                    );

                    if ( $AltResult{Successful} ) {
                        $Self->Print("<green>$Type works.</green>\n");
                        $WorkingTypeFound++;
                    }
                }

                $Self->Print("<red>No working alternative found.</red>\n") if !$WorkingTypeFound;
            }
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
