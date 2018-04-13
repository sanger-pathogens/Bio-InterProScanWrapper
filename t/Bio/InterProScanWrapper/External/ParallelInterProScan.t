#!/usr/bin/env perl
use strict;
use warnings;
use Test::Files qw(compare_ok);
use File::Basename;
use File::Copy;
use File::Temp;
use Cwd;
use Moose;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::External::ParallelInterProScan');
}

my $cwd = getcwd();
#$ENV{'GO_OBO'} = $cwd . '/t/data/gene_ontology_subset.obo';

my $tmp_obj = File::Temp->newdir( DIR =>$cwd );
my $tmp_dir = $tmp_obj->dirname();
copy_seq_files_to_tmpdir($cwd, $tmp_dir);
ok(my $protein_obj = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
     input_file       => $cwd . '/t/data/input_proteins.faa',
     input_is_gff     => 0,
     protein_file     => $cwd . '/t/data/input_proteins.faa',
     protein_files_path => $tmp_dir . '/interpro*.seq',
     output_file      => $cwd . '/input_proteins.faa.iprscan.gff',
     temp_directory_name => $tmp_dir,
     exec             => $cwd . '/t/bin/dummy_interproscan',
     cpus             => 2,
 ), 'initalise protein input object'
);

is($protein_obj->_cmd, 'nice parallel  -j 2 '.$cwd.'/t/bin/dummy_interproscan -f gff3 --goterms --iprlookup --pathways -i {} --outfile {}.out ::: '.$tmp_dir.'/interpro*.seq', 'InterProScan command for protein input constructed as expected');
is($protein_obj->_merge_cmd, 'merge_results_annotate_eukaryotes -a ' . $cwd. '/t/data/input_proteins.faa -o ' . $cwd .'/input_proteins.faa.iprscan.gff --intermediate_output_dir ' . $tmp_dir, 'Merge command for protein input constructed as expected');
ok($protein_obj->run, 'run the command to see if protein input working as expected');

compare_ok(
    $cwd . '/input_proteins.faa.iprscan.gff',
    't/data/dummy_merged_annotation.gff',
    'got expected iprscan output'
);

$tmp_obj = File::Temp->newdir( DIR =>$cwd );
$tmp_dir = $tmp_obj->dirname();
copy_seq_files_to_tmpdir($cwd, $tmp_dir);
ok(my $gff_obj = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
     input_file       => $cwd . '/t/data/input_annotation.gff',
     input_is_gff     => 1,
     protein_file     => $cwd . '/input_annotation.gff.proteome.faa',
     protein_files_path => $tmp_dir . '/interpro*.seq',
     output_file      => $cwd . '/input_annotation.gff.iprscan.gff',
     temp_directory_name => $tmp_dir,
     exec             => $cwd . '/t/bin/dummy_interproscan',
     cpus             => 2,
 ), 'initalise GFF input object'
);

is($gff_obj->_cmd, 'nice parallel  -j 2 '.$cwd.'/t/bin/dummy_interproscan -f gff3 --goterms --iprlookup --pathways -i {} --outfile {}.out ::: '.$tmp_dir.'/interpro*.seq', 'InterProScan command for GFF input constructed as expected');
is($gff_obj->_merge_cmd, 'merge_results_annotate_eukaryotes -a ' . $cwd. '/input_annotation.gff.proteome.faa -o ' . $cwd .'/input_annotation.gff.iprscan.gff --intermediate_output_dir ' . $tmp_dir, 'Merge command for GFF input constructed as expected');
is($gff_obj->_go_extraction_cmd, 'extract_interproscan_go_terms -i ' . $cwd . '/input_annotation.gff.iprscan.gff -e ' . $cwd . '/t/data/input_annotation.gff', 'GO term extraction command working as expected');

my @test_output_files = ( $cwd . '/t/data/input_annotation.gff.iprscan.gff',
			  $cwd . '/t/data/input_annotation.gff.proteome.faa'); 
foreach my $test_output_file (@test_output_files) {
    my $dest_file = join( "/", $cwd, basename($test_output_file) );
    copy($test_output_file, $dest_file) or die "Could not move $test_output_file to $dest_file: $!\n";
}

ok($gff_obj->_run_go_extraction_cmd, 'run the command to see if GFF input working as expected');

compare_ok(
    $cwd . '/input_annotation.gff.go.gff',
    't/data/expected.go.gff',
    'got expected merged GFF output'
);

unlink($cwd . '/input_proteins.faa.iprscan.gff');
unlink($cwd . '/input_annotation.gff.iprscan.gff');
unlink($cwd . '/input_annotation.gff.iprscan.gff.go.tsv');
unlink($cwd . '/input_annotation.gff.iprscan.gff.go.summary.tsv');
unlink($cwd . '/input_annotation.gff.go.gff');

done_testing();
