package Bio::InterProScanWrapper::External::ParallelInterProScan;

# ABSTRACT: Run and parse the output of interproscan

=head1 SYNOPSIS

Run and parse the output of cmscan
   use Bio::InterProScanWrapper::External::ParallelInterProScan;
   
   my $obj = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
     protein_file => 'abc.faa',
     exec       => 'interproscan.sh ',
   );
  $obj->run;

=cut

use Moose;

has 'input_file'          => ( is => 'ro', isa => 'Str',  required => 1 );
has 'input_is_gff'        => ( is => 'ro', isa => 'Bool', required => 1 );
has 'protein_file'        => ( is => 'ro', isa => 'Str',  required => 1);
has 'protein_files_path'  => ( is => 'ro', isa => 'Str',  required => 1 );
has 'temp_directory_name' => ( is => 'ro', isa => 'Str',  required => 1);
has 'output_file'         => ( is => 'ro', isa => 'Str',  required => 1);
has 'exec'                => ( is => 'ro', isa => 'Str',  default  => 'interproscan.sh' );
has 'cpus'                => ( is => 'ro', isa => 'Int',  default  => 1 );
has '_paropts'            => ( is => 'ro', isa => 'Str',  lazy     => 1, builder => '_build__paropts' );
has '_output_suffix'      => ( is => 'ro', isa => 'Str',  default  => '.out' );
has 'output_type'         => ( is => 'ro', isa => 'Str',  default => 'gff3' );

sub _build__paropts {
  my ($self) = @_;
  my $paropts = $self->cpus > 0 ? " -j " . $self->cpus : "";
  return $paropts;
}

sub _cmd 
{
  my ($self) = @_;
  my $cmd = join(
      ' ',
      (
          'nice', 'parallel', $self->_paropts, $self->exec, '-f', $self->output_type, '--goterms', '--iprlookup',
          '--pathways', '-i', '{}', '--outfile', '{}' . $self->_output_suffix, ':::', $self->protein_files_path
      )
  );
  return $cmd;
}

sub _run_interproscan_cmd {
  my ($self) = @_;
  my $cmd = $self->_cmd;
  system($cmd);

  1;
}

sub _merge_cmd
{
   my ($self) = @_;
   my $command = join(' ' , 'merge_results_annotate_eukaryotes', '-a',$self->protein_file, '-o', $self->output_file, '--intermediate_output_dir', $self->temp_directory_name);
   return $command;
}

sub _run_merge_cmd {
  my ($self) = @_;
  my $merge_cmd = $self->_merge_cmd;
  `$merge_cmd`;

  1;
}

sub _go_extraction_cmd
{
   my ($self) = @_;
   my $command = join(' ',('extract_interproscan_go_terms', '-i', $self->output_file, '-e', $self->input_file));
   return $command;
}

sub _run_go_extraction_cmd{
  my ($self) = @_;
  my $go_extraction_cmd = $self->_go_extraction_cmd;
  `$go_extraction_cmd`;

  1;
}

sub run {
  my ($self) = @_;
  $self->_run_interproscan_cmd;
  $self->_run_merge_cmd;
  $self->_run_go_extraction_cmd (if $self->input_is_gff);
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
