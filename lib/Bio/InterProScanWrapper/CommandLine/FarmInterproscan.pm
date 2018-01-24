package Bio::InterProScanWrapper::CommandLine::FarmInterproscan;

# ABSTRACT: provide a commandline interface to the interproscan wrapper

=head1 SYNOPSIS

provide a commandline interface to the interproscan wrapper

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd;
use File::Basename;
use Bio::InterProScanWrapper;

has 'args'                      => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'               => ( is => 'ro', isa => 'Str',      required => 1 );
has 'help'                      => ( is => 'rw', isa => 'Bool',     default  => 0 );
has 'cpus'                      => ( is => 'rw', isa => 'Int',      default  => 100 );
has 'exec_script'               => ( is => 'rw', isa => 'Str',      default  => '/software/pathogen/external/apps/usr/local/interproscan-5.25-64.0/interproscan.sh' );
has 'input_file'                => ( is => 'rw', isa => 'Str' );
has 'translation_table'         => ( is => 'rw', isa => 'Int',      default => 1 );
has 'input_is_gff'              => ( is => 'rw', isa => 'Bool',     default => 0 );
has 'tmp_directory'             => ( is => 'rw', isa => 'Str',      default => '/tmp' );
has 'output_filename'           => ( is => 'rw', isa => 'Str',      lazy => 1, builder => '_build_output_filename' );
has 'no_lsf'                    => ( is => 'rw', isa => 'Bool',     default => 0 );
has 'intermediate_output_dir'   => ( is => 'rw', isa => 'Maybe[Str]');

sub BUILD {
    my ($self) = @_;
    my ( $input_file, $translation_table, $input_is_gff, $tmp_directory, $help, $exec_script, $cpus, $output_filename, $no_lsf, $intermediate_output_dir );

    GetOptionsFromArray(
        $self->args,
        'a|input_file=s'            => \$input_file,
        'g|gff'                     => \$input_is_gff,
        'c|translation_table=i'     => \$translation_table,
        't|tmp_directory=s'         => \$tmp_directory,
        'e|exec_script=s'           => \$exec_script,
        'p|cpus=s'                  => \$cpus,
        'o|output_filename=s'       => \$output_filename,
        'l|no_lsf'                  => \$no_lsf,
        'intermediate_output_dir=s' => \$intermediate_output_dir,
        'h|help'                    => \$help,
    );

    $self->input_file($input_file) if ( defined($input_file) );
    $self->translation_table($translation_table) if ( defined($translation_table) );
    $self->input_is_gff($input_is_gff) if ( defined($input_is_gff) );
    if ( defined($tmp_directory) ) { $self->tmp_directory($tmp_directory); }
    else {
        $self->tmp_directory( getcwd() );
    }
    $self->exec_script($exec_script)         if ( defined($exec_script) );
    $self->cpus($cpus)                       if ( defined($cpus) );
    $self->output_filename($output_filename) if ( defined($output_filename) );
    $self->no_lsf(1)                         if ( defined($no_lsf) );
    $self->intermediate_output_dir($intermediate_output_dir)  if ( defined($intermediate_output_dir) );

}

sub _build_output_filename
{
  my ($self) = @_;
  my $output_filename = 'iprscan_results.gff';
  if(defined($self->input_file))
  {
    my($filename, $directories, $suffix) = fileparse($self->input_file);
    $output_filename = getcwd().'/'.$filename.'.iprscan.gff';
  }
  return $output_filename;
}

sub merge_results
{
   my ($self) = @_;

   ( ( -e $self->input_file ) && !$self->help ) or die $self->usage_text;
  
   my $obj = Bio::InterProScanWrapper->new(
       input_file         => $self->input_file,
       translation_table  => $self->translation_table,
       input_is_gff       => $self->input_is_gff,
       _tmp_directory     => $self->tmp_directory,
       cpus               => $self->cpus,
       exec               => $self->exec_script,
       output_filename    => $self->output_filename,
       use_lsf            => ($self->no_lsf == 1 ? 0 : 1),
   );
   $obj->merge_results($self->intermediate_output_dir);
}

sub run {
    my ($self) = @_;
    ( ( -e $self->input_file ) && !$self->help ) or die $self->usage_text;

    my $obj = Bio::InterProScanWrapper->new(
        input_file        => $self->input_file,
        translation_table => $self->translation_table,
        input_is_gff       => $self->input_is_gff,
        _tmp_directory    => $self->tmp_directory,
        cpus              => $self->cpus,
        exec              => $self->exec_script,
        output_filename   => $self->output_filename,
        use_lsf           => ($self->no_lsf == 1 ? 0 : 1)
    );
    $obj->annotate;
}

sub usage_text {
    my ($self) = @_;
    my $script_name = $self->script_name;

    return <<USAGE;
    Usage: $script_name [options]
    Run InterProScan on the farm. It is limited to using 400 CPUs at once on the farm.
  
    # Run InterProScan using LSF
    farm_interproscan -a proteins.faa

    # Provide an output file name 
    farm_interproscan -a proteins.faa -o output.gff
    
    # Create 200 jobs at a time, writing out intermediate results to a file
    farm_interproscan -a proteins.faa -p 200
    
    # Run on a single host (no LSF). '-p x' needs x*2 CPUs and x*2GB of RAM to be available
    farm_interproscan -a proteins.faa --no_lsf -p 10 

    # Run InterProScan using LSF with GFF input (standard genetic code for translation)
    farm_interproscan -a annotation.gff -g

    # Run InterProScan using LSF with GFF input (bacterial code for translation)
    farm_interproscan -a annotation.gff -g -c 11

    # This help message
    farm_interproscan -h

USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
