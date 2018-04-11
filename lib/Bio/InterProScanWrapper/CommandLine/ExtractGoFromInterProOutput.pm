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

has 'args'              => ( is => 'ro', isa => 'ArrayRef',  required => 1 );
has 'script_name'       => ( is => 'ro', isa => 'Str',       required => 1 );
has 'help'              => ( is => 'rw', isa => 'Bool',      default => 0 );
has 'iprscan_file'      => ( is => 'rw', isa => 'Str', );
has 'gff_file'          => ( is => 'rw', isa => 'Str|Undef' );
has 'ontology_database' => ( is => 'rw', isa => 'Str',       default => $ENV{GO_OBO} );
has '_output_filename'  => ( is => 'rw', isa => 'Str',       lazy => 1, builder => '_build__output_filename' );
has '_summary_filename' => ( is => 'rw', isa => 'Str',       lazy => 1, builder => '_build__summary_filename' );
has '_gff_filename'     => ( is => 'rw', isa => 'Str|Undef', lazy => 1, builder => '_build__gff_filename' );

sub BUILD {
  my ($self) = @_;
  my ($iprscan_file, $gff_file, $ontology_database, $output_filename, $summary_filename, $gff_filename, $help);

  GetOptionsFromArray(
    $self->args,
    'i|iprscan_file=s'      => \$iprscan_file,
    'e|gff_file=s'          => \$gff_file,
    'd|ontology_database=s' => \$ontology_database,
    'o|output_filename=s'   => \$output_filename,
    's|summary_filename=s'  => \$summary_filename,
    'g|gff_filename=s'      => \$gff_filename,
    'h|help'                => \$help,
  );

  $self->iprscan_file($iprscan_file) if ( defined($iprscan_file) );
  $self->gff_file($gff_file) if ( defined($gff_file) );
  $self->ontology_database($ontology_database) if ( defined($ontology_database) );
  $self->_output_filename($output_filename) if ( defined($output_filename) );
  $self->_summary_filename($summary_filename) if ( defined($summary_filename) );
  $self->_gff_filename($gff_filename) if ( defined($gff_filename) );
}

sub _build__output_filename {
  my ($self) = @_;
  my $output_suffix = '.go.tsv';
  my($filename, $directories, $suffix) = fileparse($self->iprscan_file);
  my $output_filename = getcwd().'/'.$filename.$output_suffix ;
  return $output_filename;
}

sub _build__summary_filename {
  my ($self) = @_;
  my $summary_suffix = '.go.summary.tsv';
  my($filename, $directories, $suffix) = fileparse($self->iprscan_file);
  my $summary_filename = getcwd().'/'.$filename.$summary_suffix ;
  return $summary_filename;
}

sub _build__gff_filename {
  my ($self) = @_;
  my $gff_suffix = '.go.gff';
  my $gff_filename;
  if (defined $self->gff_file) {
    my($filename, $directories, $suffix) = fileparse($self->gff_file);
    $gff_filename = getcwd().'/'.$filename.$gff_suffix if (defined $self->gff_file) ;
  }
  return $gff_filename;
}

sub run {
  my ($self) = @_;
  ( (defined $self->iprscan_file && -e $self->iprscan_file ) && !$self->help ) or die $self->usage_text;
  my $obj = Bio::InterProScanWrapper::ExtractGoFromInterProOutput->new(
        ontology_database => $self->ontology_database,
        iprscan_file      => $self->iprscan_file,
        gff_file          => $self->gff_file,
        output_filename   => $self->_output_filename,
        summary_filename  => $self->_summary_filename,
        gff_filename      => $self->_gff_filename,
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
    extract_go_from_interpro_output -i iprscan_results.gff 

    # Provide an output file name for tab-delimited id:go mapping
    extract_go_from_interpro_output -i iprscan_results.gff -o iprscan_go_terms.tsv
 
    # Add extracted GO terms to another GFF (e.g. PROKKA output)
    extract_go_from_interpro_output -i iprscan_results.gff -e prokka.out.gff

    # This help message
    extract_go_from_interpro_output -h
USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
