#!/usr/bin/env perl

#
# test read_in_tab_delim_file_to_hash
#

use warnings;
use strict;


my $norm = shift;
my $fn   = shift;
my $sizecol = shift // 1;  # col of size factor

my $test = 0;

my $n = read_in_tab_delim_file_to_hash($norm, 0);

if ($test) {
    for my $k (keys %{$n}) {
	print STDERR
	    join("\t",
		 ">$k<",
		 $n->{$k}[1],
	    ), "\n";
    }
}

my $fh = get_in_fh($fn);
my @sizes = ();
while (my $li = <$fh>) {
    chomp($li);
    my @t = split(/\t/, $li);

    if ($t[0] eq "gene") {
#	print "$t[-1]\t", scalar @t, "\n";
	for (my $i=1; $i<@t; $i++) {
	    $sizes[$i] = $n->{ $t[$i] }[$sizecol];
	    print STDERR "$t[$i]\t$sizes[$i]\n";
	}
	print "$li\n";
	next;
    }

    print "$t[0]\t";
    for (my $i=1; $i<@t; $i++) {
	printf("%.3f\t",  $t[$i]/$sizes[$i]);
    }
    print "\n";
}
close($fh);


for (my $i=1; $i<@sizes; $i++) {
    print STDERR join("\t",
		      $i,
		      $sizes[$i],
	), "\n";
}


# Use "," seperated column indices to construct key; value is the array of all
# columns. If 3rd arg is not used, default is "|"
sub read_in_tab_delim_file_to_hash {
    my ($fn, $col_list, $key_delim, ) = @_;
    
    my %h = ();

    my @keyinx = split(/,/, $col_list);
    $key_delim = "|" unless ($key_delim);

    my $fh = &get_in_fh($fn);
    while (my $li = <$fh>) {
	chomp($li);
	next if ($li =~ /^\#/);
	my @t = split(/\t/, $li);
	my $key = join($key_delim, map($t[$_], @keyinx));
	$h{ $key } = [ @t ];
    }
    close($fh);
    return \%h;
}

sub get_in_fh {
    my ($fn, ) = @_;
    my $fh;

    open($fh, "<$fn") || die "cannot open file $fn!";
    return $fh;
}
