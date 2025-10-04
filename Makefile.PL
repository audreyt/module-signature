# Dist::Zilla::Plugin::MakeMaker::Awesome 0.49.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use ExtUtils::MakeMaker;

use FindBin '$Bin';
use lib $Bin;

$|++;
my %requires;
my %args;
$args{LICENSE} = 'unrestricted';
# clean generated test files
$args{clean} = {FILES => "t/test-dat*"};

# On Win32 (excluding cygwin) we know that IO::Socket::INET,
# which is needed for keyserver stuff, doesn't work. In fact
# it potentially hangs forever. So bail out with a N/A on
# Win32.
if ( $^O eq 'MSWin32' and 0 ) {
       print "Keyserver behaviour is dangerous unreliable on Win32\n";
       print "Not installing on this platform.\n";
       exit(255);
} else {
       $requires{'IO::Socket::INET'} = 0;
}

# We will need something to handle SHA1/256
unless (
       can_use('Digest::SHA')  or
       can_use('Digest::SHA::PurePerl') or
       (can_use('Digest::SHA1') and can_use('Digest::SHA256'))
) {
       # Nothing installed, we need to install a digest module
       if ( can_cc() ) {
               $requires{'Digest::SHA'} = 0;
       } else {
               $requires{'Digest::SHA::PurePerl'} = 0;
       }
}

# Is openpgp currently installed
if ( can_use ('Crypt::OpenPGP') ) {
       # Crypt::OpenPGP installed/available, continue on...
} elsif ( my $gpg = locate_gpg() ) {
       # We SHOULD have gpg, double-check formally
       requires_external_bin ($gpg);
} elsif ( can_cc() and $ENV{AUTOMATED_TESTING} ) {
       # Dive headlong into a full Crypt::OpenPGP install.
       $requires{'Crypt::OpenPGP'} = 0;
} else {
       # Ask the user what to do
       ask_user();
}

unless ( can_run('diff') ) {
       # We know Text::Diff fails on Cygwin (for now)
       if ( $^O ne 'Cygwin' ) {
               $requires{'Algorithm::Diff'} = 0;
               $requires{'Text::Diff'} = 0;
       }
   }

#####################################################################
# Support Functions

sub locate_gpg {
       print "Looking for GNU Privacy Guard (gpg), a cryptographic signature tool...\n";

       my ($gpg, $gpg_path);
       for my $gpg_bin ('gpg', 'gpg2', 'gnupg', 'gnupg2') {
               $gpg_path = can_run($gpg_bin);
               next unless $gpg_path;
               next unless `$gpg_bin --version` =~ /GnuPG/;
               next unless defined `$gpg_bin --list-public-keys`;

               $gpg = $gpg_bin;
               last;
       }
       unless ( $gpg ) {
               print "gpg not found.\n";
               return;
       }

       print "GnuPG found ($gpg_path).\n";

       return 1 if grep { /^--installdeps/} @ARGV;

       if ( prompt("Import PAUSE and author keys to GnuPG?", 'y' ) =~ /^y/i) {
               print 'Importing... ';
               system $gpg, '--quiet', '--import', qw[ AUDREYT2018.pub ANDK2020.pub PAUSE2022.pub NIKLASHOLM2018.pub TIMLEGGE2024.pub ];
               print "done.\n";
       }

       return $gpg;
}

sub ask_user {

    # Defined the prompt messages
    my $message1 = <<'END_MESSAGE';

Could not auto-detect a signature utility on your system.

What do you want me to do?

1) Let you install GnuPG manually while I'm waiting for your answer;
   it is available at http://www.gnupg.org/download/ or may be available
   from your platforms packaging system (for Open Source platforms).

END_MESSAGE

    my $message2 = <<'END_MESSAGE';

2) Automatically install Crypt::OpenPGP and the 20 modules it requires
   from CPAN, which will give the same functionality as GnuPG.

END_MESSAGE

       # Present the options
       print $message1;

       my $option3 = 2;
       if ( can_cc() ) {
               $option3 = 3;
               print $message2;
       }

       print <<"END_MESSAGE";

$option3) Forget this cryptographic signature stuff for now.

END_MESSAGE

       my $choice;
       foreach ( 1 .. 3 ) {
               $choice = prompt("Your choice:", 3) || 3;
               last if $choice =~ /^[123]$/;
               print "Sorry, I cannot understand '$choice'.\n"
       }

       if ( $choice == 1 ) {
               # They claim to have installed gpg
               requires_external_bin ('gpg');
       } elsif ( $choice == 2 and $option3 == 3 ) {
               # They want to install Crypt::OpenPGP
               $requires{'Crypt::OpenPGP'} = 0;
       } else {
               # Forget about it...
               print "Module::Signature is not wanted on this host.\n";
               exit(0);
       }
}

# check if we can load some module
### Upgrade this to not have to load the module if possible
sub can_use {
        my ($mod, $ver) = @_;
        $mod =~ s{::|\\}{/}g;
        $mod .= '.pm' unless $mod =~ /\.pm$/i;
        my $pkg = $mod;
        $pkg =~ s{/}{::}g;
        $pkg =~ s{\.pm$}{}i;
        local $@;
        eval { require $mod; $pkg->VERSION($ver || 0); 1 };
}

# Check if we can run some command
sub can_run {
        my ($cmd) = @_;
        my $_cmd = $cmd;
        return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));
        for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
                next if $dir eq '';
                require File::Spec;
                my $abs = File::Spec->catfile($dir, $cmd);
                return $abs if (-x $abs or $abs = MM->maybe_command($abs));
        }
        return;
}
# Can we locate a (the) C compiler
sub can_cc {
        if ($^O eq 'VMS') {
                require ExtUtils::CBuilder;
                my $builder = ExtUtils::CBuilder->new(
                quiet => 1,
                );
                return $builder->have_compiler;
        }
        my @chunks = split(/ /, $Config::Config{cc}) or return;
        # $Config{cc} may contain args; try to find out the program part
        while (@chunks) {
                return can_run("@chunks") || (pop(@chunks), next);
        }
        return;
}

sub requires_external_bin {
        my ($bin, $version) = @_;
        if ( $version ) {
                die "requires_external_bin does not support versions yet";
        }
        # Load the package containing can_run early,
        # to avoid breaking the message below.
        # Locate the bin
        print "Locating bin:$bin...";
        my $found_bin = can_run( $bin );
        if ( $found_bin ) {
                print " found at $found_bin.\n";
        } else {
                print " missing.\n";
                print "Unresolvable missing external dependency.\n";
                print "Please install '$bin' seperately and try again.\n";
                print STDERR "NA: Unable to build distribution on this platform.\n";
                exit(0);
        }
        # Once we have some way to specify external deps, do it here.
        # In the mean time, continue as normal.
        1;
}

my %WriteMakefileArgs = (
  "ABSTRACT" => "Module signature file manipulation",
  "AUTHOR" => "Audrey Tang <cpan\@audreyt.org>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.36",
    "IPC::Run" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.36"
  },
  "DISTNAME" => "Module-Signature",
  "EXE_FILES" => [
    "script/cpansign"
  ],
  "LICENSE" => "perl",
  "NAME" => "Module::Signature",
  "PREREQ_PM" => {
    "File::Temp" => 0
  },
  "VERSION" => "0.94",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    %args,
    PREREQ_PM => {%{$WriteMakefileArgs{PREREQ_PM}}, %requires},
);

my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => "6.36",
  "File::Temp" => 0,
  "IPC::Run" => 0,
  "Test::More" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
