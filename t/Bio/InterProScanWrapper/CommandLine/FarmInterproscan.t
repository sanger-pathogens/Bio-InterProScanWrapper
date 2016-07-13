#!/usr/bin/env perl
use Moose;
use Data::Dumper;
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

#---- Test: Empty output file -----#
my %scripts_and_expected_files = (
    '-a t/data/input_proteins.faa -e '.$cwd.'/t/bin/dummy_interproscan --no_lsf' =>
      ['input_proteins.faa.iprscan.gff', 't/data/empty_annotation.gff'],
);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

#---- Test: Non-empty output file -----#

# Create expected output file here as it is dependent on where the tests run from
open my $FH, ">", "expected_output.gff" or die "Could not create expected output file during test";
print $FH "##gff-version 3\n";
print $FH "#Produced using: $cwd/t/bin/dummy_interproscan_non_empty_output\n";
close $FH;

%scripts_and_expected_files = (
    '-a t/data/input_proteins.faa -e '.$cwd.'/t/bin/dummy_interproscan_non_empty_output --no_lsf' =>
      ['input_proteins.faa.iprscan.gff', 'expected_output.gff'],
);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );
unlink("expected_output.gff");

done_testing();

