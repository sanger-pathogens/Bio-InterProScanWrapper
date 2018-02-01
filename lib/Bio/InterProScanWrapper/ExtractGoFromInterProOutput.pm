package Bio::InterProScanWrapper::ExtractGoFromInterProOutput;

# ABSTRACT: extract GO terms from the InterProScan GFF output

=head1 SYNOPSIS
extract GO terms from the InterProScan GFF output
   use Bio::InterProScanWrapper::ExtractGoFromInterProOutput;
   
   my $obj = Bio::InterProScanWrapper::ExtractGoFromInterProOutput->new(
     iprscan_file      => 'iprscan_results.gff',
     output_file       => 'iprscan_results.gff.go.tsv',
     summary_file      => 'iprscan_results.gff.go.summary.tsv',
     gff_to_extend     => 'prokka.out.gff',
     ontology_database => '/lustre/scratch118/infgen/pathdev/vo1/gene_ontology.obo'
   );
   $obj->merge_files;
=cut

use Moose;
use Bio::InterProScanWrapper::Exceptions;
use Bio::Tools::GFF;
use GO::Parser;
use List::MoreUtils qw(uniq);
use Data::Dumper;

has 'iprscan_file'       => ( is => 'ro', isa => 'Str',              required => 1 );
has 'output_filename'    => ( is => 'ro', isa => 'Str',              default => 'iprscan_results.gff.go.tsv' );
has 'summary_filename'   => ( is => 'ro', isa => 'Str',              default => 'iprscan_results.gff.go.summary.tsv' );
has 'gff_to_extend'      => ( is => 'ro', isa => 'Str|Undef',        required => 0 );
has 'ontology_database'  => ( is => 'ro', isa => 'Str',              default => '/lustre/scratch118/infgen/pathdev/vo1/gene_ontology.obo' );
has 'graph_obj'          => ( is => 'ro', isa => 'GO::Model::Graph', lazy => 1, builder => '__build_ontology_parser' );

sub __build_ontology_parser {
  my ($self) = @_;
  my $parser = new GO::Parser({handler=>'obj'});
  $parser->parse($self->ontology_database);
  my $graph = $parser->handler->graph;
  return $graph;
}

sub _extract_ontology_terms {
  my ($self) = @_;
  my %extracted_ontology_terms;
  my $gffio = Bio::Tools::GFF->new(-file => $self->iprscan_file, -gff_version => 3);
  while (my $feature = $gffio->next_feature()) {
    if ( $feature->has_tag('Ontology_term') ) {
      my @ontology_values = $feature->get_tag_values('Ontology_term');
      if ( exists $extracted_ontology_terms{ $feature->seq_id  } ) {
         $extracted_ontology_terms{ $feature->seq_id } = [ @{ $extracted_ontology_terms{ $feature->seq_id} }, @ontology_values ];
      } else {
        $extracted_ontology_terms{ $feature->seq_id  } =  \@ontology_values ;
      }
    }
  }  
  $self->_get_unique_ontology_terms(\%extracted_ontology_terms);
  return \%extracted_ontology_terms;
}

sub _get_unique_ontology_terms {
  my ($self) = @_;
  my $all_ontology_terms = $_[1];
  my %unique_ontology_terms;
  foreach my $seq_id ( keys %{ $all_ontology_terms } ) {
    my @uniq_terms = uniq @{ $all_ontology_terms->{$seq_id} };
    $unique_ontology_terms{$seq_id} = \@uniq_terms;
  }
  return \%unique_ontology_terms;
}

sub _write_go_terms_to_tsv {
  my ($self) = @_;
  my $ontology_terms_to_write = $_[1];
  open(my $GO_TSV, '>', $self->output_filename) or Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile->throw (
    error => "Couldn't write GO terms to TSV file: " . $self->output_filename );
  foreach my $seq_id ( keys %{ $ontology_terms_to_write } ) {
    my $ontology_term_string = join( ";", @{ $ontology_terms_to_write->{$seq_id} } );
    $ontology_term_string =~ s/\"//g;
    print $GO_TSV join("\t", $seq_id, $ontology_term_string);
  }
  close($GO_TSV);
  return 1;
}

sub _count_go_term_occurence {
  my ($self) = @_;
  my $ontology_terms = $_[1];
  my %ontology_counts;
  foreach my $seq_id ( keys %{ $ontology_terms } ) {
    foreach my $go_id ( @{ $ontology_terms->{$seq_id} } ) {
      $go_id =~ s/\"//g;
      if ( exists $ontology_counts{$go_id} ) {
        $ontology_counts{$go_id}->{'count'}++;
      } else {
        my $term = $self->graph_obj->get_term($go_id);
        $ontology_counts{$go_id}->{'count'} = 1;
        $ontology_counts{$go_id}->{'name'} = $term->name;
        $ontology_counts{$go_id}->{'namespace'} = $term->namespace;
      }
    }
  }
  return \%ontology_counts;
}

sub _write_go_term_summary {
  my ($self) = @_;
  my $ontology_terms_to_summarise = $_[1];
  
  my $ontology_term_counts = $self->_count_go_term_occurence($ontology_terms_to_summarise);   
  open(my $GO_SUMMARY, '>', $self->summary_filename) or Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile->throw (
    error => "Couldn't write GO terms counts to summary file: " . $self->summary_filename );
  foreach my $go_id (reverse sort { $ontology_term_counts->{$a}->{'count'} <=> $ontology_term_counts->{$b}->{'count'} } keys %{$ontology_term_counts}) {
    print $GO_SUMMARY join("\t", $go_id, $ontology_term_counts->{$go_id}->{'count'}, $ontology_term_counts->{$go_id}->{'name'}, $ontology_term_counts->{$go_id}->{'namespace'});
  }
  close($GO_SUMMARY);
}

sub run {
  my ($self) = @_;
  
  my $extracted_ontology_terms = $self->_extract_ontology_terms;
  $self->_write_go_terms_to_tsv($extracted_ontology_terms);  
  $self->_write_go_term_summary($extracted_ontology_terms);
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
