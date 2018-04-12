package TestHelper;
use Moose::Role;
use Test::Most;
use Test::Files qw(compare_ok);
use File::Temp;
use File::Copy;
use File::Basename;

sub mock_execute_script_and_check_output {
    my ( $script_name, $scripts_and_expected_files, $columns_to_exclude ) = @_;
    open OLDOUT, '>&STDOUT';
    open OLDERR, '>&STDERR';
    eval("use $script_name ;");
    
    my $returned_values = 0;
    {
        local *STDOUT;
        open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
        local *STDERR;
        open STDERR, '>/dev/null' or warn "Can't open /dev/null: $!";

        for my $script_parameters ( sort keys %$scripts_and_expected_files ) {
            my $full_script = $script_parameters;
            my @input_args = split( " ", $full_script );

            my $cmd = "$script_name->new(args => \\\@input_args, script_name => '$script_name')->run;";
            eval($cmd);
            warn $@ if $@;

            my @actual_output_file_names   = @{ $scripts_and_expected_files->{$script_parameters}->[0] };
            my @expected_output_file_names = @{ $scripts_and_expected_files->{$script_parameters}->[1] } if ( defined($scripts_and_expected_files->{$script_parameters}->[1]) );

            for (my $i=0; $i < scalar(@actual_output_file_names); $i++) {
                ok( -e $actual_output_file_names[$i], "Actual output file exists $actual_output_file_names[$i]  $script_parameters" );

                if ( defined($expected_output_file_names[$i]) ) {
                    compare_ok( $actual_output_file_names[$i], $expected_output_file_names[$i], "Actual and expected output match for '$script_parameters'" );
                }

                unlink($actual_output_file_names[$i]);
            }
        }
        close STDOUT;
        close STDERR;
    }

    # Restore stdout.
    open STDOUT, '>&OLDOUT' or die "Can't restore stdout: $!";
    open STDERR, '>&OLDERR' or die "Can't restore stderr: $!";

    # Avoid leaks by closing the independent copies.
    close OLDOUT or die "Can't close OLDOUT: $!";
    close OLDERR or die "Can't close OLDERR: $!";
}

sub copy_seq_files_to_tmpdir {
    my ($cwd, $tmp_dir) = @_;
    my @seq_files = glob $cwd . "/t/data/interpro*.seq";
    foreach my $seq_file (@seq_files) {
        my $dest_file = join( "/", $tmp_dir, basename($seq_file) );
        copy($seq_file, $dest_file) or die "Could not move $seq_file to $dest_file: $!\n";
    }
}

sub copy_files_for_tests {
    my ($source_file, $destination) = @_;
    my $dest_file = $destination . "/" . basename($source_file);
    copy($source_file, $dest_file) or die "Cannot copy " . $source_file . ": " . $! . "\n";
}

no Moose;
1;

