#!/usr/bin/env perl

#
# print out interleaved fastq
#

use strict;
use warnings;

use Getopt::Long;
use File::Type;

my @fq1 = ();
my @fq2 = ();

GetOptions ("read1=s" => \@fq1,
	    "read2=s" => \@fq2,
	    );

@fq1 = split(/,/, join(',', @fq1));
@fq2 = split(/,/, join(',', @fq2));

print STDERR "Check the file names are in exact order:\n";
print STDERR "\tFile names for 1st reads:\n";
print STDERR map("\t$_\n", @fq1);
print STDERR "\n";
print STDERR "\tFile names for 2nd reads:\n";
print STDERR map("\t$_\n", @fq2);


die scalar(@fq1), "!=", scalar(@fq2) if (@fq1 != @fq2);


my @fh1 = ();
my @fh2 = ();


for (my $i=0; $i<@fq1; $i++) {
    my $ftype = File::Type->new->checktype_filename($fq1[$i]);
    print STDERR "$fq1[$i]: $ftype\n";
#    if ($fq1[$i] =~ /\.gz$/) {
    if ($ftype =~ /zip/) {
	open $fh1[$i], '-|', 'gzip', '-dc', $fq1[$i];
    } else {
	open($fh1[$i], "<$fq1[$i]") or die "cannot open file $fq1[$i]";
    }

    $ftype = File::Type->new->checktype_filename($fq1[$i]);
    print STDERR "$fq2[$i]: $ftype\n";
    if ($ftype =~ /zip/) {
	open $fh2[$i], '-|', 'gzip', '-dc', $fq2[$i];
    } else {
	open($fh2[$i], "<$fq2[$i]") or die "cannot open file $fq2[$i]";
    }
}



for (my $i=0; $i<@fq1; $i++) {
    my ($f1, $f2, ) = ($fh1[$i], $fh2[$i], );
    while (my $li = <$f1>) {
	# 1st read
	print $li;
	$li = <$f1>;
	print $li;
	$li = <$f1>;
	print $li;
	$li = <$f1>;
	print $li;

	# 2nd read
	$li = <$f2>;
	print $li;
	$li = <$f2>;
	print $li;
	$li = <$f2>;
	print $li;
	$li = <$f2>;
	print $li;
    }
}



for (my $i=0; $i<@fq1; $i++) {
    close($fh1[$i]);
    close($fh2[$i]);
}
