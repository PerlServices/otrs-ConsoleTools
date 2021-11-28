# --
# Copyright (C) 2021 Perl-Services.de, https://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::SystemMaintenance::Add;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::SystemMaintenance',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Add a system maintenance entry.');
    $Self->AddOption(
        Name        => 'start',
        Description => "Start date of the system maintenance",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} /smx,
    );
    $Self->AddOption(
        Name        => 'end',
        Description => "End date of the system maintenance",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} /smx,
    );
    $Self->AddOption(
        Name        => 'comment',
        Description => "Comment",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'login-message',
        Description => "Message for login screen",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'notification',
        Description => "Notification",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'valid',
        Description => "Validity of the system maintenance entry (1 = valid, 2 = invalid)",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/[12]/,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Adding a new system maintenance entry...</yellow>\n");

    my $MaintenanceObject = $Kernel::OM->Get('Kernel::System::SystemMaintenance');

    my %Opts;

    my $Message = $Self->GetOption('login-message');
    if ( $Message ) {
        $Opts{LoginMessage}     = $Message;
        $Opts{ShowLoginMessage} = 1;
    }

    my $Notification = $Self->GetOption('notification');
    if ( $Notification ) {
        $Opts{NotifyMessage} = $Notification;
    }

    my $Success = $MaintenanceObject->SystemMaintenanceAdd(
        %Opts,
        StartDate => $Self->GetOption('start'),
        StopDate  => $Self->GetOption('end'),
        Comment   => $Self->GetOption('comment'),
        ValidID   => $Self->GetOption('valid'),
        UserID    => 1,
    );

    if ( !$Success ) {
        $Self->PrintError("Can't add system maintenance.");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;