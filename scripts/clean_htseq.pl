#!/usr/bin/env perl
#$Id: clean_htseq.pl,v 1.3 2015/03/02 17:24:35 yk336 Exp $

#
# create pbs file
#

use warnings;
use strict;
use File::Basename;
use POSIX;

my $stop = shift || "__";

while (<>) {
    last if (/^$stop/);
    print;
}
