#!/usr/bin/perl

# use 5.010;
use strict;
use warnings;

=head1 NAME



=head1 SYNOPSIS

  t/wrap.pl -c # for create

  t/wrap.pl -x # for extract

=head1 OPTIONS

=over 8

=cut

my @opt = <<'=back' =~ /B<-(\S+)>/g;

=item B<-c>

Wrap the test files into wrapper file

=item B<-f>

Path to the wrapper file. Defaults to t/wrapped-tests.bin.

=item B<-help|h!>

This help

=item B<-x>

Unwrap the test files from the wrapper file

=back

=head1 DESCRIPTION

The t/ directory contains tests for different line endings. To
distribute these tests we wrap them into a Data::Dumper file to avoid
problems on distribution verification.

Called with -c we create the wrapping file. Called with -x we unwrap
the files and install them into place.

The test t/3-verify.t calls us with -x.

When anything changes that breaks 3-verify.t, then the procedure to
create new test files is something like the following:

(1) call wrap.pl -x

(2) edit files in t/test*; take care that the files in test-datlf*
    have Unix line endings and the files in test-datcrlf* have DOS
    line endings. Apart from that keep the files identical

(3) sign in t/test-datlf-sigold/ with an old version of Module::Signature

(4) copy the signature over to t/test-datcrlf-sigold/

(5) sign in t/test-datlf-signew/ with the upcoming version of
    Module::Signature

(6) copy the signature over to t/test-datcrlf-signew/

(7) call wrap.pl -c

=cut


use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN {
    push @INC, qw(       );
}

use Data::Dumper;
use File::Basename qw(dirname);
use File::Path qw(mkpath);
use File::Spec;
use Getopt::Long;
use Pod::Usage;

our %Opt;
GetOptions(\%Opt,
           @opt,
          ) or pod2usage(1);

$Opt{f} ||= "t/wrapped-tests.bin";

sub _f ($) {File::Spec->catfile(split /\//, shift);}

my @files = qw(t/test-datcrlf-signew/MANIFEST
t/test-datcrlf-signew/README
t/test-datcrlf-signew/42.gz
t/test-datcrlf-signew/SIGNATURE
t/test-datcrlf-sigold/MANIFEST
t/test-datcrlf-sigold/README
t/test-datcrlf-sigold/42.gz
t/test-datcrlf-sigold/SIGNATURE
t/test-datlf-signew/MANIFEST
t/test-datlf-signew/README
t/test-datlf-signew/42.gz
t/test-datlf-signew/SIGNATURE
t/test-datlf-sigold/MANIFEST
t/test-datlf-sigold/README
t/test-datlf-sigold/42.gz
t/test-datlf-sigold/SIGNATURE
);
my @paths = map { _f($_) } @files;

if ($Opt{c}) {
    my $VAR;
    for my $i (0..$#files) {
        open my $fh, "<", $paths[$i] or die "Could not open '$paths[$i]': $!";
        binmode $fh;
        local $/;
        $VAR->{$files[$i]} = <$fh>;
    }
    my $d = Data::Dumper->new([$VAR]);
    $d->Useqq(1)->Sortkeys(1);
    open my $fh, ">", _f($Opt{f}) or die "Could not open $Opt{f}: $!";
    binmode $fh;
    print $fh $d->Dump;
} elsif ($Opt{x}) {
    open my $fh, "<", _f($Opt{f}) or die "Could not open $Opt{f}: $!";
    binmode $fh;
    local $/;
    my $VAR1;
    eval <$fh>;
    close $fh;
    for my $i (0..$#files) {
        mkpath dirname $paths[$i];
        open my $fh, ">", $paths[$i] or die "Could not open '$paths[$i]': $!";
        binmode $fh;
        local $\;
        print $fh $VAR1->{$files[$i]};
        close $fh or die "Could not write $paths[$i]: $!";
    }
} else {
    warn "Either of the options -x or -c must be specified";
    pod2usage(1);
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
