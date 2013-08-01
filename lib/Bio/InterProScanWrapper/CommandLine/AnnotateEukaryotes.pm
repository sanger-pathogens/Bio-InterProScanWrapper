package Bio::InterProScanWrapper::CommandLine::AnnotateEukaryotes;

# ABSTRACT: provide a commandline interface to the annotation wrappers

=head1 SYNOPSIS

provide a commandline interface to the annotation wrappers

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd;
use Bio::InterProScanWrapper;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'help'        => ( is => 'rw', isa => 'Bool',     default  => 0 );
has 'cpus'        => ( is => 'rw', isa => 'Int',      default  => 100 );
has 'exec_script' => ( is => 'rw', isa => 'Str',      default  => 'interproscan.sh' );
has 'proteins_file'   => ( is => 'rw', isa => 'Str' );
has 'tmp_directory'   => ( is => 'rw', isa => 'Str', default => '/tmp' );
has 'output_filename' => ( is => 'rw', isa => 'Str', default => 'iprscan_results.gff' );
has 'no_lsf'         => ( is => 'rw', isa => 'Bool', default => 0 );

sub BUILD {
    my ($self) = @_;
    my ( $proteins_file, $tmp_directory, $help, $exec_script, $cpus, $output_filename, $no_lsf );

    GetOptionsFromArray(
        $self->args,
        'a|proteins_file=s'   => \$proteins_file,
        't|tmp_directory=s'   => \$tmp_directory,
        'e|exec_script=s'     => \$exec_script,
        'p|cpus=s'            => \$cpus,
        'o|output_filename=s' => \$output_filename,
        'l|use_lsf'           => \$use_lsf,
        'h|help'              => \$help,
    );

    $self->proteins_file($proteins_file) if ( defined($proteins_file) );
    if ( defined($tmp_directory) ) { $self->tmp_directory($tmp_directory); }
    else {
        $self->tmp_directory( getcwd() );
    }
    $self->exec_script($exec_script)         if ( defined($exec_script) );
    $self->cpus($cpus)                       if ( defined($cpus) );
    $self->output_filename($output_filename) if ( defined($output_filename) );
    $self->no_lsf(1)                         if (  defined($no_lsf) );

}

sub run {
    my ($self) = @_;
    ( ( -e $self->proteins_file ) && !$self->help ) or die $self->usage_text;

    my $obj = Bio::InterProScanWrapper->new(
        input_file      => $self->proteins_file,
        _tmp_directory  => $self->tmp_directory,
        cpus            => $self->cpus,
        exec            => $self->exec_script,
        output_filename => $self->output_filename,
        use_lsf         => ($self->no_lsf == 1 ? 0 : 1)
    );
    $obj->annotate;

}

sub usage_text {
    my ($self) = @_;
    my $script_name = $self->script_name;

    return <<USAGE;
    Usage: $script_name [options]
    Annotate eukaryotes
  
    $script_name -a proteins.faa
    
    # Run on a single host with 10 instances - it needs 20 CPUs and 20GB of RAM to be reserved
    $script_name -a proteins.faa -p 10
    
    # Split up over multiple hosts using LSF where '-p' is the max number of jobs at any given time
    $script_name -a proteins.faa --use_lsf -p 10

    # This help message
    annotate_eukaryotes -h

USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
