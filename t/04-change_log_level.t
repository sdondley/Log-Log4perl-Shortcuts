#/usr/bin/env perl
use Test::More;
use Test::Warn;
use Test::Fatal;
use Data::Dumper;
use Test::Exception;
use Test::NoWarnings;
use lib '/Users/stevedondley/perl/modules/Log-Log4perl-Shortcuts/lib';
use Log::Log4perl::Shortcuts qw(:all);
diag( "Running my tests" );






my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;
logt('tracing');
set_log_level('debug');
logt('tracing');
logt('skdfj', 'cat');
