package DumpVars;

use strict;
use parent qw/Exporter/;
use Data::Dmp;

our @EXPORT = qw/dumpVars/;

sub dumpVars {
  my $q = CGI->new();
  my $v = $q->Vars;
  return dmp($v);
}

1;
