#!/usr/bin/env perl

#
# parse bam from bwa
#

use strict;
use warnings;

use Getopt::Long;
my $test;
my $fix;
GetOptions ("test" => \$test,
	    "fix" => \$fix,
	    );

while (my $li = <>) {
    chomp($li);
    my @t = split(/\t/, $li);
#    print "$t[2]\t$t[10]\n";

    if ($li =~ /^\@/) {
	print "$li\n" ;
	next;
    }

    next if (soft_clipping(\@t));
    my $seq = $t[9];
    my $seql = length($seq);
    #print "$seq\n";
    
    my ($nm, $as, $xs, ) = (1000, 0, 0,);

    for (my $i=10; $i<@t; $i++) {
	if ($t[$i] =~ /^AS:i:(\d+)/) {       # Alignment score  
	    $as = $1;
	} elsif ($t[$i] =~ /^XS:i:(\d+)/) {  # Suboptimal alignment score
	    $xs = $1;
	} elsif ($t[$i] =~ /^NM:i:(\d+)/) {
	    $nm = $1;
	}
    }

    print join("\t",	       
	       "NM-AS-XS", $nm, $as, $xs, $as - $xs), "\n" if ($test);

    if ($fix) {
	if ($nm < 3 && ($as - $xs >= 5)) {
	    print "$li\n";
	}
    } else {
	my $nmperc = $nm / $seql;
	#my $asxsperc = ($as - $xs) / $seql;
	if ($nmperc < 0.02 && ($as - $xs >= 5)) {
	    print "$li\n";
	}
    }
}

sub soft_clipping {
    my ($t, ) = @_;
    
    my $c = $t->[5];
    my @l = split(/[0-9]+/, $c);
    shift(@l);  # 1st is empty
    my @d = split(/[a-zA-Z]+/, $c);
    die "$#l != $#d" if (scalar @l != scalar @d);

    if ($test) {
	print "\t$c\n";
	print "\t->\t", map(">$_< ", @d), "\n";
	print "\t=>\t", map(">$_< ", @l), "\n";
    }
    
    my ($tot, $s, $h, ) = (0, 0, 0,);
    for (my $i=0; $i<@l; $i++) {
	$tot += $d[$i];
	$h += $d[$i] if ($l[$i] eq "H");
	$s += $d[$i] if ($l[$i] eq "S");
    }
    print join("\t", "\t",  $tot, $s, $h, ),"\n" if ($test);

    my $perc = ($h+$s) / $tot;

    my $r;
    if ($fix) {
	$r = ($h+$s>=3) ? 1 : 0;
    } else {
	$r = ($perc>=0.02) ? 1 : 0;
    }
    return $r;
}
