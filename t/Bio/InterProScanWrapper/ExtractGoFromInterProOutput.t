#!/usr/bin/env perl

use strict;
use warnings;
use Moose;
use Test::Files qw(compare_ok);
use Cwd;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::ExtractGoFromInterProOutput');
}

my $script_name = 'Bio::InterProScanWrapper::CommandLine::ExtractGoFromInterProOutput';
my $cwd = getcwd();
$ENV{'GO_OBO'} = $cwd . '/t/data/gene_ontology_subset.obo';

copy_files_for_tests($cwd . '/t/data/input_annotation.gff', $cwd);
copy_files_for_tests($cwd . '/t/data/input_annotation.gff.iprscan.gff', $cwd);

ok( my $obj = Bio::InterProScanWrapper::ExtractGoFromInterProOutput->new(
    iprscan_file      => 'input_annotation.gff.iprscan.gff',
    ontology_database => $cwd . '/t/data/gene_ontology_subset.obo'
), 'initialise object');
ok( $obj->run, 'Produce GO term list/summary' );

compare_ok(
    't/data/expected.go.tsv', 
    'iprscan_results.gff.go.tsv', 
    'GO terms per gene list as expected'
);

compare_ok(
    't/data/expected.go.summary.tsv',
    'iprscan_results.gff.go.summary.tsv',
    'GO term summary as expected'
);

unlink('input_annotation.gff.proteome.faa');
unlink('iprscan_results.gff.go.tsv');
unlink('iprscan_results.gff.go.summary.tsv');

ok( my $gff_obj = Bio::InterProScanWrapper::ExtractGoFromInterProOutput->new(
    iprscan_file  => 'input_annotation.gff.iprscan.gff',
    gff_file      => 'input_annotation.gff',
    gff_filename  => 'input_annotation.gff.go.gff',
    ontology_database => $cwd . '/t/data/gene_ontology_subset.obo'
), 'initialise object with gff file');
ok( $gff_obj->run, 'Produce GO term list/summary' );

compare_ok(
    't/data/expected.go.tsv',
    'iprscan_results.gff.go.tsv',
    'GO terms per gene list as expected'
);

compare_ok(
    't/data/expected.go.summary.tsv',
    'iprscan_results.gff.go.summary.tsv',
    'GO term summary as expected'
);

compare_ok(
    't/data/expected.go.gff',
    'input_annotation.gff.go.gff',
    'GO term summary as expected'
);

unlink('input_annotation.gff');
unlink('input_annotation.gff.iprscan.gff');
unlink('input_annotation.gff.proteome.faa');
unlink('iprscan_results.gff.go.tsv');
unlink('iprscan_results.gff.go.summary.tsv');
unlink('input_annotation.gff.go.gff');

done_testing();
