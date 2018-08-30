# --
# Copyright (C) 2018 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Ticket::CheckFlag;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Check "Seen" flag for all users and all tickets.');
    $Self->AddOption(
        Name        => 'state',
        Description => "State of ticket.",
        Required    => 0,
        Multiple    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'fix-flag',
        Description => "reset ticket flag if user has not seen all articles.",
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddOption(
        Name        => 'summary',
        Description => "print summary at the end of the check.",
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddOption(
        Name        => 'links',
        Description => "print summary at the end of the check.",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Check 'Seen' flag for all users and all tickets...</yellow>\n");

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %UserList  = $UserObject->UserList(
        Valid => 1,
    );

    my %Opts;
    my $States = $Self->GetOption('state');
    if ( $States ) {
       $Opts{States} = $States;
    }

    my %Errors;

    for my $UserID ( sort keys %UserList ) {
        my $UserName = $UserList{$UserID};
        $Self->Print( "Checks for User $UserName\n" );

        my $ErrorFound = 0;

        my @TicketIDs = $TicketObject->TicketSearch(
            %Opts,
            TicketFlag => {
                Seen => 1,
            },
            Result => 'ARRAY',
            UserID => $UserID,
        );

        for my $TicketID ( @TicketIDs ) {
            
            my @SenderTypes = (qw(customer agent system));

            # ignore system sender
            if ( $ConfigObject->Get('Ticket::NewArticleIgnoreSystemSender') ) {
                @SenderTypes = (qw(customer agent));
            }

            my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

            my @ArticleList;
            for my $SenderType (@SenderTypes) {
                my @Articles = $ArticleObject->ArticleList(
                    TicketID   => $TicketID,
                    SenderType => $SenderType,
                );

                for my $Article (@Articles) {
                    push @ArticleList, $Article->{ArticleID};
                }
            }

            # check if ticket needs to be marked as seen
            my %Flags = $ArticleObject->ArticleFlagsOfTicketGet(
                TicketID => $TicketID,
                UserID   => $UserID,
            );

            ARTICLE:
            for my $ArticleID (@ArticleList) {

                # last ARTICLE if article was not shown
                if ( !$Flags{$ArticleID}->{Seen} ) {
                    $Self->Print("<red>Ticket $TicketID marked as seen, but not all articles are marked as seen</red>\n");
                    $ErrorFound++;

                    push @{ $Errors{$UserName} }, [ $TicketID, $ArticleID ];

                    last ARTICLE;
                }
            }
        }

        if ( !$ErrorFound ) {
            $Self->Print("<green>Ok for user $UserName.</green>\n");
        }
    }

    my $Format = sprintf "%s://%s/%s/index.pl?Action=AgentTicketZoom&TicketID=%%s&ArticleID=%%s",
        $ConfigObject->Get('HttpType'),
        $ConfigObject->Get('FQDN'),
        $ConfigObject->Get('ScriptAlias');

    if ( $Self->GetOption('summary') ) {
        $Self->Print("<yellow>Summary:</yellow>\n");

        if ( $ConfigObject->Get('Ticket::NewArticleIgnoreSystemSender') ) {
            $Self->Print("<yellow>    Ticket::NewArticleIgnoreSystemSender is active.</yellow>\n");
        }

        for my $User ( sort keys %Errors ) {
            if ( !$Self->GetOption('links') ) {
                my $Message = join ', ', map{ sprintf "TicketID: %s / Article %s", @{ $_ } }@{ $Errors{$User} || [] };
                $Self->Print("<red>    $User: $Message.</red>\n");
            }
            else {
                for my $Error ( @{ $Errors{$User} || [] } ) {
                    my $URL = sprintf $Format, @{ $Error || [] };
                    $Self->Print("<red>    $User: $URL</red>\n");
                }
            }
        }

        if ( !%Errors ) {
            $Self->Print("<green>    Everything ok.</green>\n");
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
