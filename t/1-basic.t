#!/usr/bin/perl

use strict;
use Test::More tests => 2;

use_ok('Module::Signature');
Module::Signature->import('SIGNATURE_OK');
ok(defined(&SIGNATURE_OK), 'constant exported');

__END__
