#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use Test::Files qw(compare_ok);
use File::Copy;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper');
}

my $obj;
my $cwd = getcwd();

ok($obj = Bio::InterProScanWrapper->new(
  input_file   => $cwd.'/t/data/input_proteins.faa',
  exec             => $cwd.'/t/bin/dummy_interproscan',
),'Initialise object');
ok($obj->annotate, 'run a mocked interproscan');

copy('t/data/input_annotation.gff','input_annotation.gff');
ok($obj = Bio::InterProScanWrapper->new(
  input_file          => 'input_annotation.gff',
  input_is_gff	      => 1,
  translation_table   => 11,
  exec                => $cwd.'/t/bin/dummy_interproscan',
),'Initialise object');
ok($obj->annotate, 'run a mocked interproscan');

ok($obj = Bio::InterProScanWrapper->new(
  input_file   => $cwd.'/t/data/input_proteins.faa',
  exec             => $cwd.'/t/bin/dummy_interproscan',
  _protein_files_per_cpu => 2,
  _proteins_per_file  => 2,
),'Initialise object creating 2 protein files per iteration');

ok(my $file_names = $obj->_create_protein_files(2), 'create files');
compare_ok(
	$file_names->[0],
	't/data/interpro.seq', 
	'first protein the same'
);
compare_ok(
	$file_names->[1],
	't/data/interpro2.seq', 
	'2nd protein the same'
);

ok($file_names->[0] =~ /1.seq$/, 'file name as expected');
ok($file_names->[1] =~ /2.seq$/, 'file name as expected');


copy('t/data/intermediate_interpro.gff', 't/data/intermediate.gff');
ok($obj->_merge_proteins_into_gff($obj->input_file, 't/data/intermediate.gff'));

compare_ok(
	't/data/intermediate.gff',
	't/data/expected_merged_proteins.gff', 
	'proteins merged with gff'
);

unlink('t/data/intermediate.gff');
done_testing();
