use 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

my $shared_dir = "../shared";
my $in_source_repo = -d "../../.git" && -d $shared_dir;

my $module = "Sereal::Merger";

unshift @INC, ".", "./inc";
unshift @INC, $shared_dir, "$shared_dir/inc" if $in_source_repo;
require inc::Sereal::BuildTools;
inc::Sereal::BuildTools::link_files($shared_dir) if $in_source_repo;
inc::Sereal::BuildTools::generate_constant_includes($module) if $in_source_repo;

# TODO Configure/optimize for miniz:
#   * Important: For best perf. be sure to customize the below macros for your target platform:
#     #define MINIZ_USE_UNALIGNED_LOADS_AND_STORES 1
#     #define MINIZ_LITTLE_ENDIAN 1
#     #define MINIZ_HAS_64BIT_REGISTERS 1

my $optimize = inc::Sereal::BuildTools::build_optimize();

my $libs = '';
my $subdirs = [];
my $objects = '$(BASEEXT)$(OBJ_EXT) srl_merger$(OBJ_EXT)';
my $defines = inc::Sereal::BuildTools::build_defines();

# Prefer external libraries over the bundled one.
inc::Sereal::BuildTools::check_external_libraries(\$libs, \$defines, \$objects, $subdirs);

if ($defines !~ /HAVE_CSNAPPY/) {
    # from Compress::Snappy
    require Devel::CheckLib;
    my $ctz = Devel::CheckLib::check_lib(
        lib      => 'c',
        function => 'return (__builtin_ctzll(0x100000000LL) != 32);'
    ) ? '-DHAVE_BUILTIN_CTZ' : '';
    $defines .= " $ctz" if $ctz;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
inc::Sereal::BuildTools::WriteMakefile(
    MIN_PERL_VERSION => '5.008',
    META_MERGE => {
        resources => {
            repository => {
              url => 'git://github.com/Sereal/Sereal.git',
            },
            bugtracker => {
              web => 'https://github.com/Sereal/Sereal/issues',
            },
        },
        'meta-spec' => { version => 2 },
    },
    BUILD_REQUIRES => {
        'File::Find' => 0,
        'File::Path' => 0,
        'Sereal::Encoder' => '4.000',
        'Sereal::Decoder' => '4.000',
        'ExtUtils::ParseXS' => '2.21',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.0',
    },
    NAME              => $module,
    VERSION_FROM      => 'lib/Sereal/Merger.pm', # finds $VERSION
    PREREQ_PM         => {
        'XSLoader' => 0,
    }, # e.g., Module::Name => 1.1
    LICENSE => 'perl',
    ABSTRACT_FROM => 'lib/Sereal/Merger.pm',
    AUTHOR => 'Ivan Kruglov <ivan.kruglov@yahoo.com>',
    LIBS              => [$libs], # e.g., '-lm'
    DEFINE            => $defines,
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OPTIMIZE          => $optimize,
    OBJECT            => $objects,
    DIR               => $subdirs,
);
$ENV{OPTIMIZE} = $optimize;
