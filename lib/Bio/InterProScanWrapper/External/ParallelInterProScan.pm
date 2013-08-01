package Bio::InterProScanWrapper::External::ParallelInterProScan;

# ABSTRACT: Run and parse the output of interproscan

=head1 SYNOPSIS

Run and parse the output of cmscan
   use Bio::InterProScanWrapper::External::ParallelInterProScan;
   
   my $obj = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
     input_file => 'abc.faa',
     exec       => 'interproscan.sh ',
   );
  $obj->run;

=cut

use Moose;

has 'input_files_path' => ( is => 'ro', isa => 'Str', required => 1 );
has 'exec'             => ( is => 'ro', isa => 'Str', default  => 'interproscan.sh' );
has 'cpus'             => ( is => 'ro', isa => 'Int', default  => 1 );
has '_output_suffix'   => ( is => 'ro', isa => 'Str', default  => '.out' );

has 'output_type' => ( is => 'ro', isa => 'Str', default => 'gff3' );

sub _cmd 
{
  my ($self) = @_;
  my $paropts = $self->cpus > 0 ? " -j " . $self->cpus : "";
  my $cmd = join(
      ' ',
      (
          'nice', 'parallel', $paropts, $self->exec, '-f', $self->output_type, '--goterms', '--iprlookup',
          '--pathways', '-i', '{}', '--outfile', '{}' . $self->_output_suffix, ':::', $self->input_files_path
      )
  );
  return $cmd;
}

sub run {
    my ($self) = @_;
    my $cmd = $self->_cmd;
    `$cmd`;
    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
