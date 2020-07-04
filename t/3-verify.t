#!perl

use strict;
use File::Spec;
use Test::More;
use IPC::Run qw(run);

if (eval { require Crypt::OpenPGP; 1 }) {
    plan skip_all => "GnuPG only tests";
    exit 0;
}

plan tests => 6;

$|=1;
sub _f ($) {File::Spec->catfile(split /\//, shift);}
0 == system $^X, _f"t/wrap.pl", "-x" or die;
for my $tdir (glob("t/test-dat*")) {
    chdir $tdir or die;
    my @system = ($^X, "-I../../lib/", "../../script/cpansign", "-v");
    my($in,$out,$err);
    run \@system, \$in, \$out, \$err;
    my $ret = $?;
    close $out;
    my $diff = join "\n", grep /^.SHA\d/, split /\n/, $out;
    $err =~ s/Old SIGNATURE detected.*newer\.//;
    ok(0==$ret, "dir[$tdir]system[@system]ret[$ret]out[$out]err[$err]diff[$diff]");
    chdir "../../" or die;
}
