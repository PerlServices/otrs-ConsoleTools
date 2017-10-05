# --
# Copyright (C) 2017 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::ITSM::ConfigItem::Add;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::GeneralCatalog',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Add a config item.');
    $Self->AddOption(
        Name        => 'class',
        Description => "Class of the config item",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'name',
        Description => "Name for the config item.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'incistate',
        Description => "Incident state of the config item",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'deplstate',
        Description => "Deployment state of the config item",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'attribute',
        Description => "One attribute (form: <attrname>=<value>)",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Adding a new config item...</yellow>\n");

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    my $Classes = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );
    my $IncidentStates = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::Core::IncidentState',
    );
    my $DeploymentStates = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::DeploymentState',
    );

    my %IncidentStatesByName   = reverse %{ $IncidentStates };
    my %DeploymentStatesByName = reverse %{ $DeploymentStates };
    my %ClassesByName          = reverse %{ $Classes };

    my $ClassID           = $ClassesByName{ $Self->GetOption('class') };
    my $IncidentStateID   = $IncidentStatesByName{ $Self->GetOption('incistate') };
    my $DeploymentStateID = $DeploymentStatesByName{ $Self->GetOption('deplstate') };

    my $XMLData = $Self->_CreateXMLData( Data => $Self->GetOption('attribute') );

    my $HasNeededInformation;
    $HasNeededInformation++ if $ClassID && $IncidentStateID && $DeploymentStateID;

    if ( !$HasNeededInformation ) {
        $Self->PrintError("Can't add config item - necessary information are missing.");
        return $Self->ExitCodeError();
    }

    my $ConfigItemID = $ConfigItemObject->ConfigItemAdd(
        ClassID => $ClassID,
        UserID  => 1,
    );

    if ( !$ConfigItemID ) {
        $Self->PrintError("Can't add config item.");
        return $Self->ExitCodeError();
    }

    my $DefinitionRef = $ConfigItemObject->DefinitionGet(
        ClassID => $ClassID,
    );

    my $DefinitionID = $DefinitionRef->{DefinitionID};

    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ConfigItemID,
        Name         => $Self->GetOption('name') // '<undefined name>',
        DefinitionID => $DefinitionID,
        DeplStateID  => $DeploymentStateID,
        InciStateID  => $IncidentStateID,
        XMLData      => $XMLData,
        UserID       => 1,
    );

    if ( !$VersionID ) {
        $Self->PrintError("Can't add config item.");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

sub _CreateXMLData {
    my ($Self, %Param) = @_;

    if ( !$Param{Data} ) {
        return;
    }

    my $Version = {};

    for my $Attribute ( @{ $Param{Data} || [] } ) {
        my ($AttributeKey, $Value) = split /=/, $Attribute, 2;

        $AttributeKey .= '::1' if $AttributeKey !~ m{ :: [0-9]+ \z }xms;

        my $TagKey = $AttributeKey;

        my $Counter = 0;
        $TagKey =~ s!::!++$Counter % 2 ? "'}[" : "]{'"!ge;

        my @Parts = split /::/, $AttributeKey;

        my $Ref = $Version;
        while ( @Parts ) {
            my $Name  = shift @Parts;
            my $Index = shift @Parts;

            if ( !@Parts ) {
                $Ref->{$Name}->[$Index] = {
                    TagKey  => "[1]{'Version'}[1]{'" . $TagKey . ']',
                    Content => $Value,
                };

                last;
            }

            $Ref = $Ref->{$Name}->[$Index];
        }
    }

    my @Data = (
        undef,
        {
            TagKey => '[1]',
            Version => [
                undef,
                $Version,
            ],
        },
    );

    return \@Data;
}

1;
