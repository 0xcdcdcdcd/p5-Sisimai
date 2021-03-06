package Sisimai::Test::Modules;
sub list {
    my $v = [];
    my $f = [ qw|
        Address.pm
        ARF.pm
        Data.pm
            Data/JSON.pm
            Data/YAML.pm
        DateTime.pm
        ISO3166.pm
        MIME.pm
        Mail.pm
            Mail/Mbox.pm
            Mail/Maildir.pm
            Mail/STDIN.pm
        Message.pm
        MDA.pm
        MSP.pm
            MSP/DE/EinsUndEins.pm
            MSP/DE/GMX.pm
            MSP/JP/Biglobe.pm
            MSP/JP/EZweb.pm
            MSP/JP/KDDI.pm
            MSP/RU/MailRu.pm
            MSP/RU/Yandex.pm
            MSP/UK/MessageLabs.pm
            MSP/US/AmazonSES.pm
            MSP/US/Aol.pm
            MSP/US/Bigfoot.pm
            MSP/US/Facebook.pm
            MSP/US/Google.pm
            MSP/US/Outlook.pm
            MSP/US/ReceivingSES.pm
            MSP/US/SendGrid.pm
            MSP/US/Verizon.pm
            MSP/US/Yahoo.pm
            MSP/US/Zoho.pm
        MTA.pm
            MTA/Activehunter.pm
            MTA/ApacheJames.pm
            MTA/Courier.pm
            MTA/Domino.pm
            MTA/Exim.pm
            MTA/Exchange.pm
            MTA/IMailServer.pm
            MTA/InterScanMSS.pm
            MTA/MailFoundry.pm
            MTA/MailMarshalSMTP.pm
            MTA/McAfee.pm
            MTA/MessagingServer.pm
            MTA/mFILTER.pm
            MTA/MXLogic.pm
            MTA/Notes.pm
            MTA/OpenSMTPD.pm
            MTA/Postfix.pm
            MTA/qmail.pm
            MTA/Sendmail.pm
            MTA/SurfControl.pm
            MTA/UserDefined.pm
            MTA/V5sendmail.pm
            MTA/X1.pm
            MTA/X2.pm
            MTA/X3.pm
            MTA/X4.pm
            MTA/X5.pm
        Order.pm
        Reason.pm
            Reason/Blocked.pm
            Reason/ContentError.pm
            Reason/ExceedLimit.pm
            Reason/Expired.pm
            Reason/Filtered.pm
            Reason/HasMoved.pm
            Reason/HostUnknown.pm
            Reason/MailboxFull.pm
            Reason/MailerError.pm
            Reason/MesgTooBig.pm
            Reason/SpamDetected.pm
            Reason/NoRelaying.pm
            Reason/NotAccept.pm
            Reason/NetworkError.pm
            Reason/OnHold.pm
            Reason/Rejected.pm
            Reason/SecurityError.pm
            Reason/Suspend.pm
            Reason/SystemError.pm
            Reason/SystemFull.pm
            Reason/TooManyConn.pm
            Reason/UserUnknown.pm
        RFC2606.pm
        RFC3463.pm
        RFC3464.pm
        RFC3834.pm
        RFC5321.pm
        RFC5322.pm
        Rhost.pm
            Rhost/GoogleApps.pm
        SMTP.pm
            SMTP/Reply.pm
            SMTP/Status.pm
        String.pm
        Time.pm
    | ];

    push @$v, 'Sisimai.pm';
    for my $e ( @$f ) {
        push @$v, sprintf( "Sisimai/%s", $e );
    }
    return $v;
}
1;
