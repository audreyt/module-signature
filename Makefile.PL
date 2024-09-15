use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Module signature file manipulation",
  "AUTHOR" => "Audrey Tang <cpan\@audreyt.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Module-Signature",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Module::Signature",
  "PREREQ_PM" => {
    "Crypt::OpenPGP" => 0,
    "Crypt::OpenPGP::KeyServer" => 0,
    "Exporter" => 0,
    "ExtUtils::Manifest" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Socket::INET" => 0,
    "Text::Diff" => 0,
    "constant" => 0,
    "strict" => 0,
    "vars" => 0,
    "version" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Basename" => 0,
    "File::Path" => 0,
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "IPC::Run" => 0,
    "Pod::Usage" => 0,
    "Socket" => 0,
    "Test::More" => 0,
    "lib" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.90",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Crypt::OpenPGP" => 0,
  "Crypt::OpenPGP::KeyServer" => 0,
  "Data::Dumper" => 0,
  "Exporter" => 0,
  "ExtUtils::Manifest" => 0,
  "File::Basename" => 0,
  "File::Path" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "Getopt::Long" => 0,
  "IO::Socket::INET" => 0,
  "IPC::Run" => 0,
  "Pod::Usage" => 0,
  "Socket" => 0,
  "Test::More" => 0,
  "Text::Diff" => 0,
  "constant" => 0,
  "lib" => 0,
  "strict" => 0,
  "vars" => 0,
  "version" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
