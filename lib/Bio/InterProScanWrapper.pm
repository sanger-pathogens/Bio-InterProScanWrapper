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
use File::Path qw(remove_tree);
use File::Copy;
use File::Basename;
use Bio::SeqIO;
use Bio::Roary::ExtractProteomeFromGFF;
use Bio::InterProScanWrapper::External::ParallelInterProScan;
use Bio::InterProScanWrapper::ParseInterProOutput;
use Bio::InterProScanWrapper::External::LSFInterProScan;
use Bio::InterProScanWrapper::Exceptions;
use Bio::InterProScanWrapper::ExtractGoFromInterProOutput;

has 'input_file'                  => ( is => 'ro', isa => 'Str',    required => 1 );
has 'input_is_gff'                => ( is => 'ro', isa => 'Bool',   default  => 0 );
has 'translation_table'           => ( is => 'ro', isa => 'Int',    default  => 1 );
has 'cpus'                        => ( is => 'ro', isa => 'Int',    default  => 1 );
has 'exec'                        => ( is => 'ro', isa => 'Str',    required => 1 );
has 'output_filename'             => ( is => 'ro', isa => 'Str',    default  => 'iprscan_results.gff' );

has '_input_protein_filename'  => ( is => 'ro', isa => 'Str',    lazy => 1, builder => '_build__input_protein_filename' );

has '_tmp_directory'              => ( is => 'ro', isa => 'Str',    default  => '/tmp' );
has '_temp_directory_obj'         =>( is => 'ro', isa => 'File::Temp::Dir', lazy => 1, builder => '_build__temp_directory_obj' );
has '_temp_directory_name'        => ( is => 'ro', isa => 'Str',    lazy => 1, builder => '_build__temp_directory_name' );

has '_protein_file_suffix'        => ( is => 'ro', isa => 'Str',    default  => '.seq' );
has '_proteins_per_file'          => ( is => 'ro', isa => 'Int',    default  => 100 );
has '_default_protein_files_per_cpu' => ( is => 'ro', isa => 'Int', default  => 20 );
has '_protein_files_per_cpu'      => ( is => 'ro', isa => 'Int',    lazy => 1, builder => '_build__protein_files_per_cpu' );
has '_input_file_parser'          => ( is => 'ro', lazy => 1,       builder => '_build__input_file_parser' );

has '_output_suffix'              => ( is => 'ro', isa => 'Str',    default  => '.out' );
has 'use_lsf'                     => ( is => 'ro', isa => 'Bool',   default => 0 );

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
    return File::Temp->newdir( DIR => $self->_tmp_directory, CLEANUP => 0 );
}

sub _build__temp_directory_name {
    my ($self) = @_;
    return $self->_temp_directory_obj->dirname();
}

sub _build__input_protein_filename {
  my ($self) = @_;

  my $protein_filename = $self->input_file;
  if ( $self->input_is_gff ) {
    $protein_filename = $self->input_file . ".proteome.faa"; 
  }
  return $protein_filename;
}

sub _build__input_file_parser {
    my ($self) = @_;
    return Bio::SeqIO->new(
        -format   => 'Fasta',
        -file     => $self->_input_protein_filename,
        -alphabet => 'protein'
    );
}

sub _create_protein_fasta_file_from_gff {
  my ($self) = @_;

  my $roary_obj = Bio::Roary::ExtractProteomeFromGFF->new(
            gff_file              => $self->input_file,
            apply_unknowns_filter => 0,
            translation_table     => $self->translation_table,
            output_filename       => $self->_input_protein_filename,
  );
  $roary_obj->fasta_file();

  my $exected_protein_fasta_file = $self->_input_protein_filename;
  (-e $exected_protein_fasta_file) or Bio::InterProScanWrapper::Exceptions::FileNotFound->throw(
    error => "Couldn't find extracted proteins file: " . $exected_protein_fasta_file );
  return 1;
}

sub _create_protein_file {
   my ( $self, $seq_io_protein, $counter ) = @_;
    my $output_filename = $self->_temp_directory_name . '/' . ($counter +1) . $self->_protein_file_suffix;
    my $fout         = Bio::SeqIO->new( -file => ">>" . $output_filename, -format => 'Fasta', -alphabet => 'protein' );
    my $raw_sequence = $seq_io_protein->seq;
    $raw_sequence =~ s/\*//g;
    $seq_io_protein->seq($raw_sequence);
    $fout->write_seq($seq_io_protein);
    return $output_filename;
}

sub _create_protein_files {
    my ( $self ) = @_;
    my %file_names;
    my $counter = 0;
    while ( my $seq = $self->_input_file_parser->next_seq ) {
        $file_names{ $self->_create_protein_file( $seq, int( $counter / $self->_proteins_per_file ) ) }++;
        $counter++;
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
    my ( $self, $input_directory ) = @_;
    my $output_suffix = $self->_output_suffix;
    
    opendir(my $dh, $input_directory) || die "can't opendir $input_directory: $!";
    my @output_files = grep { /$output_suffix$/ } readdir($dh);
    closedir($dh);
    
    for(my $i=0;$i < @output_files; $i++)
    {
      $output_files[$i] = join('/',($input_directory, $output_files[$i]));
    }

    return \@output_files;
}

sub annotate {
    my ($self) = @_;

    if ( $self->input_is_gff ) {
      $self->_create_protein_fasta_file_from_gff;
    }

    my $protein_files = $self->_create_protein_files() ;
    last if ( @{$protein_files} == 0 );

    my $job_runner;
    if ( $self->use_lsf ) {
  
        # split over multiple hosts with LSF
        $job_runner = Bio::InterProScanWrapper::External::LSFInterProScan->new(
            input_file          => $self->input_file,
            input_is_gff        => $self->input_is_gff,
            protein_file        => $self->_input_protein_filename,
            protein_files       => $protein_files,
            exec                => $self->exec,
            output_file         => $self->output_filename,
            temp_directory_name => $self->_temp_directory_name
        );
    }
    else {
        # Run on a single host with parallel
        $job_runner = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
            input_file          => $self->input_file,
            input_is_gff        => $self->input_is_gff,
            protein_file        => $self->_input_protein_filename,
            protein_files_path  => join( '/', ( $self->_temp_directory_name, '*' . $self->_protein_file_suffix ) ),
            exec                => $self->exec,
            cpus                => $self->cpus,
            output_file         => $self->output_filename,
            temp_directory_name => $self->_temp_directory_name
        );
    }
    $job_runner->run;

    return $self;
}


sub merge_results
{
  my ($self, $temp_directory) = @_;

  # delete intermediate input files where there is 1 protein per file
  # move to separate cleanup job (ended)
  my $output_files        = $self->_expected_output_files($temp_directory);
  my $merge_gff_files_obj = Bio::InterProScanWrapper::ParseInterProOutput->new(
      gff_files   => $output_files,
      output_file => $self->output_filename,
      exec => $self->exec,
  );
  $merge_gff_files_obj->merge_files;
  $self->_merge_proteins_into_gff( $self->input_file, $self->output_filename );
  $self->_delete_list_of_files($output_files);
  
  remove_tree($temp_directory);
  return 1;
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
