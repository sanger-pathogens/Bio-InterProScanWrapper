package Bio::InterProScanWrapper::ExtractGoFromInterProOutput;

# ABSTRACT: extract GO terms from the InterProScan GFF output

=head1 SYNOPSIS
extract GO terms from the InterProScan GFF output
   use Bio::InterProScanWrapper::ExtractGoFromInterProOutput;
   
   my $obj = Bio::InterProScanWrapper::ExtractGoFromInterProOutput->new(
     iprscan_file      => 'iprscan_results.gff',
     output_file       => 'iprscan_results.gff.go.tsv',
     summary_file      => 'iprscan_results.gff.go.summary.tsv',
     gff_file          => 'prokka.out.gff',
     ontology_database => './gene_ontology.obo'
   );
   $obj->merge_files;
=cut

use Moose;
use Bio::InterProScanWrapper::Exceptions;
use Bio::Tools::GFF;
use GO::Parser;
use List::MoreUtils qw(uniq);

has 'iprscan_file'      => ( is => 'ro', isa => 'Str',       required => 1 );
has 'gff_file'          => ( is => 'ro', isa => 'Str|Undef', required => 0 );
has 'output_filename'   => ( is => 'ro', isa => 'Str',       default => 'iprscan_results.gff.go.tsv' );
has 'summary_filename'  => ( is => 'ro', isa => 'Str',       default => 'iprscan_results.gff.go.summary.tsv' );
has 'gff_filename'      => ( is => 'ro', isa => 'Str|Undef' );
has 'ontology_database' => ( is => 'ro', isa => 'Str',              lazy => 1, default => $ENV{'GO_OBO'} );
#has '_graph_obj'        => ( is => 'ro', isa => 'GO::Model::Graph', lazy => 1, builder => '_build__graph_obj' );
has '_output_fh'	=> ( is => 'ro', lazy => 1, builder => '_build__output_fh');	
has '_summary_fh'       => ( is => 'ro', lazy => 1, builder => '_build__summary_fh' );
has '_gff_obj'          => ( is => 'ro', lazy => 1, builder => '_build__gff_obj' );
has '_ontology_hash'     => ( is => 'ro', lazy => 1, builder => '_build__ontology_hash' );

sub _build__ontology_database {
  my ($self) = @_;
  (-e $self->ontology_database) or Bio::InterProScanWrapper::Exceptions::FileNotFound->throw( error => "Couldnt open file: " . $self->ontology_database );
  return 1;  
}

sub _build__output_fh {
  my ($self) = @_;
  open(my $fh, '>', $self->output_filename) or Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile->throw (
    error => "Couldn't write Gene:GO term mapping to TSV file: " . $self->output_filename );
  return $fh;
}

sub _build__summary_fh {
  my ($self) = @_;
  open(my $fh, '>', $self->summary_filename) or Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile->throw (
    error => "Couldn't write GO term summary to TSV file: " . $self->summary_filename );
  return $fh;
}

#sub _build__graph_obj {
#  my ($self) = @_;
#  my $parser = new GO::Parser({handler=>'obj'});
#  $parser->parse($self->ontology_database);
#  my $graph = $parser->handler->graph;
#  return $graph;
#}

sub _build__ontology_hash {
  my ($self) = @_;
  
  open(my $fh, '<', $self->ontology_database) or Bio::InterProScanWrapper::Exceptions::FileNotFound->throw (
    error => "Couldn't find ontology database (.obo): " . $self->ontology_database );  

  my %ontology_hash;
  local $/ = "[Term]";
  while (my $chunk = <$fh>) {
    my ($go_id) = $chunk =~ /id:.+/g;
    my ($go_name) = $chunk =~ /name:.+/g;
    my ($go_namespace) = $chunk =~ /namespace:.+/g;
    if (defined $go_id) {
      $ontology_hash{ substr($go_id, 4) } = { 'go_name' => substr($go_name, 6),
                                              'go_namespace' => substr($go_namespace, 11) };
    }
  }
  close($fh);
  
  return \%ontology_hash;
}

sub _extract_ontology_terms {
  my ($self) = @_;
  my %extracted_ontology_terms;
  my $gffio = Bio::Tools::GFF->new(-file => $self->iprscan_file, -gff_version => 3 );
  
  eval {      
	local $SIG{__WARN__} = sub { @_; };      
	my $feature = $gffio->next_feature(); 
  };
   
  if (!$@) {
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
  }  

  my $unique_ontology_terms = $self->_get_unique_ontology_terms(\%extracted_ontology_terms);
  return $unique_ontology_terms;
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
  foreach my $seq_id ( keys %{ $ontology_terms_to_write } ) {
    my $ontology_term_string = join( ";", @{ $ontology_terms_to_write->{$seq_id} } );
    $ontology_term_string =~ s/\"//g;
    print {$self->_output_fh} join("\t", $seq_id, $ontology_term_string) . "\n";
  }
  close($self->_output_fh);
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
        $ontology_counts{$go_id}->{'count'} = 1;
        if ( exists $self->_ontology_hash->{$go_id} ) {
          $ontology_counts{$go_id}->{'go_name'} = $self->{_ontology_hash}->{$go_id}->{'go_name'};
          $ontology_counts{$go_id}->{'go_namespace'} = $self->{_ontology_hash}->{$go_id}->{'go_namespace'};
        } 
#        my $term = $self->_graph_obj->get_term($go_id);
#        eval {
#          $ontology_counts{$go_id}->{'name'} = $term->name;
#          $ontology_counts{$go_id}->{'namespace'} = $term->namespace;
#        };
#        if( !$@ ) {
#          $ontology_counts{$go_id}->{'name'} = $term->name;
#          $ontology_counts{$go_id}->{'namespace'} = $term->namespace;
#        }        
      }
    }
  }
  return \%ontology_counts;
}

sub _write_go_term_summary {
  my ($self) = @_;
  my $ontology_terms_to_summarise = $_[1];
  my $ontology_term_counts = $self->_count_go_term_occurence($ontology_terms_to_summarise);   
  foreach my $go_id (reverse sort { $ontology_term_counts->{$a}->{'count'} <=> $ontology_term_counts->{$b}->{'count'} } keys %{$ontology_term_counts}) {
    if ( exists $ontology_term_counts->{$go_id}->{'go_name'} && exists $ontology_term_counts->{$go_id}->{'go_namespace'}) {
      print {$self->_summary_fh} join("\t", $go_id, $ontology_term_counts->{$go_id}->{'count'}, $ontology_term_counts->{$go_id}->{'go_name'}, $ontology_term_counts->{$go_id}->{'go_namespace'}) . "\n";
    } else {
      print {$self->_summary_fh} join("\t", $go_id, $ontology_term_counts->{$go_id}->{'count'}) . "\n";
    }
  }
  close($self->_summary_fh);
}

sub _add_go_terms_to_gff {
  my ($self) = @_;
  my $ontology_terms = $_[1];
  open(my $gff_output_fh, '>', $self->gff_filename) or Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile->throw (
      error => "Couldn't write extended GFF: " . $self->gff_filename );

  my $gffio = Bio::Tools::GFF->new( -file => $self->gff_file, -gff_version => 3 );
  print $gff_output_fh join(" ", "##gff-version", $gffio->gff_version) . "\n";

  while (my $segment = $gffio->next_segment ) {
    print $gff_output_fh join(" ", "##sequence-region", $segment->id, $segment->start, $segment->end) . "\n";
  }  

  while(my $feature = $gffio->next_feature ) {
    my $feature_id = [$feature->get_tag_values('ID')]->[0];
    if (exists $ontology_terms->{ $feature_id } ) {
      my @ontology_terms_to_add = @{$ontology_terms->{ $feature_id }};
      @ontology_terms_to_add = map "\"$ontology_terms_to_add[$_]\"", 0..$#ontology_terms_to_add; # escape quotes as gff_string removes them
      $feature->add_tag_value( 'Ontology_term', @ontology_terms_to_add );
    }
   print $gff_output_fh $gffio->gff_string($feature) . "\n";
  }

  my $cmd = "sed -n '/##FASTA/,//p' " . $self->gff_file;
  my $seqs = `$cmd`;  
  print $gff_output_fh $seqs;

  close($gff_output_fh);
}

sub run {
  my ($self) = @_;  
  my $extracted_ontology_terms = $self->_extract_ontology_terms;
  $self->_write_go_terms_to_tsv($extracted_ontology_terms);  
  $self->_write_go_term_summary($extracted_ontology_terms);
  $self->_add_go_terms_to_gff($extracted_ontology_terms) if (defined $self->gff_file);
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
