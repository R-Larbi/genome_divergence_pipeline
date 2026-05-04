
set seaview = "/home/larbi/seaview5-64/seaview/seaview"

if ($6 == "") then
   echo  " "
   echo "$0 : extract CDS sequences SEQ1 SEQ2 from BLASTDB , align them at protein level, compute dN and dS "
   echo "Usage: $0 SEQ1 SEQ2 BLASTDB genetic_code_1 genetic_code_2 outfile"
   exit
endif

set SEQ1 = $1
set SEQ2 = $2
set BLASTDB = $3
set genetic_code_1 = $4
set genetic_code_2 = $5
set outfile = $6

# Empty files
echo "" > "$1"-"$2"-tmp_seq_nuc.Ka
echo "" > "$1"-"$2"-tmp_seq_nuc.Ks
echo "" > $outfile

# Extract sequences
blastdbcmd -db $BLASTDB  -entry $SEQ1 > "$1"-"$2"-tmp_seq_nuc1.fa
blastdbcmd -db $BLASTDB  -entry $SEQ2 > "$1"-"$2"-tmp_seq_nuc2.fa

set n1 = `grep ">" "$1"-"$2"-tmp_seq_nuc1.fa | wc -l`
set n2 = `grep ">" "$1"-"$2"-tmp_seq_nuc2.fa | wc -l`

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
echo ";; " > "$1"-"$2"-tmp_seq_nuc.mase
echo ";/transl_table=$genetic_code_1" >> "$1"-"$2"-tmp_seq_nuc.mase
cut -f1 -d" " "$1"-"$2"-tmp_seq_nuc1.fa | sed "s/>//g" >> "$1"-"$2"-tmp_seq_nuc.mase
echo ";/transl_table=$genetic_code_2" >> "$1"-"$2"-tmp_seq_nuc.mase
cut -f1 -d" " "$1"-"$2"-tmp_seq_nuc2.fa  |cut -f1 -d" " | sed "s/>//g" >> "$1"-"$2"-tmp_seq_nuc.mase

# Align MASE file
$seaview -o "$1"-"$2"-tmp_seq_nuc.aln.mase -align_at_protein_level -align "$1"-"$2"-tmp_seq_nuc.mase >& "$1"-"$2"-tmp_aln.log

# Compute distances
$seaview  -distance  Ks -distance_matrix "$1"-"$2"-tmp_seq_nuc.Ks -build_tree "$1"-"$2"-tmp_seq_nuc.aln.mase >& "$1"-"$2"-tmp_Ks.log
$seaview  -distance  Ka -distance_matrix "$1"-"$2"-tmp_seq_nuc.Ka -build_tree "$1"-"$2"-tmp_seq_nuc.aln.mase >& "$1"-"$2"-tmp_Ka.log

# Check saturation
set saturationKs = `grep "Saturation between" "$1"-"$2"-tmp_Ks.log |wc -l`
set saturationKa = `grep "Saturation between" "$1"-"$2"-tmp_Ka.log |wc -l`

set Ks = "NA"
if($saturationKs == 0) then 
	set n = `cat "$1"-"$2"-tmp_seq_nuc.Ks | wc -l`
	if($n != 7) then
		echo "EXIT: problem in "$1"-"$2"-tmp_seq_nuc.Ks"
		echo "$SEQ1 $SEQ2 NA NA" > $outfile
		exit(1)
	endif
	set Ks = `tail -1 "$1"-"$2"-tmp_seq_nuc.Ks |cut -f2 -d" "`
else if ($saturationKs == 1) then 
	set Ks = 99
endif

set Ka = "NA"
if($saturationKa == 0) then 
	set n = `cat "$1"-"$2"-tmp_seq_nuc.Ka | wc -l`
	if($n != 7) then
		echo "EXIT: problem in "$1"-"$2"-tmp_seq_nuc.Ka"
		echo "$SEQ1 $SEQ2 NA NA" > $outfile
		exit(1)
	endif
	set Ka = `tail -1 "$1"-"$2"-tmp_seq_nuc.Ka |cut -f2 -d" "`
else if ($saturationKa == 1) then 
	set Ka = 99
endif


# Extract distances
set Ka = `tail -1 "$1"-"$2"-tmp_seq_nuc.Ka |cut -f2 -d" "`

echo "$SEQ1 $SEQ2 $Ka $Ks" > $outfile

\rm "$1"-"$2"-tmp_seq_nuc1.fa "$1"-"$2"-tmp_seq_nuc2.fa "$1"-"$2"-tmp_seq_nuc.mase "$1"-"$2"-tmp_seq_nuc.aln.mase "$1"-"$2"-tmp_seq_nuc.Ks "$1"-"$2"-tmp_seq_nuc.Ka "$1"-"$2"-tmp_Ks.log "$1"-"$2"-tmp_Ka.log "$1"-"$2"-tmp_aln.log


