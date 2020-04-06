#!/usr/bin/env perl
#$Id: run_clean_htseq.pl,v 1.2 2015/03/02 17:24:35 yk336 Exp $

#
# create pbs file
#

use warnings;
use strict;
use File::Basename;
use POSIX;

my $dir = shift;
my $e1 = shift;
my $e2 = shift;
my $stop = shift;

die "$e1 eq $e2" if ($e1 eq $e2);



my $find = "find $dir -name \"*${e1}\"";
my $out = `$find`;


my @files = split(/\n/, $out);
for my $f (@files) {
    my $o = $f;
    $o =~ s/${e1}$/$e2/;
    my $cmd = "clean_htseq.pl $stop $f > $o";
    print "$cmd\n";
    system($cmd);
}

