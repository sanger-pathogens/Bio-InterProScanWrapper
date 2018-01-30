#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Copy;
use File::Basename;
use Test::Files qw(compare_ok);
use Cwd;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::External::ParallelInterProScan');
}

my $cwd = getcwd();

my $tmp_obj = File::Temp->newdir( DIR =>$cwd );
my $tmp_dir = $tmp_obj->dirname();
my @seq_files = glob $cwd . "/t/data/interpro*.seq";
foreach my $seq_file (@seq_files) {
    my $dest_file = join( "/", $tmp_dir, basename($seq_file) );
    copy($seq_file, $dest_file) or die "Could not move $seq_file to $dest_file: $!\n";
}

ok(my $obj = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
     input_file       => $cwd . '/t/data/input_proteins.faa',
     output_file      => $cwd . '/t/data/input_proteins.faa.iprscan.gff',
     temp_directory_name => $tmp_dir,
     input_files_path => $tmp_dir . '/interpro*.seq',
     exec             => $cwd . '/t/bin/dummy_interproscan',
     cpus             => 2,
 ), 'initalise object'
);

is($obj->_cmd, 'nice parallel  -j 2 '.$cwd.'/t/bin/dummy_interproscan -f gff3 --goterms --iprlookup --pathways -i {} --outfile {}.out ::: '.$tmp_dir.'/interpro*.seq', 'InterProScan command constructed as expected');
is($obj->_merge_cmd, 'merge_results_annotate_eukaryotes -a ' . $cwd. '/t/data/input_proteins.faa -o ' . $cwd .'/t/data/input_proteins.faa.iprscan.gff --intermediate_output_dir ' . $tmp_dir, 'Merge command constructed as expected');
ok($obj->run, 'run the command to see if the mock is working as expected');

compare_ok(
    $cwd . '/t/data/input_proteins.faa.iprscan.gff',
    't/data/dummy_merged_annotation.gff', 
    'got expected iprscal output'
);

unlink($cwd . '/t/data/input_proteins.faa.iprscan.gff');




done_testing();
