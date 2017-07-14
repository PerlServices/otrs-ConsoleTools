# --
# Copyright (C) 2017 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::User::Search;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Group',
    'Kernel::System::User',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Search for users.');
    $Self->AddOption(
        Name        => 'term',
        Description => "Search term.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'valid',
        Description => "Search only for valid users",
        Required    => 0,
        HasValue    => 0,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Search for users...</yellow>\n");

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    my %UserList = $UserObject->UserSearch(
        Search => $Self->GetOption('term'),
        Valid  => $Self->GetOption('valid'),
    );

    for my $UserID ( sort { $UserList{$a} cmp $UserList{$b} } keys %UserList ) {
        my %User = $UserObject->GetUserData(
            UserID => $UserID,
        );

        $Self->Print( sprintf qq~"%s %s" <%s>\n~, $User{UserFirstname}, $User{UserLastname}, $User{UserEmail} );
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
