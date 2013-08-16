package Bio::InterProScanWrapper;

# ABSTRACT: Take in a file of proteins and predict functions using interproscan

=head1 SYNOPSIS

Take in a file of proteins and predict functions using interproscan
   use Bio::InterProScanWrapper::InterProScan;

   my $obj = Bio::InterProScanWrapper::InterProScan->new(
     input_file   => 'input.faa'
   );
   $obj->annotate;

=cut

use Moose;
use File::Temp;
use File::Copy;
use Bio::SeqIO;
use Bio::InterProScanWrapper::External::ParallelInterProScan;
use Bio::InterProScanWrapper::ParseInterProOutput;
use Bio::InterProScanWrapper::External::LSFInterProScan;

has 'input_file'             => ( is => 'ro', isa => 'Str', required => 1 );
has 'cpus'                   => ( is => 'ro', isa => 'Int', default  => 1 );
has 'exec'                   => ( is => 'ro', isa => 'Str', required => 1 );
has 'output_filename'        => ( is => 'ro', isa => 'Str', default  => 'iprscan_results.gff' );
has '_protein_file_suffix'   => ( is => 'ro', isa => 'Str', default  => '.seq' );
has '_tmp_directory'         => ( is => 'ro', isa => 'Str', default  => '/tmp' );
has '_default_protein_files_per_cpu' => ( is => 'ro', isa => 'Int', default  => 20 );
has '_protein_files_per_cpu' => ( is => 'ro', isa => 'Int',  lazy => 1, builder => '_build__protein_files_per_cpu' );
has '_proteins_per_file'     => ( is => 'ro', isa => 'Int', default  => 20 );
has '_temp_directory_obj' =>
  ( is => 'ro', isa => 'File::Temp::Dir', lazy => 1, builder => '_build__temp_directory_obj' );
has '_temp_directory_name' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__temp_directory_name' );
has '_input_file_parser' => ( is => 'ro', lazy => 1, builder => '_build__input_file_parser' );

has 'use_lsf' => ( is => 'ro', isa => 'Bool', default => 0 );

sub _build__protein_files_per_cpu
{
  my ($self) = @_;
  if($self->use_lsf == 1)
  {
    return 1;
  }
  else
  {
    return $self->_default_protein_files_per_cpu;
  }
}

sub _build__temp_directory_obj {
    my ($self) = @_;
    return File::Temp->newdir( DIR => $self->_tmp_directory, CLEANUP => 1 );
}

sub _build__temp_directory_name {
    my ($self) = @_;
    return $self->_temp_directory_obj->dirname();
}

sub _build__input_file_parser {
    my ($self) = @_;
    return Bio::SeqIO->new(
        -format   => 'Fasta',
        -file     => $self->input_file,
        -alphabet => 'protein'
    );
}

sub _create_protein_file {
    my ( $self, $seq_io_protein, $counter ) = @_;
    my $output_filename = $self->_temp_directory_name . '/' . $counter . $self->_protein_file_suffix;
    my $fout         = Bio::SeqIO->new( -file => ">>" . $output_filename, -format => 'Fasta', -alphabet => 'protein' );
    my $raw_sequence = $seq_io_protein->seq;
    $raw_sequence =~ s/\*//g;
    $seq_io_protein->seq($raw_sequence);
    $fout->write_seq($seq_io_protein);
    return $output_filename;
}

sub _create_a_number_of_protein_files {
    my ( $self, $files_to_create ) = @_;
    my %file_names;
    my $counter = 0;
    while ( my $seq = $self->_input_file_parser->next_seq ) {
        $file_names{ $self->_create_protein_file( $seq, int( $counter / $self->_proteins_per_file ) ) }++;

        $counter++;
        last if ( $self->_protein_files_per_cpu * $self->cpus * $self->_proteins_per_file == $counter );
    }
    my @uniq_files = sort keys %file_names;
    return \@uniq_files;
}

sub _delete_list_of_files {
    my ( $self, $list_of_files ) = @_;
    for my $file ( @{$list_of_files} ) {
        unlink($file);
    }
    return $self;
}

sub _expected_output_files {
    my ( $self, $input_files ) = @_;
    my @output_files;

    for my $file ( @{$input_files} ) {
        push( @output_files, $file . '.out' );
    }

    return \@output_files;
}

sub annotate {
    my ($self) = @_;

    while ( my $protein_files = $self->_create_a_number_of_protein_files( $self->cpus ) ) {
        last if ( @{$protein_files} == 0 );

        my $job_runner;
        if ( $self->use_lsf ) {

            # split over multiple hosts with LSF
            $job_runner = Bio::InterProScanWrapper::External::LSFInterProScan->new(
                input_files => $protein_files,
                exec        => $self->exec,
            );
        }
        else {
            # Run on a single host with parallel
            $job_runner = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
                input_files_path => join( '/', ( $self->_temp_directory_name, '*' . $self->_protein_file_suffix ) ),
                exec             => $self->exec,
                cpus             => $self->cpus,
            );
        }
        $job_runner->run;

        # delete intermediate input files where there is 1 protein per file
        $self->_delete_list_of_files($protein_files);

        my $intermediate_results_filename    = join( '/', ( $self->_temp_directory_name, 'block_merged_results.gff' ) );
        my $output_files                     = $self->_expected_output_files($protein_files);
        my $merge_intermediate_gff_files_obj = Bio::InterProScanWrapper::ParseInterProOutput->new(
            gff_files   => $output_files,
            output_file => $intermediate_results_filename,
        );
        $merge_intermediate_gff_files_obj->merge_files;
        $self->_delete_list_of_files($output_files);
        $self->_merge_block_results_with_final($intermediate_results_filename);
    }

    $self->_merge_proteins_into_gff( $self->input_file, $self->output_filename );

    return $self;
}

sub _merge_proteins_into_gff {
    my ( $self, $input_file, $output_file ) = @_;
    open( my $output_fh, '>>', $output_file )
      or Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile->throw(
        error => "Couldnt write to file: " . $output_file );
    open( my $input_fh, $input_file )
      or Bio::InterProScanWrapper::Exceptions::FileNotFound->throw( error => "Couldnt open file: " . $input_file );

    print {$output_fh} "##FASTA\n";
    while (<$input_fh>) {
        print {$output_fh} $_;
    }
    close($output_fh);
    close($input_fh);
}

sub _merge_block_results_with_final {
    my ( $self, $intermediate_filename ) = @_;
    if ( -e $self->output_filename ) {
        my $merge_intermediate_gff_files_obj = Bio::InterProScanWrapper::ParseInterProOutput->new(
            gff_files => [ $self->output_filename, $intermediate_filename ],
            output_file => join( '/', ( $self->_temp_directory_name, 'merge_with_final.gff' ) ),
        );
        $merge_intermediate_gff_files_obj->merge_files;
        move( join( '/', ( $self->_temp_directory_name, 'merge_with_final.gff' ) ), $self->output_filename );
    }
    else {
        move( $intermediate_filename, $self->output_filename );
    }
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
