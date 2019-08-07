#!/usr/bin/env perl

#
# erv: map to genome
#

use warnings;
use strict;
use File::Basename;
use Cwd;
#use File::Type;
use Getopt::Long;
use Pod::Usage;



my $help = 0;
my $man = 0;
my ($btrim, $aligner, $bwa, $samtools, $filter, $bedtools,);
my ($genome, $genome_Bowtie2, $bed, $genomefile, $gtf, $transcriptome, $adaptor, );


my $cell = "sample";          # sample name
my $workdir = ".";            # working dir "$cell"
my $outdir = "tmp";           # dir under $cell

my $stage  = 0;
my $stage2 = 0;

my $fastq;             # sequence file

my $length = 40;
my $score_offset = 33;
my $score = 25;
my $cat = '';


my $test = 0;

print map("\t$_", @ARGV), "\n";


GetOptions (
    'help|h|?'    => \$help,	    
    'man'       => \$man,	    
    "test|t"      => \$test,
    "cell=s"    => \$cell,
    "workdir=s" => \$workdir,
    "outdir=s"  => \$outdir,

    "stage=i"   => \$stage,
    "stage2=i"  => \$stage2,

    "length=i"  => \$length,
    "score_offset=i"  => \$score_offset,

    "btrim=s"     => \$btrim,
    "adaptor=s"     => \$adaptor,
    "bwa=s" => \$bwa,
    "samtools=s" => \$samtools,
    "filter=s" => \$filter,
    "tophat=s" => \$aligner,

    "bedtools=s" => \$bedtools,
    "bed=s" => \$bed,
    "genomefile=s" => \$genomefile,
    
    "genome=s" => \$genome,
    "genome_Bowtie2=s" => \$genome_Bowtie2,
    "gtf=s" => \$gtf,
    "transcriptome=s" => \$transcriptome,
    
    "cat"       => \$cat,
    "score=i"   => \$score,

    "fastq=s"  => \$fastq,   ### absolute path
    
    ) or pod2usage( "Try '$0 --help' for more information." );

pod2usage(1) if $help;
pod2usage(2) if $man;

pod2usage(1) unless ($btrim && $aligner && $bwa && $samtools && $filter && $bedtools);
pod2usage(1) unless (-x $btrim && -x $aligner && -x $bwa && -x $samtools && -x $filter && -x $bedtools);
pod2usage(1) unless (-e $genome && -e $genome_Bowtie2 && -e $bed && -e $genomefile && -e $gtf && -e $transcriptome && -e $adaptor); 

pod2usage(1) unless ($fastq && $stage > 0 && $stage2 > 0);



### check if fastq file is zipped
my $zipped = 0;
my $ftype = File::Type->new->checktype_filename($fastq);
print STDERR "$fastq: $ftype\n";
if ($ftype =~ /zip/) {
    $zipped = 1;
}


### btrim
my $btrimout = "btrim_g_se.out";
my $btrim_cmd;
if ($score_offset == 33) {
    if ($zipped) {
	$btrim_cmd = "/bin/bash -c '$btrim -l $length -w 10 -a 25 -p $adaptor -3 -P -o $btrimout -t <(gunzip -c $fastq) -C > btrim.log 2> btrim.log'";
    } else {
	$btrim_cmd = "/bin/bash -c '$btrim -l $length -w 10 -a 25 -p $adaptor -3 -P -o $btrimout -t <(cat $fastq) -C > btrim.log 2> btrim.log'";
    }
} else {
    if ($zipped) {
	$btrim_cmd = "/bin/bash -c '$btrim -i -l $length -w 10 -a 25 -p $adaptor -3 -P -o $btrimout -t <(gunzip -c $fastq) -C > btrim.log 2> btrim.log'";
    } else {
	$btrim_cmd = "/bin/bash -c '$btrim -i -l $length -w 10 -a 25 -p $adaptor -3 -P -o $btrimout -t <(cat $fastq) -C > btrim.log 2> btrim.log'";
    }
}


### bwa
my $bwabam = "bwa.bam";
#my $bwa_cmd = "/bin/bash -c '$bwa mem -t 8 -p $genome ${btrimout} | $samtools view -Sh -F4 - | tee >($samtools view -Shb - | $samtools sort - -o bwa_unfiltered.bam) | $filter | $samtools view -bSh - > $bwabam'";
my $bwa_cmd = "/bin/bash -c '$bwa mem -t 8 -p $genome ${btrimout} | $samtools view -Sh -F4 - | $filter | $samtools view -bSh - > $bwabam'";


### sort
my $bwabam_sorted = "bwa_sorted.bam";
my $sort_cmd = "$samtools sort $bwabam -o $bwabam_sorted";

# index
my $bamindex_cmd = "$samtools index ${bwabam_sorted}";


### count
my $cntfile = "herv_coverage_GRCh38_genome.txt";
my $count_cmd = "$bedtools coverage -b ${bwabam_sorted} -a $bed -counts -sorted -g $genomefile > $cntfile";

### tophat2
my $files = "btrim_g_se.out";
my $aln_log = "align.log";
my $aln_err = "align.err";
my $thread = "--num-threads 2";
my $out = "-o GRCh38";
my $ann = "-G $gtf";
my $aln_cmd = "$aligner --b2-very-fast --no-novel-junc --transcriptome-index=$transcriptome --no-coverage-search $thread $ann $out $genome_Bowtie2 $files > $aln_log 2> $aln_err";

# index
my $bam = "accepted_hits.bam";
my $bamindex_cmd2 = "$samtools index $bam";

# count
my $count     = "htseq.cnt"; 
my $count_log = "htseq.log";
my $count_cmd2 = "$samtools view $bam | python2.7 -m HTSeq.scripts.count -f sam -s no - $gtf > $count 2> $count_log";



chdir($workdir);
my $wdir = "$cell";	
my $cmd = "mkdir -p $wdir";
&cmd($cmd);
chdir($wdir);




# btrim
if ($stage <= 1 && $stage2 >= 1) {
    &cmd($btrim_cmd);
}

# bwa
if ($stage <= 2 && $stage2 >= 2) {
    &cmd($bwa_cmd);
#    unlink($btrimout) if (-s $bwabam > 10);
}


# sort
if ($stage <= 3 && $stage2 >= 3) {
    &cmd($sort_cmd);
    &cmd($bamindex_cmd);
    unlink($bwabam);
}

# count
if ($stage <= 4 && $stage2 >= 4) {
    &cmd($count_cmd);
}

# tophat
if ($stage <= 5 && $stage2 >= 5) {
    &cmd($aln_cmd);
    chdir("GRCh38");
    &cmd($bamindex_cmd2);
}

# count2
if ($stage <= 6 && $stage2 >= 6) {
    &cmd($count_cmd2);
}



sub cmd {
    my ($c, ) = @_;

    print "In ", cwd(), ":\n";
    print "$c\n";
    system($c) unless ($test);
}


__END__
=head1 NAME

erv_se_genome_v2.pl - Script to run ervmap

=head1 SYNOPSIS

erv_se_genome_v2.pl [options]

   Options:
    -h, -? --help            brief help message
    -t, --test               print out commands without run
    --btrim                  path to btrim (http://graphics.med.yale.edu/trim/)
    --tophat                 path to tophat
    --bwa                    path to bwa
    --samtools               path to samtools
    --filter                 path to filter (parse_bam.pl)
    --bedtools               path to bedtools

    --genome                 path to bwa human genome index
    --genome_Bowtie2         path to Bowtie2 human genome index
    --bed                    path to bed file of ERVs
    --genomefile             path to genome size file
    --gtf                    path to gtf file of human gene annotation
    --transcriptome          path to known transcriptome, used by tophat2
    --adaptor                path to adaptor files, used by btrim (http://graphics.med.yale.edu/trim/)

    --fastq                  fastq file
    --stage                  start stage (see below)
    --stage2                 end stage (see below)


    Stages:
      1                      trim adaptors and low quality regions
      2                      map reads using bwa
      3                      sort bam file
      4                      count reads mapped to ERVs
      5                      map reads using  tophat2
      6                      counts reads mapped to genes

=cut

