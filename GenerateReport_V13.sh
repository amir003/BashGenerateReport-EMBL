#!/bin/bash

#-------------------------------------------------------------------------------------
#   Author : Amir Naar (amir.naar@embl.de)
#	Description : this script generates NGS Reports after galaxy workflow
#-------------------------------------------------------------------------------------

# If you use 'HERE' : just make sure to place this script on the same directory as the  
# 'galaxy' directory


# If you use 'CURRENT_ID'
# Pass as an argument your current path directory where all yours repositories are.
# For example, for the Santamaria's project take as argument: /g/furlong/santamaria/galaxy
# You may have a subdirectory where all the files are named: 'galaxy'

echo "Processing..."

# To take an argument 
#CURRENT_DIR="$1"

HERE="$PWD"

path_Galaxy="$HERE"/galaxy
#path_Galaxy="$CURRENT_DIR"

if [ -d "$path_Galaxy" ]; then
	echo "'galaxy' directory has been found."	
	echo "Take a coffee, the process may take a little time..."
	echo ""

	EXPERIMENTS="$path_Galaxy"/p*


	# Go in all the experiments : the name of these directory may begin by 'p*' (if it is not the case, change the path 'EXPERIMENTS')
	for EXP_1 in $EXPERIMENTS; 
	do
		# iterate on all the 'Experiments' directory

		##################################################################################
		##################################################################################
		NAMEDIR=$path_Galaxy
		LENGTH_NAMEDIR=${#NAMEDIR}
		LENGTH_CUT_NAMEDIR=$((LENGTH_NAMEDIR+1))
		NAMEDIR_EXP_CUT=${EXP_1:$LENGTH_CUT_NAMEDIR} # Name of the experiment for example : p1_55_vs_input_10-12

		# At first, going at the experiment : 'p1_55_vs_input_10-12'
		if [ -d "$EXP_1" ]; then
			
			echo "'$NAMEDIR_EXP_CUT' directory has been found." # $EXP_1 : is the complete path directory
			cd "$EXP_1"

	
			#######################################################################################
			#######################################################################################
			###			 FLAGSTAT Processing
			#######################################################################################
			#######################################################################################

			# 'flagstat' path directory
			flagStat_1="$EXP_1"/flagstat

			# Length of this path directory
			lengthFlag=${#flagStat_1}

			# add +1 inorder to not have the '/'(slash) in the name of the file
			lengthFlagPath=$((lengthFlag+1))

			if [ -d "$flagStat_1" ]; then
				echo "'flagstat' directory in $EXP_1 has been found."
				# go to 'flagstat' directory
				cd "$flagStat_1"

				# Create repository to put the flagStat files with only the third first lines
				flagResults="$flagStat_1"/FlagResults
				if [ ! -d "$flagResults" ]; then
					mkdir FlagResults
				fi

				FILES_FLAG="$flagStat_1"/*

				# Create a NEW Report 
				echo -ne > ../OUTPUT_$NAMEDIR_EXP_CUT.txt 

				for flagFiles in $FILES_FLAG;
				do
					# iterate on the files presents on the 'Tag_BAM' directory
					if [ -f "$flagFiles" ];then
						# Cut the name of the flag files
						nameCutFlag=${flagFiles:$lengthFlagPath}

						# Renaming of the flag files columns 
						
						if [[ $nameCutFlag == *"allreads"* ]]; then # flagfile contain 'allreads'
							if [[ $nameCutFlag == *"input"* ]]; then 
								id=$(echo $nameCutFlag | cut -d '_' -f 7) # obtain '10-12'

								nameCutFlag_Final="allreads_input_$id" # 'allreads_input_10-12'
							else 
								p=$(echo $nameCutFlag | cut -d '_' -f 6)
								id=$(echo $nameCutFlag | cut -d '_' -f 7)
								tab="_"

								nameCutFlag_Final="allreads_$p$tab$id" # 'allreads_p1_55'
							fi
						else # flagfile contain 'PhoPolII_TiGR'
							if [[ $nameCutFlag == *"input"* ]]; then 
								id=$(echo $nameCutFlag | cut -d '_' -f 5) # obtain '10-12'
								nameCutFlag_Final="XS-filt-input_$id" # 'XS-filt_input_10-12'
							else
								p=$(echo $nameCutFlag | cut -d '_' -f 4)
								id=$(echo $nameCutFlag | cut -d '_' -f 5)
								tab="_"

								nameCutFlag_Final="XS-filt_$p$tab$id" # 'XS-filt_p1_55'
							fi
						fi

						# Add for each flagstat files only the third first lines in 'FlagResults' repository
						sed -n 1,3p $flagFiles > FlagResults/$nameCutFlag_Final

						# Write the HEADER of the 4 first flagstat files 
						echo -ne $nameCutFlag_Final "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt
					fi
				done
			else
				echo "'flagstat' directory has been found."
			fi

			# Return to the global directory of the experiment. For example, at first, in: 'p1_55_vs_input_10-12'
			cd "$EXP_1"

			#######################################################################################
			#######################################################################################
			###			 PEAKS Processing
			#######################################################################################
			#######################################################################################

			# Go to the 'peaks' directory
			Peaks_dir="$EXP_1"/peaks
			# Length of the path directory
			length_peaks=${#Peaks_dir}
			# add +1 inorder to not have the '/'(slash) in the name of the file
			lengthPeaks_final=$((length_peaks+1))

			if [ -d "$Peaks_dir" ]; then
				echo "'peaks' directory has been found."
				cd "$Peaks_dir"

				# Create repository to put the results
				peakResults="$Peaks_dir"/CountResults
				if [ ! -d "$peakResults" ]; then
					mkdir CountResults
				fi

				FILES_PEAKS="$Peaks_dir"/*

				for peakFiles in $FILES_PEAKS;
				do
					if [ -f "$peakFiles" ];then
						# Name of the peak file 
						nameCutPeak=${peakFiles:$lengthPeaks_final}

						# Change the name of the header 
						if [[ $nameCutPeak == *"NO"* ]]; then 
							# work with the file name without the extension
							noName=id=$(echo $nameCutPeak | cut -d '.' -f 1)
							p=$(echo $noName | cut -d '_' -f 4)
							id=$(echo $noName | cut -d '_' -f 5)
							tab="_"

							nameCutPeak="NOXS_specific_peaks_$p$tab$id"
						else
							xsName=id=$(echo $nameCutPeak | cut -d '.' -f 1)

							p=$(echo $xsName | cut -d '_' -f 9)
							id=$(echo $xsName | cut -d '_' -f 10)
							tab="_"

							nameCutPeak="XS_specific_peaks_allreads_$p$tab$id"
						fi

						echo -ne $nameCutPeak "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt

						# Counting the peaks files
						countLine=$(more $peakFiles | wc -l)

						nameCountPeak=${nameCutPeak:0:4}

						# 2 files generated named : NOXS and XS_s
						echo $countLine > CountResults/$nameCountPeak
					fi
				done

			else
				echo "'peaks' directory has not be found."
			fi

			#######################################################################################
			#######################################################################################
			###			 BAM FILES Processing
			#######################################################################################
			#######################################################################################

			# Goo to 'Tag_BAM' directory
			Tag_BAM_1="$EXP_1"/Tag_BAM

			#Length of this path directory to substract it to the filenames
			length_Tag_BAM_1=${#Tag_BAM_1}
			# add +1 inorder to not have the '/'(slash) in the name of the file
			lengthBamPath=$((length_Tag_BAM_1+1))
			# obtain the length with : ${length_Tag_BAM_1}

			if [ -d "$Tag_BAM_1" ]; then
				echo "'Tag_Bam' directory has been found."
				# go to 'Tag_Bam' directory
				cd "$Tag_BAM_1"

				# Create a directory for the results if it do not yet exist
				countRep="$Tag_BAM_1"/CountResults
				FRIP_REP="$Tag_BAM_1"/FRIP_Results
				DUPLICATES_REP="$Tag_BAM_1"/Duplicates_Results
				DUPLICATES_FRIP="$Tag_BAM_1"/Duplicates_FRIP
				if [ ! -d "$countRep" ]; then
					mkdir $countRep	
				fi

				if [ ! -d "$FRIP_REP" ]; then
					mkdir $FRIP_REP
				fi

				if [ ! -d "$DUPLICATES_REP" ]; then
					mkdir $DUPLICATES_REP
				fi

				if [ ! -d "$DUPLICATES_FRIP" ]; then
					mkdir $DUPLICATES_FRIP
				fi

				echo "Calculate the number of NS and YS for each bam files."
				
				FILES="$Tag_BAM_1"/*
				cpt=1
				NSnameFile=nsCount
				YSnameFile=ysCount
				NSfinal=nsFile
				YSfinal=ysFile

				for bamFiles in $FILES;
				do
					# Iterate on the files presents on the 'Tag_BAM' directory
					if [ -f "$bamFiles" ];then
						# Name of the files in the directory 'Tag_BAM' automatically obtained
						nameCutBamFiles=${bamFiles:$lengthBamPath}

						echo "Processing on the file : $nameCutBamFiles ..."

						# Rename the columns of the bam files
						
						if [[ $nameCutBamFiles == *"allreads"* ]]; then # bamfile contain 'allreads'
							# name file : 'NOXS_XS_peaks_allreads_marked-dups_PhoPolII_TiGR_input_10-12_LIB19493_RBA18776_1_bowtie2.bam'
							if [[ $nameCutBamFiles == *"input"* ]]; then 
								id=$(echo $nameCutBamFiles | cut -d '_' -f 9) # obtain '10-12'

								nameCutBamFiles="allreads_input_$id" # 'allreads_input_10-12'
							# name file : 'NOXS_XS_peaks_allreads_marked-dups_PhoPolII_TiGR_p1_55_18-1_LIB19488_RBA18771_1_bowtie2.bam '
							else 
								p=$(echo $nameCutBamFiles | cut -d '_' -f 8)
								id=$(echo $nameCutBamFiles | cut -d '_' -f 9)
								tab="_"
								nameCutBamFiles="allreads_$p$tab$id" # 'allreads_p1_55'
							fi
						else # bamfile contain 'PhoPolII_TiGR'
							if [[ $nameCutBamFiles == *"input"* ]]; then 
								id=$(echo $nameCutBamFiles | cut -d '_' -f 7) # obtain '10-12'
								nameCutBamFiles="XS-filt-input_$id" # 'XS-filt_input_10-12'
							else
								p=$(echo $nameCutBamFiles | cut -d '_' -f 6)
								id=$(echo $nameCutBamFiles | cut -d '_' -f 7)
								tab="_"

								nameCutBamFiles="XS-filt_$p$tab$id" # 'XS-filt_p1_55'
							fi
						fi

						nsCutFile="NS_$nameCutBamFiles"
						ysCutFile="YS_$nameCutBamFiles"

						#echo "!!! BAM Header name ---> '$nsCutFile' AND '$ysCutFile'"

						### HEADER: write the HEADER of the BAM files
						# -Normal-  Header for NS 
						echo -ne $nsCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt
						# -Normal- FRIP for the NS 
						echo -ne FRIP_$nsCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt

						### -DUPLICATES-  Header for NS Duplicates
						echo -ne Duplicates_$nsCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt
						# -DUPLICATES- FRIP for the NS 
						echo -ne Duplicates_FRIP_$nsCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt
						#############################

						# -Normal- Header for YS 
						echo -ne $ysCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt
						# -Normal- FRIP for the YS
						echo -ne FRIP_$ysCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt

						### -DUPLICATES- Header for YS Duplicates
						echo -ne Duplicates_$ysCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt
						# -DUPLICATES- FRIP for the YS
						echo -ne Duplicates_FRIP_$ysCutFile "\t" >> ../OUTPUT_$NAMEDIR_EXP_CUT.txt
						#############################

						# Check if samtools is installed
						if ! type "samtools" ;then
							echo "Please, install samtools..."
						else
							# BAM Files processing 
							nsCount=$(samtools view $bamFiles | grep 'NS:Z:MACS' | wc -l)
							ysCount=$(samtools view $bamFiles | grep 'YS:Z:MACS' | wc -l)

							######### Manage the Duplicates also
							# Counts duplicates for the other FRIP
							nsDuplicate=$(samtools view -f 1024 $bamFiles | grep 'NS:Z:MACS' | wc -l)
							ysDuplicate=$(samtools view -f 1024 $bamFiles | grep 'YS:Z:MACS' | wc -l)

							# To calculate the FRIP 
							TOTAL_READS=$(samtools view -c $bamFiles)
						fi
						
						# Calcul the Global FRIP
						nsFRIP=$(echo "scale=5; $nsCount/$TOTAL_READS*100" | bc)
						ysFRIP=$(echo "scale=5; $ysCount/$TOTAL_READS*100" | bc)


						# Difference between all and duplicates
						nsDiff=$(echo "scale=4; $nsCount-$nsDuplicate" | bc)
						ysDiff=$(echo "scale=4; $ysCount-$ysDuplicate" | bc)

						# Calcul the FRIP without duplicates
						nsFRIP_DUP=$(echo "scale=4; $nsDiff/$TOTAL_READS*100" | bc)
						ysFRIP_DUP=$(echo "scale=4; $ysDiff/$TOTAL_READS*100" | bc)

						###############################################################
						### To see the results on the terminal: uncomment until the line 360

						#echo "-----------------------------------------------"
						#echo "NsCOUNT ---> $nsCount"
						#echo "NsDuplicate ---> $nsDuplicate"
						#echo "Diff_NS = $nsDiff"
						#echo "Percentage NORMAL = $nsFRIP"
						#echo "Percentage DUPLICATE = $nsFRIP_DUP"

						#echo "-----------------------------------------------"
						#echo "YsCOUNT ---> $ysCount"
						#echo "YsDuplicate ---> $ysDuplicate"
						#echo "Diff_YS = $ysDiff"
						#echo "Percentage NORMAL = $ysFRIP"
						#echo "Percentage DUPLICATE = $ysFRIP_DUP"
						#################################################################
						
						# Put the results of the processing on the 'CountResults' directory
						# Number of NS 
						echo $nsCount > CountResults/$NSfinal$cpt
						# Number of YS 
						echo $ysCount > CountResults/$YSfinal$cpt

						# Put the results of the FRIP in the 'FRIP_Results' directory
						echo $nsFRIP > FRIP_Results/nsFRIP_$cpt
						# Number of YS 
						echo $ysFRIP > FRIP_Results/ysFRIP_$cpt

						### DUPLICATES 
						#Add NS duplicates results in the 'Duplicates_Results' repository
						echo $nsDuplicate > Duplicates_Results/$NSfinal$cpt
						# Number of YS 
						echo $ysDuplicate > Duplicates_Results/$YSfinal$cpt

						# Put the results of the FRIP in the 'FRIP_Results' directory
						echo $nsFRIP_DUP > Duplicates_FRIP/nsFRIP_$cpt
						# Number of YS 
						echo $ysFRIP_DUP > Duplicates_FRIP/ysFRIP_$cpt

						cpt=$(($cpt + 1))
					fi	
				done
			else
				echo "'Tag_Bam' directory is not found."
			fi

			# Return to the global directory of the experiment: at first, 'p1_55_vs_input_10-12'
			cd "$EXP_1"

			# GO to the line on the final report after the HEADER
			echo -e >> OUTPUT_$NAMEDIR_EXP_CUT.txt
			# JUMP a line
			echo -e >> OUTPUT_$NAMEDIR_EXP_CUT.txt

			# Create the final report here
			paste "$flagStat_1"/FlagResults/allreads_input* "$flagStat_1"/FlagResults/allreads_p* "$flagStat_1"/FlagResults/XS-filt-input* "$flagStat_1"/FlagResults/XS-filt_p* "$Peaks_dir"/CountResults/NOXS "$Peaks_dir"/CountResults/XS_s "$Tag_BAM_1"/CountResults/nsFile1 "$Tag_BAM_1"/FRIP_Results/nsFRIP_1 "$Tag_BAM_1"/Duplicates_Results/nsFile1 "$Tag_BAM_1"/Duplicates_FRIP/nsFRIP_1 "$Tag_BAM_1"/CountResults/ysFile1 "$Tag_BAM_1"/FRIP_Results/ysFRIP_1 "$Tag_BAM_1"/Duplicates_Results/ysFile1 "$Tag_BAM_1"/Duplicates_FRIP/ysFRIP_1 "$Tag_BAM_1"/CountResults/nsFile2 "$Tag_BAM_1"/FRIP_Results/nsFRIP_2 "$Tag_BAM_1"/Duplicates_Results/nsFile2 "$Tag_BAM_1"/Duplicates_FRIP/nsFRIP_2 "$Tag_BAM_1"/CountResults/ysFile2 "$Tag_BAM_1"/FRIP_Results/ysFRIP_2 "$Tag_BAM_1"/Duplicates_Results/ysFile2 "$Tag_BAM_1"/Duplicates_FRIP/ysFRIP_2 "$Tag_BAM_1"/CountResults/nsFile3 "$Tag_BAM_1"/FRIP_Results/nsFRIP_3 "$Tag_BAM_1"/Duplicates_Results/nsFile3 "$Tag_BAM_1"/Duplicates_FRIP/nsFRIP_3 "$Tag_BAM_1"/CountResults/ysFile3 "$Tag_BAM_1"/FRIP_Results/ysFRIP_3 "$Tag_BAM_1"/Duplicates_Results/ysFile3 "$Tag_BAM_1"/Duplicates_FRIP/ysFRIP_3 "$Tag_BAM_1"/CountResults/nsFile4 "$Tag_BAM_1"/FRIP_Results/nsFRIP_4 "$Tag_BAM_1"/Duplicates_Results/nsFile4 "$Tag_BAM_1"/Duplicates_FRIP/nsFRIP_4 "$Tag_BAM_1"/CountResults/ysFile4 "$Tag_BAM_1"/FRIP_Results/ysFRIP_4 "$Tag_BAM_1"/Duplicates_Results/ysFile4 "$Tag_BAM_1"/Duplicates_FRIP/ysFRIP_4 >> OUTPUT_$NAMEDIR_EXP_CUT.txt

			echo "---> OUTPUT_$NAMEDIR_EXP_CUT.txt Report created !"
			echo ""
	
		else
			echo "$EXP_1 has not been found, make sure you have this directory or rename it."
		fi
	done
	echo "I hope the coffee was good."

else 
	echo "Please place this script in the same folder as the 'galaxy' repository."
	#echo "Please, pass as an argument the correct path directory."
	#echo "For example : /g/furlong/santamaria/galaxy"
fi

echo "Processing finished."

exit 0;