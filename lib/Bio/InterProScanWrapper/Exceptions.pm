package Bio::InterProScanWrapper::Exceptions;
# ABSTRACT: Exceptions for input data 

=head1 SYNOPSIS

Exceptions for input data 

=cut


use Exception::Class (
    Bio::InterProScanWrapper::Exceptions::FileNotFound       => { description => 'Couldnt open the file' },
    Bio::InterProScanWrapper::Exceptions::CouldntReadFile    => { description => 'Couldnt open the file for reading' },
    Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile => { description => 'Couldnt open the file for writing' },
    Bio::InterProScanWrapper::Exceptions::LSFJobFailed       => { description => 'Jobs failed' },
);  

1;
