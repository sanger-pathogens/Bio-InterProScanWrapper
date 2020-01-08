#!/usr/bin/env perl

use strict;
use warnings;
use Moose;
use Data::Dumper;
use Cwd;
use File::Copy;

with 'TestHelper';

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::CommandLine::ExtractGoFromInterProOutput');
}

my $script_name = 'Bio::InterProScanWrapper::CommandLine::ExtractGoFromInterProOutput';
my $cwd = getcwd();

copy_files_for_tests($cwd . '/t/data/input_annotation.gff', $cwd);
copy_files_for_tests($cwd . '/t/data/input_annotation.gff.iprscan.gff', $cwd);
my %scripts_and_expected_files = (
    '-i input_annotation.gff.iprscan.gff -d t/data/gene_ontology_subset.obo' => 
        [ ['input_annotation.gff.iprscan.gff.go.tsv', 'input_annotation.gff.iprscan.gff.go.summary.tsv'],['t/data/expected.go.tsv', 't/data/expected.go.summary.tsv'] ],
    '-i input_annotation.gff.iprscan.gff -e input_annotation.gff -d t/data/gene_ontology_subset.obo' => 
        [ ['input_annotation.gff.iprscan.gff.go.tsv', 'input_annotation.gff.iprscan.gff.go.summary.tsv', 'input_annotation.gff.go.gff'],['t/data/expected.go.tsv', 't/data/expected.go.summary.tsv', 't/data/expected.go.gff'] ],
);

mock_execute_script_and_check_sorted_output( $script_name, \%scripts_and_expected_files );

unlink($cwd . '/input_annotation.gff.iprscan.gff');
unlink($cwd . '/input_annotation.gff');

done_testing();
