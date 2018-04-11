#!/usr/bin/env perl
use strict;
use warnings;
use Test::Files qw(compare_ok);

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::ParseInterProOutput');
}

ok(my $obj = Bio::InterProScanWrapper::ParseInterProOutput->new(
  gff_files   => ['t/data/iproutput/0.seq.out','t/data/iproutput/1.seq.out','t/data/iproutput/2.seq.out','t/data/iproutput/3.seq.out'],
  output_file => 'output.gff',
  exec => '/path/to/interpro',
),'initialise object');

ok($obj->merge_files, 'Merge the files together');
compare_ok(
	't/data/expected_merged_results.gff', 
	'output.gff', 
	'content as expected'
);

unlink('output.gff');

done_testing();

