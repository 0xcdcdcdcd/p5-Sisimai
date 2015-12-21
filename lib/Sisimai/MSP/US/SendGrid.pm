package Sisimai::MSP::US::SendGrid;
use parent 'Sisimai::MSP';
use feature ':5.10';
use strict;
use warnings;

my $Re0 = {
    'from'        => qr/\AMAILER-DAEMON\z/,
    'return-path' => qr/\A[<]apps[@]sendgrid[.]net[>]\z/,
    'subject'     => qr/\AUndelivered Mail Returned to Sender\z/,
};
my $Re1 = {
    'begin'  => qr/\AThis is an automatically generated message from SendGrid[.]\z/,
    'error'  => qr/\AIf you require assistance with this, please contact SendGrid support[.]\z/,
    'rfc822' => qr|\AContent-Type: message/rfc822|,
    'endof'  => qr/\A__END_OF_EMAIL_MESSAGE__\z/,
};

my $Indicators = __PACKAGE__->INDICATORS;
my $LongFields = Sisimai::RFC5322->LONGFIELDS;
my $RFC822Head = Sisimai::RFC5322->HEADERFIELDS;

sub description { 'SendGrid: http://sendgrid.com/' }
sub smtpagent   { 'US::SendGrid' }
sub headerlist  { return [ 'Return-Path', 'X-Mailer' ] }
sub pattern     { return $Re0 }

sub scan {
    # Detect an error from SendGrid
    # @param         [Hash] mhead       Message header of a bounce email
    # @options mhead [String] from      From header
    # @options mhead [String] date      Date header
    # @options mhead [String] subject   Subject header
    # @options mhead [Array]  received  Received headers
    # @options mhead [String] others    Other required headers
    # @param         [String] mbody     Message body of a bounce email
    # @return        [Hash, Undef]      Bounce data list and message/rfc822 part
    #                                   or Undef if it failed to parse or the
    #                                   arguments are missing
    # @since v4.0.2
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless $mhead->{'return-path'};
    return undef unless $mhead->{'return-path'} =~ $Re0->{'return-path'};
    return undef unless $mhead->{'subject'}     =~ $Re0->{'subject'};

    require Sisimai::DateTime;

    my $dscontents = []; push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
    my @hasdivided = split( "\n", $$mbody );
    my $rfc822next = { 'from' => 0, 'to' => 0, 'subject' => 0 };
    my $rfc822part = '';    # (String) message/rfc822-headers part
    my $previousfn = '';    # (String) Previous field name
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $commandtxt = '';    # (String) SMTP Command name begin with the string '>>>'
    my $connvalues = 0;     # (Integer) Flag, 1 if all the value of $connheader have been set
    my $connheader = {
        'date'    => '',    # The value of Arrival-Date header
    };

    my $v = undef;
    my $p = '';

    for my $e ( @hasdivided ) {
        # Read each line between $Re1->{'begin'} and $Re1->{'rfc822'}.
        unless( $readcursor ) {
            # Beginning of the bounce message or delivery status part
            if( $e =~ $Re1->{'begin'} ) {
                $readcursor |= $Indicators->{'deliverystatus'};
                next;
            }
        }

        unless( $readcursor & $Indicators->{'message-rfc822'} ) {
            # Beginning of the original message part
            if( $e =~ $Re1->{'rfc822'} ) {
                $readcursor |= $Indicators->{'message-rfc822'};
                next;
            }
        }

        if( $readcursor & $Indicators->{'message-rfc822'} ) {
            # After "message/rfc822"
            if( $e =~ m/\A([-0-9A-Za-z]+?)[:][ ]*.+\z/ ) {
                # Get required headers only
                my $lhs = lc $1;
                $previousfn = '';
                next unless exists $RFC822Head->{ $lhs };

                $previousfn  = $lhs;
                $rfc822part .= $e."\n";

            } elsif( $e =~ m/\A[\s\t]+/ ) {
                # Continued line from the previous line
                next if $rfc822next->{ $previousfn };
                $rfc822part .= $e."\n" if exists $LongFields->{ $previousfn };

            } else {
                # Check the end of headers in rfc822 part
                next unless exists $LongFields->{ $previousfn };
                next if length $e;
                $rfc822next->{ $previousfn } = 1;
            }

        } else {
            # Before "message/rfc822"
            next unless $readcursor & $Indicators->{'deliverystatus'};
            next unless length $e;

            if( $connvalues == scalar( keys %$connheader ) ) {
                # Final-Recipient: rfc822; kijitora@example.jp
                # Original-Recipient: rfc822; kijitora@example.jp
                # Action: failed
                # Status: 5.1.1
                # Diagnostic-Code: 550 5.1.1 <kijitora@example.jp>... User Unknown 
                $v = $dscontents->[ -1 ];

                if( $e =~ m/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/ ) {
                    # Final-Recipient: RFC822; userunknown@example.jp
                    if( length $v->{'recipient'} ) {
                        # There are multiple recipient addresses in the message body.
                        push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                        $v = $dscontents->[ -1 ];
                    }
                    $v->{'recipient'} = $1;
                    $recipients++;

                } elsif( $e =~ m/\A[Aa]ction:[ ]*(.+)\z/ ) {
                    # Action: failed
                    $v->{'action'} = lc $1;

                } elsif( $e =~ m/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/ ) {
                    # Status: 5.1.1
                    # Status:5.2.0
                    # Status: 5.1.0 (permanent failure)
                    $v->{'status'} = $1;

                } else {

                    if( $e =~ m/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+)\z/ ) {
                        # Diagnostic-Code: 550 5.1.1 <userunknown@example.jp>... User Unknown
                        $v->{'diagnosis'} = $1;

                    } elsif( $p =~ m/\A[Dd]iagnostic-[Cc]ode:[ ]*/ && $e =~ m/\A[\s\t]+(.+)\z/ ) {
                        # Continued line of the value of Diagnostic-Code header
                        $v->{'diagnosis'} .= ' '.$1;
                        $e = 'Diagnostic-Code: '.$e;
                    }
                }

            } else {
                # This is an automatically generated message from SendGrid.
                # 
                # I'm sorry to have to tell you that your message was not able to be
                # delivered to one of its intended recipients.
                #
                # If you require assistance with this, please contact SendGrid support.
                # 
                # shironekochan:000000:<kijitora@example.jp> : 192.0.2.250 : mx.example.jp:[192.0.2.153] :
                #   550 5.1.1 <userunknown@cubicroot.jp>... User Unknown  in RCPT TO
                # 
                # ------------=_1351676802-30315-116783
                # Content-Type: message/delivery-status
                # Content-Disposition: inline
                # Content-Transfer-Encoding: 7bit
                # Content-Description: Delivery Report
                #
                # X-SendGrid-QueueID: 959479146
                # X-SendGrid-Sender: <bounces+61689-10be-kijitora=example.jp@sendgrid.info>
                # Arrival-Date: 2012-12-31 23-59-59
                if( $e =~ m{.+ in (?:End of )?([A-Z]{4}).*\z} ) {
                    # in RCPT TO, in MAIL FROM, end of DATA
                    $commandtxt = $1;

                } elsif( $e =~ m/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/ ) {
                    # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                    next if length $connheader->{'date'};
                    my $r = $1;

                    if( $e =~ m/\A[Aa]rrival-[Dd]ate: (\d{4})[-](\d{2})[-](\d{2}) (\d{2})[-](\d{2})[-](\d{2})\z/ ) {
                        # Arrival-Date: 2011-08-12 01-05-05
                        $r .= 'Thu, '.$3.' ';
                        $r .= Sisimai::DateTime->monthname(0)->[ int($2) - 1 ];
                        $r .= ' '.$1.' '.join( ':', $4, $5, $6 );
                        $r .= ' '.Sisimai::DateTime->abbr2tz('CDT');
                    }
                    $connheader->{'date'} = $r;
                    $connvalues++;
                }
            }
        } # End of if: rfc822

    } continue {
        # Save the current line for the next loop
        $p = $e;
        $e = '';
    }

    return undef unless $recipients;
    require Sisimai::String;
    require Sisimai::SMTP::Status;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{'diagnosis'} = Sisimai::String->sweep( $e->{'diagnosis'} );

        if( $e->{'status'} ) {
            # Check softbounce or not
            $e->{'softbounce'} = 1 if $e->{'status'} =~ m/\A4[.]/;

        } else {
            # Get the value of SMTP status code as a pseudo D.S.N.
            if( $e->{'diagnosis'} =~ m/\b([45])\d\d\s*/ ) {
                # 4xx or 5xx
                $e->{'softbounce'} = 1 if $1 == 4;
                $e->{'status'} = sprintf( "%d.0.0", $1 );
            }
        }

        if( $e->{'status'} =~ m/[45][.]0[.]0/ ) {
            # Get the value of D.S.N. from the error message or the value of
            # Diagnostic-Code header.
            my $r = Sisimai::SMTP::Status->find( $e->{'diagnosis'} );
            $e->{'status'} = $r if length $r;
        }

        if( $e->{'action'} eq 'expired' ) {
            # Action: expired
            $e->{'reason'} = 'expired';
            if( ! $e->{'status'} || $e->{'status'} =~ m/[45][.]0[.]0/ ) {
                # Set pseudo Status code value if the value of Status is not
                # defined or 4.0.0 or 5.0.0.
                my $r = Sisimai::SMTP::Status->code('expired');
                $e->{'status'} = $r if length $r;
            }
        } 

        if( scalar @{ $mhead->{'received'} } ) {
            # Get localhost and remote host name from Received header.
            my $r = $mhead->{'received'};
            $e->{'lhost'} ||= shift @{ Sisimai::RFC5322->received( $r->[0] ) };
            $e->{'rhost'} ||= pop @{ Sisimai::RFC5322->received( $r->[-1] ) };
        }

        $e->{'spec'}    ||= 'SMTP';
        $e->{'agent'}     = __PACKAGE__->smtpagent;
        $e->{'command'} ||= $commandtxt;
    }
    return { 'ds' => $dscontents, 'rfc822' => $rfc822part };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::MSP::US::SendGrid - bounce mail parser class for C<SendGrid>.

=head1 SYNOPSIS

    use Sisimai::MSP::US::SendGrid;

=head1 DESCRIPTION

Sisimai::MSP::US::SendGrid parses a bounce email which created by C<SendGrid>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::MSP::US::SendGrid->description;

=head2 C<B<smtpagent()>>

C<smtpagent()> returns MTA name.

    print Sisimai::MSP::US::SendGrid->smtpagent;

=head2 C<B<scan( I<header data>, I<reference to body string>)>>

C<scan()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2015 azumakuniyuki E<lt>perl.org@azumakuniyuki.orgE<gt>,
All Rights Reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
