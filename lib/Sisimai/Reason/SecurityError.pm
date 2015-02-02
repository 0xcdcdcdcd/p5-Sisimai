package Sisimai::Reason::SecurityError;
use feature ':5.10';
use strict;
use warnings;

sub text  { 'securityerror' }
sub match {
    my $class = shift;
    my $argvs = shift // return undef;
    my $regex = qr{(?>
         ["]The[ ]mail[ ]server[ ]detected[ ]your[ ]message[ ]as[ ]spam[ ]and[ ]
            has[ ]prevented[ ]delivery[.]["]    # CPanel/Exim with SA rejections on
        |authentication[ ](?:
             failed;[ ]server[ ].+[ ]said:  # Postfix
            |turned[ ]on[ ]in[ ]your[ ]email[ ]client
            )
        |\d+[ ]denied[ ]\[[a-z]+\][ ].+[(]Mode:[ ].+[)]
        |because[ ](?>
             the[ ]recipient[ ]is[ ]not[ ]accepting[ ]mail[ ]with[ ](?:
                 attachments        # AOL Phoenix
                |embedded[ ]images  # AOL Phoenix
                )
            )
        |blocked[ ]by[ ](?:
             policy:[ ]no[ ]spam[ ]please
            |spamAssassin                   # rejected by SpamAssassin
            )
        |cyberoam[ ]anti[ ]spam[ ]engine[ ]has[ ]identified[ ]this[ ]email[ ]as[ ]a[ ]bulk[ ]email
        |denied[ ]due[ ]to[ ]spam[ ]list
        |domain[ ].+[ ]is[ ]a[ ]dead[ ]domain
        |dt:spm[ ]mx.+[ ]http://mail[.]163[.]com/help/help_spam_16[.]htm
        |email[ ](?:
             not[ ]accepted[ ]for[ ]policy[ ]reasons
            # http://kb.mimecast.com/Mimecast_Knowledge_Base/Administration_Console/Monitoring/Mimecast_SMTP_Error_Codes#554
            |rejected[ ]due[ ]to[ ]security[ ]policies
            )
        |insecure[ ]mail[ ]relay
        |mail[ ](?:
             appears[ ]to[ ]be[ ]unsolicited    # rejected due to spam
            |content[ ]denied   # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000726
            )
        |message[ ](?:
             filtered
            |filtered[.][ ]please[ ]see[ ]the[ ]faqs[ ]section[ ]on[ ]spam
            |rejected[ ]due[ ]to[ ]suspected[ ]spam[ ]content
            |refused[ ]by[ ]mailmarshal[ ]spamprofiler
            )
        |our[ ]filters[ ]rate[ ]at[ ]and[ ]above[ ].+[ ]percent[ ]probability[ ]of[ ]being[ ]spam
        |rejected(?:
             :[ ]spamassassin[ ]score[ ]
            |[ ]due[ ]to[ ]spam[ ]content
            )
        |rejecting[ ]banned[ ]content 
        |sorry,[ ](?:
             that[ ]domain[ ]isn'?t[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthosts
            |you[ ]don'?t[ ]authenticate[ ]or[ ]the[ ]domain[ ]isn'?t[ ]in[ ]
                my[ ]list[ ]of[ ]allowed[ ]rcpthosts
            )
        |spam[ ](?:
             detected
            |email[ ]not[ ]accepted
            |message[ ]rejected[.]       # mail.ru
            |not[ ]accepted
            )
        |spambouncer[ ]identified[ ]spam # SpamBouncer identified SPAM
        |the[ ]message[ ]was[ ]rejected[ ]because[ ]it[ ]contains[ ]prohibited[ ]
            virus[ ]or[ ]spam[ ]content
        |transaction[ ]failed[ ]spam[ ]message[ ]not[ ]queued
        |we[ ]dont[ ]accept[ ]spam
        |your[ ](?:
             email[ ]is[ ]considered[ ]spam
            |message[ ]has[ ]been[ ]temporarily[ ]blocked[ ]by[ ]our[ ]filter
            |network[ ]is[ ]temporary[ ]blacklisted
            )
        )
    }ix;

    return 1 if $argvs =~ $regex;
    return 0;
}

sub true { return undef };

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::SecurityError - Bounce reason is C<securityerror> or not.

=head1 SYNOPSIS

    use Sisimai::Reason::SecurityError;
    print Sisimai::Reason::SecurityError->match('5.7.1 Email not accept');   # 1

=head1 DESCRIPTION

Sisimai::Reason::SecurityError checks the bounce reason is C<securityerror> or not.
This class is called only Sisimai::Reason class.

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> returns string: C<securityerror>.

    print Sisimai::Reason::SecurityError->text;  # securityerror

=head2 C<B<match( I<string> )>>

C<match()> returns 1 if the argument matched with patterns defined in this class.

    print Sisimai::Reason::SecurityError->match('5.7.1 Email not accept');   # 1

=head2 C<B<true( I<Sisimai::Data> )>>

C<true()> returns 1 if the bounce reason is C<securityerror>. The argument must be
Sisimai::Data object and this method is called only from Sisimai::Reason class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2015 azumakuniyuki E<lt>perl.org@azumakuniyuki.orgE<gt>,
All Rights Reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
