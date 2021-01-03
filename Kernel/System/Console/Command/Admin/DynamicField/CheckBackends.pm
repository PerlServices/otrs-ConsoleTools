# --
# Copyright (C) 2019 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::DynamicField::CheckBackends;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Check the backends');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Checking all dynamic field backends...</yellow>\n");

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my %ConfiguredBackends = %{ $ConfigObject->Get('DynamicFields::Driver') || {} };
    my %BackendModules     = map{ $_ => $ConfiguredBackends{$_}->{Module} } keys %ConfiguredBackends;
    my %UsedBackends       = $Self->_UsedBackendsGet();
    my %AllBackends        = ( %UsedBackends, %BackendModules );

    for my $Backend ( sort keys %AllBackends ) {
        $Self->Print("<yellow>Check $Backend...  </yellow>");

        # require this backend
        my $Module = $AllBackends{$Backend};
        my $Loaded = $MainObject->Require( $Module, Silent => 1 );

        if ( $Loaded ) {
            $Self->Print("<green>Ok.</green>\n");
        }
        else {
            $Self->Print("<red>Failed.</red>\n");
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

sub _UsedBackendsGet {
    my ($Self) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $SQL      = qq~;
        SELECT field_type FROM dynamic_field
    ~;

    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    my %Backends;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $Name   = $Row[0];
    my $Module = 'Kernel::System::DynamicField::Driver::' . $Name;
    $Backends{$Name} = $Module;
    }

    return %Backends;
}

1;
