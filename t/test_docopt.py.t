use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper;
use Docopt;
use Data::Dumper;

sub Option { Docopt::Option->new(@_) }
sub Argument { Docopt::Argument->new(@_) }

sub Optional { Docopt::Optional->new(\@_) }
sub Either { Docopt::Either->new(\@_) }
sub Required { Docopt::Required->new(\@_) }
sub OneOrMore { Docopt::OneOrMore->new(\@_) }
sub OptionsShortcut() { Docopt::OptionsShortcut->new(\@_) }

sub Tokens { Docopt::Tokens->new(\@_) }

sub None() { undef }
sub True() { \1 }
sub False() { \0 }

subtest 'test_pattern_flat' => sub {
    test_pattern_flat(
        Required(OneOrMore(Argument('N')),
                        Option('-a'), Argument('M')),
        [Argument('N'), Option('-a'), Argument('M')],
    );
    test_pattern_flat(
        Required(Optional(OptionsShortcut()),
                                Optional(Option('-a', None))),
        [OptionsShortcut()],
        Docopt::OptionsShortcut::
    );
};

subtest 'test_option' => sub {
    test_option(
        '-h',
        ['-h', None]
    );
    test_option(
        '--help',
        [None, '--help'],
    );
    test_option(
        '-h --help',
        ['-h', '--help'],
    );
    test_option(
        '-h, --help',
        ['-h', '--help'],
    );

    test_option(
        '-h TOPIC',
        ['-h', None, 1]
    );
    test_option(
        '--help TOPIC',
        [None, '--help', 1]
    );
    test_option(
        '-h TOPIC --help TOPIC',
        ['-h', '--help', 1]
    );
    test_option(
        '-h TOPIC, --help=TOPIC',
        ['-h', '--help', 1]
    );
    test_option(
        '-h  Description...',
        ['-h', None]
    );
    test_option(
        '-h --help  Description...',
        ['-h', '--help']
    );
    test_option(
        '-h TOPIC  Description...',
        ['-h', None, 1]
    );
    test_option(
        '    -h',
        ['-h', None]
    );


    test_option('-h TOPIC  Descripton... [default: 2]',
               ['-h', None, 1, '2']);
    test_option('-h TOPIC  Descripton... [default: topic-1]',
               ['-h', None, 1, 'topic-1']);
    test_option('--help=TOPIC  ... [default: 3.14]',
               [None, '--help', 1, '3.14']);
    test_option('-h, --help=DIR  ... [default: ./]',
               ['-h', '--help', 1, "./"]);
    test_option('-h TOPIC  Descripton... [dEfAuLt: 2]',
               ['-h', None, 1, '2']);
};

subtest 'test_option_name' => sub {
    is(Option('-h', None)->name, '-h');
    is(Option('-h', '--help')->name, '--help');
    is(Option(None, '--help')->name, '--help');
};

# TODO: test_commands

subtest 'test_formal_usage' => sub {
    my $doc = "
    Usage: prog [-hv] ARG
           prog N M

    prog is a program.";
    my ($usage,) = Docopt::parse_section('usage:', $doc);
    is($usage, "Usage: prog [-hv] ARG\n           prog N M");
    is(Docopt::formal_usage($usage), "( [-hv] ARG ) | ( N M )");
};

subtest 'parse_argv' => sub {
    test_parse_argv(
        [],
        []
    );

    test_parse_argv(
        '-h',
        [Option('-h', None, 0, True)],
    );
    test_parse_argv(
        '-h --verbose',
        [Option('-h', None, 0, True), Option('-v', '--verbose', 0, True)],
    );
    test_parse_argv('-h --file f.txt',
            [Option('-h', None, 0, True), Option('-f', '--file', 1, 'f.txt')]);
    test_parse_argv('-h --file f.txt arg',
           [Option('-h', None, 0, True),
            Option('-f', '--file', 1, 'f.txt'),
            Argument(None, 'arg')]);
    test_parse_argv('-h --file f.txt arg arg2',
            [Option('-h', None, 0, True),
             Option('-f', '--file', 1, 'f.txt'),
             Argument(None, 'arg'),
             Argument(None, 'arg2')]);
    test_parse_argv('-h arg -- -v',
            [Option('-h', None, 0, True),
             Argument(None, 'arg'),
             Argument(None, '--'),
             Argument(None, '-v')]);
};

subtest 'test_parse_pattern' => sub {
    test_parse_pattern('[ -h ]',
        Required(Optional(Option('-h')))
    );
    test_parse_pattern('[ ARG ... ]',
        Required(Optional(OneOrMore(Argument('ARG')))),
    );
    test_parse_pattern('[ -h | -v ]',
        Required(Optional(Either(Option('-h'),
                                    Option('-v', '--verbose'))))
    );
    test_parse_pattern('[ --file <f> ]',
        Required(Optional(Option('-f', '--file', 1, undef)))
    );
    test_parse_pattern(
        '( -h | -v [ --file <f> ] )',
            Required(Required(
                Either(Option('-h'),
                Required(Option('-v', '--verbose'),
                Optional(Option('-f', '--file', 1, undef))))))
    );
    test_parse_pattern('(-h|-v[--file=<f>]N...)',
        Required(Required(Either(Option('-h'),
            Required(Option('-v', '--verbose'),
            Optional(Option('-f', '--file', 1, undef)),
            OneOrMore(Argument('N')))))),
    );
    test_parse_pattern('(N [M | (K | L)] | O P)',
        Required(Required(Either(
                        Required(Argument('N'),
                                    Optional(Either(Argument('M'),
                                                    Required(Either(Argument('K'),
                                                                    Argument('L')))))),
                        Required(Argument('O'), Argument('P')))))
    );
    test_parse_pattern('[ -h ] [N]',
        Required(Optional(Option('-h')),
                    Optional(Argument('N'))));
    test_parse_pattern(
        '[options]',
        Required(Optional(OptionsShortcut())),
    );
    test_parse_pattern('[options] A',
        Required(Optional(OptionsShortcut()), Argument('A')));
    test_parse_pattern('-v [options]',
        Required(Option('-v', '--verbose'),
                                    Optional(OptionsShortcut())));
    test_parse_pattern('ADD',
        Required(Argument('ADD')));
    test_parse_pattern('<add>',
        Required(Argument('<add>')));
};

subtest test_options_match => sub {
    test_options_match(
        [Option('-a')->match([Option('-a', True)])],
            [True, [], [Option('-a', True)]]
    );
    test_options_match([Option('-a')->match([Option('-x')])], [False, [Option('-x')], []]);
    test_options_match([Option('-a')->match([Argument('N')])], [False, [Argument('N')], []]);
    test_options_match([Option('-a')->match([Option('-x'), Option('-a'), Argument('N')])],
            [True, [Option('-x'), Argument('N')], [Option('-a')]]);
    test_options_match([Option('-a')->match([Option('-a', True), Option('-a')])],
            [True, [Option('-a')], [Option('-a', True)]]);
};

subtest 'test_argument_match' => sub {
    test_argument_match(
        [Argument('N')->match([Argument(None, 9)])],
        [True, [], [Argument('N', 9)]]
    );
    test_argument_match(
        [Argument('N')->match([Option('-x')])],
        [False, [Option('-x')], []]
    );
    test_argument_match(
        [Argument('N')->match([Option('-x'),
                                Option('-a'),
                                Argument(None, 5)])],
        [True, [Option('-x'), Option('-a')], [Argument('N', 5)]]
    );
    test_argument_match(
        [Argument('N')->match([Argument(None, 9), Argument(None, 0)])],
        [True, [Argument(None, 0)], [Argument('N', 9)]]
    );
};

done_testing;

sub test_pattern_flat {
    my ($input, $expected, $types) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Docopt::DocoptExit=0;
    my $got = $input->flat($types);
    is_deeply(
        $got,
        $expected,
    ) or diag Dumper($got);
}

sub test_option {
    my ($input, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply(
        Docopt::Option->parse($input),
        Docopt::Option->new(@$expected),
        $input,
    );
}

sub test_parse_argv {
    my ($input, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $o = [Option('-h'), Option('-v', '--verbose'), Option('-f', '--file', 1)];
    my $got = Docopt::parse_argv(Docopt::Tokens->new($input), $o);
    is_deeply(
        $got,
        $expected
    ) or diag Dumper($got);
}

sub test_parse_pattern {
    my ($input, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Docopt::DocoptExit=0;
    my $o = [Option('-h'), Option('-v', '--verbose'), Option('-f', '--file', 1)];
    is(
        Docopt::parse_pattern($input, $o)->__repl__,
        $expected->__repl__,
        $input
    );
}

sub test_options_match {
    my ($got, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Docopt::DocoptExit=0;
    local $Data::Dumper::Purity=0;
    local $Data::Dumper::Terse=1;
    local $Data::Dumper::Deepcopy=1;
    local $Data::Dumper::Sortkeys=1;
    is_deeply(
        $got,
        $expected,
    ) or diag Dumper($got, $expected);
}

sub test_argument_match {
    my ($got, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Docopt::DocoptExit=0;
    local $Data::Dumper::Purity=0;
    local $Data::Dumper::Terse=1;
    local $Data::Dumper::Deepcopy=1;
    local $Data::Dumper::Sortkeys=1;
    is_deeply(
        $got,
        $expected,
    ) or diag Dumper($got, $expected);
}
