use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai::MTA::Postfix;

my $PackageName = 'Sisimai::MTA::Postfix';
my $EmailPrefix = 'postfix';
my $MethodNames = {
    'class' => [ 
        'version', 'description', 'headerlist', 'scan',
        'SMTPCOMMAND', 'DELIVERYSTATUS', 'RFC822HEADERS',
    ],
    'object' => [],
};
my $ReturnValue = {
    '01' => { 'status' => qr/\A5[.]1[.]1\z/, 'reason' => qr/mailererror/ },
    '02' => { 'status' => qr/\A5[.][12][.]1\z/, 'reason' => qr/(?:filtered|userunknown)/ },
    '03' => { 'status' => qr/\A5[.]0[.]0\z/, 'reason' => qr/filtered/ },
    '04' => { 'status' => qr/\A5[.]1[.]1\z/, 'reason' => qr/userunknown/ },
    '05' => { 'status' => qr/\A4[.]1[.]1\z/, 'reason' => qr/userunknown/ },
    '06' => { 'status' => qr/\A5[.]4[.]4\z/, 'reason' => qr/hostunknown/ },
    '07' => { 'status' => qr/\A5[.]0[.]\d+\z/, 'reason' => qr/filtered/ },
    '08' => { 'status' => qr/\A4[.]4[.]1\z/, 'reason' => qr/expired/ },
    '09' => { 'status' => qr/\A4[.]3[.]2\z/, 'reason' => qr/notaccept/ },
    '10' => { 'status' => qr/\A5[.]1[.]8\z/, 'reason' => qr/rejected/ },
    '11' => { 'status' => qr/\A5[.]1[.]8\z/, 'reason' => qr/rejected/ },
    '12' => { 'status' => qr/\A5[.]1[.]1\z/, 'reason' => qr/userunknown/ },
    '13' => { 'status' => qr/\A5[.]2[.][12]\z/, 'reason' => qr/(?:userunknown|mailboxfull)/ },
    '14' => { 'status' => qr/\A5[.]1[.]1\z/, 'reason' => qr/userunknown/ },
    '15' => { 'status' => qr/\A4[.]4[.]1\z/, 'reason' => qr/expired/ },
    '16' => { 'status' => qr/\A5[.]1[.]6\z/, 'reason' => qr/hasmoved/ },
    '17' => { 'status' => qr/\A5[.]4[.]4\z/, 'reason' => qr/networkerror/ },
    '18' => { 'status' => qr/\A5[.]7[.]1\z/, 'reason' => qr/blocked/ },
    '19' => { 'status' => qr/\A5[.]0[.]0\z/, 'reason' => qr/blocked/ },
    '20' => { 'status' => qr/\A5[.]0[.]\d+\z/, 'reason' => qr/undefined/ },
};

use_ok $PackageName;
can_ok $PackageName, @{ $MethodNames->{'class'} };

MAKE_TEST: {
    my $v = undef;
    my $c = 0;

    $v = $PackageName->version;
    ok $v, '->version = '.$v;
    $v = $PackageName->description;
    ok $v, '->description = '.$v;

    $v = $PackageName->smtpagent;
    ok $v, '->smtpagent = '.$v;

    is $PackageName->scan, undef, '->scan';

    use Sisimai::Data;
    use Sisimai::Mail;
    use Sisimai::Message;

    PARSE_EACH_MAIL: for my $n ( 1..20 ) {

        my $emailfn = sprintf( "./eg/maildir-as-a-sample/new/%s-%02d.eml", $EmailPrefix, $n );
        my $mailbox = Sisimai::Mail->new( $emailfn );
        my $emindex = sprintf( "%02d", $n );
        next unless defined $mailbox;
        ok -f $emailfn, 'email = '.$emailfn;

        while( my $r = $mailbox->read ) {

            my $p = Sisimai::Message->new( 'data' => $r );
            my $o = undef;
            isa_ok $p, 'Sisimai::Message';
            isa_ok $p->ds, 'ARRAY';
            isa_ok $p->header, 'HASH';
            isa_ok $p->rfc822, 'HASH';
            ok length $p->from;

            for my $e ( @{ $p->ds } ) {
                ok length $e->{'recipient'}, '->recipient = '.$e->{'recipient'};
                ok length $e->{'diagnosis'}, '->diagnosis = '.$e->{'diagnosis'};
                is $e->{'agent'}, 'Postfix', '->agent = '.$e->{'agent'};

                ok defined $e->{'date'}, '->date = '.$e->{'date'};
                ok defined $e->{'spec'}, '->spec = '.$e->{'spec'};
                ok defined $e->{'reason'}, '->reason = '.$e->{'reason'};
                ok defined $e->{'status'}, '->status = '.$e->{'status'};
                ok defined $e->{'command'}, '->command = '.$e->{'command'};
                ok defined $e->{'action'}, '->action = '.$e->{'action'};
                ok defined $e->{'rhost'}, '->rhost = '.$e->{'rhost'};
                ok defined $e->{'lhost'}, '->lhost = '.$e->{'lhost'};
                ok defined $e->{'alias'}, '->alias = '.$e->{'alias'};
                ok defined $e->{'feedbacktype'}, '->feedbacktype = ""';
                ok defined $e->{'softbounce'}, '->softbounce = '.$e->{'softbounce'};

                like $e->{'recipient'}, qr/[0-9A-Za-z@-_.]+/, '->recipient = '.$e->{'recipient'};
            }

            $o = Sisimai::Data->make( 'data' => $p );
            ok scalar @$o, 'entry = '.scalar @$o;
            for my $e ( @$o ) {
                isa_ok $e, 'Sisimai::Data';
                like $e->deliverystatus, $ReturnValue->{ $emindex }->{'status'}, '->status = '.$e->deliverystatus;
                like $e->reason, $ReturnValue->{ $emindex }->{'reason'}, '->reason = '.$e->reason;
            }
            $c++;
        }
    }
    ok $c, 'the number of emails = '.$c;
}
done_testing;

