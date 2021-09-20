#!/usr/bin/env perl

#
# merge counts
#

use warnings;
use strict;

use File::Basename;
 
my $gene_col = shift;   # gene
my $cnt_col  = shift;   # counts
my $ext      = shift;   # extension
my $curdir   = shift;   # directory

### the rest of ARGV is the files to exclude
my %exclude =  map { $_ => 1 } @ARGV;


my $test = 0;
my $cnt = 0;

my $dir;
opendir($dir, $curdir) || die "Cannot opendir $curdir: $!";
my @allfiles = grep { $_ =~ /$ext$/} readdir($dir);
closedir($dir);



my %allH = ();    # {gene}{subj} => cnt
my @cells = ();
### read in 
for my $f (sort @allfiles) {
    next if ($exclude{$f});
    &read_in($f);

    my $cell = basename($f);
    #print STDERR ">$cell<\n";
    $cell =~ s/(^.*)\..*?$/$1/;
    #print STDERR ">>$cell<<\n";
    push(@cells, $cell);
    $cnt++;
    last if ($test && $cnt >= 5);
}

### print header; remember to keep the same order as below
print "gene";
for my $c (@cells) {
    print "\t$c";
}
print "\n";

for my $g (sort keys %allH) {
    print "$g";

    ### print counts; remember to keep the same order as above
    for my $c (@cells) {
	print "\t", $allH{$g}{$c} ? $allH{$g}{$c} : 0;		   
    }
    print "\n";
}


sub read_in {
    my ($fn) = @_;

    my $subj = basename($fn);
    $subj =~ s/(^.*)\..*?$/$1/;
#    print STDERR "$subj\n";

    $fn = "$curdir/$fn";
    
    my $fh;
    open($fh, "<$fn") || die "cannot open $fn!";
    while (<$fh>) {
	next if (/^\#/);
	next if (/^$/);

	chomp($_);
#	my @t = split(/[\s\t]/);
	my @t = split(/\t/);

	my $gene = $t[$gene_col];
	my $cnt  = $t[$cnt_col];

	$gene =~ s/\#/\|/;

#	my $key = join("_", $chr, $pos, $gene);

	$allH{$gene}{$subj} = $cnt;
    }
    close($fh);
}


