
set seaview = "/home/larbi/seaview5-64/seaview/seaview"

if ($5 == "") then
   echo  " "
   echo "$0 : extract CDS sequences SEQ1 SEQ2 from BLASTDB , align them at protein level, compute dN and dS "
   echo "Usage: $0 SEQ1 SEQ2 BLASTDB genetic_code outfile"
   exit
endif

set SEQ1 = $1
set SEQ2 = $2
set BLASTDB = $3
set genetic_code = $4
set outfile = $5

# Empty files
echo "" > tmp_seq_nuc.Ka
echo "" > tmp_seq_nuc.Ks
echo "" > $outfile

# Extract sequences
blastdbcmd -db $BLASTDB  -entry $SEQ1 > tmp_seq_nuc1.fa
blastdbcmd -db $BLASTDB  -entry $SEQ2 > tmp_seq_nuc2.fa

set n1 = `grep ">" tmp_seq_nuc1.fa | wc -l`
set n2 = `grep ">" tmp_seq_nuc2.fa | wc -l`

if($n1 != 1) then
	echo "EXIT: $SEQ1 not found"
	echo "$SEQ1 $SEQ2 NA NA" > $outfile
	exit(1)
endif
if($n2 != 1) then
	echo "EXIT: $SEQ2 not found"
	echo "$SEQ1 $SEQ2 NA NA" > $outfile
	exit(1)
endif

# Prepare MASE file (with information on genetic code)
echo ";; " > tmp_seq_nuc.mase
echo ";/transl_table=$genetic_code" >> tmp_seq_nuc.mase
cut -f1 -d" " tmp_seq_nuc1.fa | sed "s/>//g" >> tmp_seq_nuc.mase
echo ";/transl_table=$genetic_code" >> tmp_seq_nuc.mase
cut -f1 -d" " tmp_seq_nuc2.fa  |cut -f1 -d" " | sed "s/>//g" >> tmp_seq_nuc.mase

# Align MASE file
$seaview -o tmp_seq_nuc.aln.mase -align_at_protein_level -align tmp_seq_nuc.mase >& tmp_aln.log

# Compute distances
$seaview  -distance  Ks -distance_matrix tmp_seq_nuc.Ks -build_tree tmp_seq_nuc.aln.mase >& tmp_Ks.log
$seaview  -distance  Ka -distance_matrix tmp_seq_nuc.Ka -build_tree tmp_seq_nuc.aln.mase >& tmp_Ka.log

# Check saturation
set saturationKs = `grep "Saturation between" tmp_Ks.log |wc -l`
set saturationKa = `grep "Saturation between" tmp_Ka.log |wc -l`

set Ks = "NA"
if($saturationKs == 0) then 
	set n = `cat tmp_seq_nuc.Ks | wc -l`
	if($n != 7) then
		echo "EXIT: problem in tmp_seq_nuc.Ks"
		echo "$SEQ1 $SEQ2 NA NA" > $outfile
		exit(1)
	endif
	set Ks = `tail -1 tmp_seq_nuc.Ks |cut -f2 -d" "`
else if ($saturationKs == 1) then 
	set Ks = 99
endif

set Ka = "NA"
if($saturationKa == 0) then 
	set n = `cat tmp_seq_nuc.Ka | wc -l`
	if($n != 7) then
		echo "EXIT: problem in tmp_seq_nuc.Ka"
		echo "$SEQ1 $SEQ2 NA NA" > $outfile
		exit(1)
	endif
	set Ka = `tail -1 tmp_seq_nuc.Ka |cut -f2 -d" "`
else if ($saturationKa == 1) then 
	set Ka = 99
endif


# Extract distances
set Ka = `tail -1 tmp_seq_nuc.Ka |cut -f2 -d" "`

echo "$SEQ1 $SEQ2 $Ka $Ks" > $outfile

\rm tmp_seq_nuc1.fa tmp_seq_nuc2.fa tmp_seq_nuc.mase tmp_seq_nuc.aln.mase tmp_seq_nuc.Ks tmp_seq_nuc.Ka tmp_Ks.log tmp_Ka.log tmp_aln.log


