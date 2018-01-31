package Bio::InterProScanWrapper::CommandLine::ExtractGoFromInterProOutput;

# ABSTRACT: extract GO terms from Interproscan GFF output and summarise.

=head1 SYNOPSIS
Command line interface to extract GO terms from Interproscan
=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd;
use File::Basename;
use Bio::InterProScanWrapper::ExtractGoFromInterProOutput;

has 'args'                   => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'            => ( is => 'ro', isa => 'Str',      required => 1 );
has 'help'                   => ( is => 'rw', isa => 'Bool',     default => 0 );
has 'iprscan_file'           => ( is => 'rw', isa => 'Str' );
has 'gff_to_extend'          => ( is => 'rw', isa => 'Str' );
has 'output_filename'        => ( is => 'rw', isa => 'Str',      lazy => 1, builder => '_build_output_filename' );
has 'summary_filename'       => ( is => 'rw', isa => 'Str',      lazy => 1, builder => '_build_summary_filename' );

sub BUILD {
  my ($self) = @_;
  my ($iprscan_file, $gff_to_extend, $output_filename, $summary_filename, $help);

  GetOptionsFromArray(
    $self->args,
    'i|iprscan_file=s'      => \$iprscan_file,
    'e|gff_to_extend=s'     => \$gff_to_extend,
    'o|output_filename=s'   => \$output_filename,
    's|summary_filename=s'  => \$summary_filename,
    'h|help'                => \$help,
  );

  $self->gff_to_extend($gff_to_extend) if ( defined($gff_to_extend) );
  $self->iprscan_file($iprscan_file) if ( defined($iprscan_file) );
  $self->output_filename($output_filename) if ( defined($output_filename) );
  $self->summary_filename($summary_filename) if ( defined($summary_filename) );
}

sub _build_output_filename
{
  my ($self) = @_;
  my $output_suffix = '.go.tsv';
  my($filename, $directories, $suffix) = fileparse($self->iprscan_file);
  my $output_filename = getcwd().'/'.$filename.$output_suffix ;
  return $output_filename;
}

sub _build_summary_filename
{
  my ($self) = @_;
  my $summary_suffix = '.go.summary.tsv';
  my($filename, $directories, $suffix) = fileparse($self->iprscan_file);
  my $summary_filename = getcwd().'/'.$filename.$summary_suffix ;
  return $summary_filename;
}

sub run {
  my ($self) = @_;
  ( (defined $self->iprscan_file && -e $self->iprscan_file ) && !$self->help ) or die $self->usage_text;

  my $obj = Bio::InterProScanWrapper::ExtractGoFromInterProOutput->new(
        iprscan_file      => $self->iprscan_file,
        output_filename   => $self->output_filename,
        summary_filename  => $self->summary_filename,
        gff_to_extend     => $self->gff_to_extend,
    );
  $obj->run;  
}

sub usage_text {
    my ($self) = @_;
    my $script_name = $self->script_name;

    return <<USAGE;
    Usage: $script_name [options]
    Extract GO terms from Interproscan GFF output file.
  
    # Run using default settings 
    iprscan_extract_go_terms -i iprscan_results.gff 

    # Provide an output file name for tab-delimited id:go mapping
    iprscan_extract_go_terms -i iprscan_results.gff -o iprscan_go_terms.tsv
 
    # Add extracted GO terms to another GFF (e.g. PROKKA output)
    iprscan_extract_go_terms -i iprscan_results.gff -e prokka.out.gff

    # This help message
    iprscan_extract_go_terms -h
USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
