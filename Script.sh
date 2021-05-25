#!/bin/bash
#############
# Variables #
#############
# Github to use as base
GITHUB_URL=https://github.com/bntjah/pfsense-aliases
# Github UK Cached Domains
GITHUB_UKL=https://github.com/uklans/cache-domains
# Folder where I will clone Github repo to and do my work 
WORK_FOLDER=/home/bntjah/pfsense-aliases
# Temp folder to store things
TMP_FOLDER=/tmp

# Cleanup Work Folder if it exists already
if [ -d '${WORK_FOLDER}' ]; then
	rm -rf '${WORK_FOLDER}'
fi

# Clone Repo to work Folder if it doesn't exist yet
if [ ! -d '${WORK_FOLDER}' ]; then
	git clone  ${GITHUB_URL} ${WORK_FOLDER}
fi

# Clone UKLans Cache Domains to TMP
if [ ! -d '${TMP_FOLDER}/UKLANS' ]; then
	git clone  ${GITHUB_URL} ${TMP_FOLDER}/UKLANS
	if [ -d '${WORK_FOLDER}' ]; then
		mv ${TMP_FOLDER}/UKLANS/*.txt ${WORK_FOLDER}/dns-raw/
		if [ -f '${WORK_FOLDER}/blizzard.txt' ]; then
			rm -rf ${TMP_FOLDER}/UKLANS/
		fi
	fi
fi

for f in ${WORK_FOLDER}/dns-raw/*; do
	UPSTREAM_CONFIG_FILE="/home/gvw/pfsense-aliases/dns-resolved/${f##*/}.txt"
	TMP_UPSTREAM_FILE="${TMP_FOLDER}/${f##*/}.txt"

	# Read the upstream file line by line
	while read -r LINE;
	do
		# Skip line if it is a comment
		if [[ ${LINE:0:1} == '#' ]]; then
			continue
		fi

		# Check if hostname is a wildcard
        if [[ $LINE == *"*"* ]]; then
			# Remove the asterix and the dot from the start of the hostname
			LINE=${LINE/#\*./}
		fi

		# Add a standard A record config line
		dig ${LINE} +short >> ${TMP_UPSTREAM_FILE}

	done < ${WORK_FOLDER}/dns-raw/${f##*/}

		# Parse through TMP File for eleminating Cname records
		cat ${TMP_UPSTREAM_FILE} | grep -v '\.$' | sort | uniq -u > ${UPSTREAM_CONFIG_FILE}

		if [ -f '${UPSTREAM_CONFIG_FILE}' ]; then
			rm -rf ${TMP_UPSTREAM_FILE}
		fi
done
