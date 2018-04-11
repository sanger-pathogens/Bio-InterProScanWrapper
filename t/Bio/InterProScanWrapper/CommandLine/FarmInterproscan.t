#!/usr/bin/env perl
use Moose;
use Cwd;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::CommandLine::FarmInterproscan');
}

my $script_name = 'Bio::InterProScanWrapper::CommandLine::FarmInterproscan';
my $cwd = getcwd();
$ENV{'GO_OBO'} = $cwd . '/t/data/go_ontology_subset.obo';

copy_files_for_tests($cwd . '/t/data/input_annotation.gff', $cwd);
my %scripts_and_expected_files = (
    '-a t/data/input_proteins.faa -e '.$cwd.'/t/bin/dummy_interproscan --no_lsf' =>
      [ ['input_proteins.faa.iprscan.gff'], ['t/data/dummy_merged_annotation.gff'] ],
    '-a input_annotation.gff -e '.$cwd.'/t/bin/dummy_interproscan -g -c 11 --no_lsf' =>
      [ ['input_annotation.gff.iprscan.gff'], ['t/data/dummy_merged_annotation.iprscan.gff'] ],
);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

unlink('input_annotation.gff');
unlink('input_annotation.gff.go.gff');
unlink('input_annotation.gff.iprscan.gff.go.summary.tsv');
unlink('input_annotation.gff.iprscan.gff.go.tsv');

done_testing();

