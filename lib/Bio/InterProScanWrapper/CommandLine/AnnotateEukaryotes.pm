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
has 'exec_script' => ( is => 'rw', isa => 'Str',      default  => '/software/pathogen/external/apps/usr/local/iprscan-5.0.7/interproscan.sh' );
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
        'l|no_lsf'            => \$no_lsf,
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
    Annotate eukaryotes using InterProScan
  
    # Run InterProScan using LSF and screen (recommended)
    screen $script_name -a proteins.faa
    
    # Provide an output file name 
    screen $script_name -a proteins.faa -o output.gff
    
    # Create 200 jobs at a time, writing out intermediate results to a file
    screen $script_name -a proteins.faa -p 200
    
    # Run on a single host (no LSF). '-p x' needs x*2 CPUs and x*2GB of RAM to be available
    screen $script_name -a proteins.faa --no_lsf -p 10 

    # This help message
    annotate_eukaryotes -h

USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
