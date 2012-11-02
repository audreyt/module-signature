#!/usr/bin/perl -w
use strict;

use Module::Signature;
use Test::More;

if ($^O ne 'cygwin') {
    plan skip_all => "Cygwin only tests";
}
elsif (! $ENV{TEST_CYGWIN_GNUPG} ) {
    plan skip_all => 'Set the environment variable TEST_CYGWIN_GNUPG to enable this test';
}
elsif (! -x '/usr/local/bin/gpg') {
    plan skip_all => '/usr/local/bin/gpg not found';
}

plan tests => 1;

my $version = Module::Signature::_has_gpg();

like($version, qr/^\d+\.\d+\.\d+$/, "gpg version detected");
