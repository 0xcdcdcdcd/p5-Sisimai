package Sisimai::Reason::Suspend;
use feature ':5.10';
use strict;
use warnings;

sub text  { 'suspend' }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.0.0
    my $class = shift;
    my $argv1 = shift // return undef;
    my $regex = qr{(?:
         invalid/inactive[ ]user
        # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000742
        |email[ ]account[ ]that[ ]you[ ]tried[ ]to[ ]reach[ ]is[ ]disabled
        |is[ ]a[ ]deactivated[ ]mailbox
        |mailbox[ ](?:
             currently[ ]suspended
            |unavailable[ ]or[ ]access[ ]denied
            )
        |user[ ]suspended   # http://mail.163.com/help/help_spam_16.htm
        |recipient[ ]suspend[ ]the[ ]service
        |sorry[ ]your[ ]message[ ]to[ ].+[ ]cannot[ ]be[ ]delivered[.][ ]this[ ]
            account[ ]has[ ]been[ ]disabled[ ]or[ ]discontinued
        |vdelivermail:[ ]account[ ]is[ ]locked[ ]email[ ]bounced
        )
    }xi;

    return 1 if $argv1 =~ $regex;
    return 0;
}

sub true { 
    # The envelope recipient's mailbox is suspended or not
    # @param    [Sisimai::Data] argvs   Object to be detected the reason
    # @return   [Integer]               1: is mailbox suspended
    #                                   0: is not suspended
    # @since v4.0.0
    # @see http://www.ietf.org/rfc/rfc2822.txt
    my $class = shift;
    my $argvs = shift // return undef;

    return undef unless ref $argvs eq 'Sisimai::Data';
    my $statuscode = $argvs->deliverystatus // '';
    my $reasontext = __PACKAGE__->text;

    return undef unless length $statuscode;
    return 1 if $argvs->reason eq $reasontext;
    return 1 if __PACKAGE__->match( $argvs->diagnosticcode // '' );
    return 0
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::Suspend - Bounce reason is C<suspend> or not.

=head1 SYNOPSIS

    use Sisimai::Reason::Suspend;
    print Sisimai::Reason::Suspend->match('recipient suspend the service'); # 1

=head1 DESCRIPTION

Sisimai::Reason::Suspend checks the bounce reason is C<suspend> or not. This 
class is called only Sisimai::Reason class.

This is the error that a recipient account is being suspended due to unpaid or 
other reasons.

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> returns string: C<suspend>.

    print Sisimai::Reason::Suspend->text;  # suspend

=head2 C<B<match( I<string> )>>

C<match()> returns 1 if the argument matched with patterns defined in this class.

    print Sisimai::Reason::Suspend->match('recipient suspend the service'); # 1

=head2 C<B<true( I<Sisimai::Data> )>>

C<true()> returns 1 if the bounce reason is C<suspend>. The argument must be
Sisimai::Data object and this method is called only from Sisimai::Reason class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2015 azumakuniyuki E<lt>perl.org@azumakuniyuki.orgE<gt>,
All Rights Reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
