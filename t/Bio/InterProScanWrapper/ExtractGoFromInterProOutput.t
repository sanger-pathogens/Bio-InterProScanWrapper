#!/usr/bin/env perl
use Moose;
use Data::Dumper;
use File::Copy;
use Cwd;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::CommandLine::ExtractGoFromInterProOutput');
}

my $script_name = 'Bio::InterProScanWrapper::CommandLine::ExtractGoFromInterProOutput';
my $cwd = getcwd();

copy($cwd . '/t/data/input_annotation.gff', $cwd . '/input_annotation.gff');
copy($cwd . '/t/data/input_annotation.gff.iprscan.gff', $cwd . '/input_annotation.gff.iprscan.gff');

my %scripts_and_expected_files = (
    "-i input_annotation.gff.iprscan.gff" => [ ['input_annotation.gff.iprscan.gff.go.tsv', 'input_annotation.gff.iprscan.gff.go.summary.tsv'],
                                       ['t/data/input_annotation.gff.iprscan.gff.go.tsv', 't/data/input_annotation.gff.iprscan.gff.go.summary.tsv'] ],
    "-i input_annotation.gff.iprscan.gff -e input_annotation.gff" => [ ['input_annotation.gff.iprscan.gff.go.tsv', 'input_annotation.gff.iprscan.gff.go.summary.tsv', 'input_annotation.gff.go.gff'],
                                       ['t/data/input_annotation.gff.iprscan.gff.go.tsv', 't/data/input_annotation.gff.iprscan.gff.go.summary.tsv', 't/data/input_annotation.gff.go.gff'] ],
);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

unlink($cwd . '/input_annotation.gff.iprscan.gff');

done_testing();
