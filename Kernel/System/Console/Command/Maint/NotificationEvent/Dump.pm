# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::NotificationEvent::Dump;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = qw(
    Kernel::System::NotificationEvent
    Kernel::System::Main;
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Print dump of all event based notifications.');

    $Self->AddOption(
        Name        => 'id',
        Description => "ID of notification to be dumped.",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/\d+/smx,
    );

    $Self->AddOption(
        Name        => 'name',
        Description => "Name of notification to be dumped.",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Print dump of all event based notifications...</yellow>\n");

    my $NotificationObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');
    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');

    my @Names = @{ $Self->GetOption('name') // [] };
    my @IDs   = @{ $Self->GetOption('id') // [] };

    my %NameMap = map{ $_ => 1 }@Names;
    my %IDMap   = map{ $_ => 1 }@IDs;

    my $Check   = %NameMap || %IDMap;

    my %List = $NotificationObject->NotificationList();

    my @Notifications;

    ID:
    for my $ID ( sort { $List{$a} cmp $List{$b} }keys %List ) {
        my %Notification = $NotificationObject->NotificationGet(
            ID => $ID,
        );

        my $DoPush = $Check ? 0 : 1;

        if ( $IDMap{$ID} || $NameMap{ $List{$ID} } ) {
            $DoPush = 1;
        }

        push @Notifications, \%Notification if $DoPush;
    }

    $Self->Print( $MainObject->Dump( \@Notifications ) );

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
