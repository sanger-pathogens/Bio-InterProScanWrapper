package Bio::InterProScanWrapper::External::LSFInterProScan;

# ABSTRACT: Run interproscan via LSF jobs

=head1 SYNOPSIS

Run interproscan via LSF jobs
   use Bio::InterProScanWrapper::External::LSFInterProScan;
   
   my $obj = Bio::InterProScanWrapper::External::LSFInterProScan->new(
     input_files => ['abc.fa','efg.fa'],
     exec => 'abc',
   );
   $obj->run();

=cut

use Moose;
use LSF;
use LSF::JobManager;
use Bio::InterProScanWrapper::Exceptions;

has 'input_files'     => ( is => 'ro', isa => 'ArrayRef',        required => 1 );
has 'memory_in_mb'    => ( is => 'ro', isa => 'Int',             default  => 3000 );
has 'queue'           => ( is => 'ro', isa => 'Str',             default  => 'normal' );
has '_job_manager'    => ( is => 'ro', isa => 'LSF::JobManager', lazy     => 1, builder => '_build__job_manager' );

has 'exec'             => ( is => 'ro', isa => 'Str', default  => '/software/pathogen/external/apps/usr/local/iprscan-5.0.7/interproscan.sh' );
has 'output_type'      => ( is => 'ro', isa => 'Str', default => 'gff3' );
has '_output_suffix'   => ( is => 'ro', isa => 'Str', default  => '.out' );

# A single instance uses more than 1 cpu so you need to reserve more slots
has '_cpus_per_command'  => ( is => 'ro', isa => 'Int',  default  => 4 );

sub _build__job_manager {
    my ($self) = @_;
    return LSF::JobManager->new( -q => $self->queue, history => 1 );
}

sub _generate_memory_parameter {
    my ($self) = @_;
    return "select[mem > ".$self->memory_in_mb."] rusage[mem=".$self->memory_in_mb."] span[hosts=1]";
}

sub _submit_job {
    my ( $self, $command_to_run ) = @_;
    $self->_job_manager->submit(
        -o => "out.o",
        -e => "out.e",
        -M => $self->memory_in_mb,
        -R => $self->_generate_memory_parameter,
        -n => $self->_cpus_per_command,
        $command_to_run
    );
}

sub _report_errors {
    my ($self) = @_;
    my @errors;

    for my $job ( $self->_job_manager->jobs ) {
        if ( $job->history->exit_status != 0 ) {
            push( @errors, $job );
        }
    }

    if ( scalar @errors != 0 ) {
        Bio::InterProScanWrapper::Exceptions::LSFJobFailed->throw( error => "The following jobs failed: ", join( ",", @errors ) );
    }
    $self->_job_manager->clear;
}

sub _construct_cmd
{ 
  my ($self, $input_file) = @_;
  my $cmd = join(
      ' ',
      (
          $self->exec, '-f', $self->output_type, '--goterms', '--iprlookup',
          '--pathways', '-i', $input_file, '--outfile', $input_file. $self->_output_suffix
      )
  );
}

sub run {
    my ($self) = @_;

    for my $input_file ( @{ $self->input_files } ) {
        $self->_submit_job($self->_construct_cmd($input_file));
    }
    $self->_job_manager->wait_all_children( history => 1 );
    $self->_report_errors;
    1;
}
no Moose;
__PACKAGE__->meta->make_immutable;

1;
