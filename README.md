# ERVmap
ERVmap is one part curated database of human proviral ERV loci and one part a stringent algorithm to determine which ERVs are transcribed in their RNA seq data.

# **Citation** 
Tokuyama M. et. al., ERVmap analysis reveals genome-wide transcription of human endogenous retroviruses. Proc Natl Acad Sci U S A. 2018 Dec 11;115(50):12565-12572. doi: 10.1073/pnas.1814589115.

# **Installing**

### Install dependencies
``` 
bedtools2
cufflinks
bwa-0.7.17
cufflinks-2.2.1.Linux_x86_64
python
samtools-1.8
tophat-2.1.1.Linux_x86_64
tophat2
trim (http://graphics.med.yale.edu/trim/)
```

### Install .pl and r files
```
erv_genome.pl
interleaved.pl
run_clean_htseq.pl
merge_count.pl
normalize_with_file.pl
normalize_deseq.r
```

# **Map data to human genome (hg38)**

This step will yield raw counts for cellular genes and ERVmap loci as separate files.

### For single-end sequences:
```
erv_genome.pl -stage 1 -stage2 6 -fastq /${i}_SS.fastq.gz
```

### For pair-end sequences:
```
interleaved.pl --read1  ${i}_R1.fastq.gz  --read2 ${i}_R2.fastq.gz > ${i}.fastq.gz
erv_genome.pl -stage 1 -stage2 6 -fastq /${i}.fastq.gz
```

### Store output files
```
mkdir -p output
mv ./sample/herv_coverage_GRCh38_genome.txt ./output/erv/${i}.e
mv ./sample/GRCh38/htseq.cnt ./output/cellular/${i}.c
```

# **Clean up data, merge, and normalize**

These steps will yield normalized ERV read counts based on size factors obtained through DESeq2 analysis. 
Use the output files from above. 

```
run_clean_htseq.pl ./output/cellular c c2 __
merge_count.pl 3 6 e ./output/erv > ./output/erv/merged_erv.txt
merge_count.pl 0 1 c2 ./output/cellular > ./output/cellular/merged_cellular.txt
normalize_deseq.r  ./output/cellular/merged_cellular.txt ./output/cellular/normalized_cellular ./output/cellular/normalized_factors
normalize_with_file.pl ./output/cellular/normalized_factors ./output/erv/merged_erv.txt > ./output/$folder_name.txt
```

# **Authors**

* Maria Tokuyama
* Yong Kong



