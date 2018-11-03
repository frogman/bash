#!/bin/bash
#####################################################################
#Purpose:  Gather all permissions on server and store in a file for
#emergencies
#####################################################################
 
# Input only the first directory to ignore
# this is needed for the first path statement in the find command
first_dir_to_ignore="/sys"
 
# Input remaining directories to ignore
dirs_to_ignore="/nets /proc /dev"
 
# Custom formatted date command
date_format=$(date '+%Y.%m.%d.%H%M%S')
 
# Input output file and directory
perm_backup_file="/$(hostname).owner.perm.backup.sh"
 
# Stores directories to exclude in an array
counter=0
for tmp0 in ${dirs_to_ignore}; do
        dirs_to_ignore_array[${counter}]=" -o -path ${tmp0} "
        let counter=counter+1
done
 
# Executes find command ignoring all directories above and store them in a file
# specified in the variable perm_backup_file.
echo "#!/bin/bash" > ${perm_backup_file}-${date_format}
echo "##############################################" >> ${perm_backup_file}-${date_format}
echo "# Hostname:  $(hostname)" >> ${perm_backup_file}-${date_format}
echo "# File Created: $(date)" >> ${perm_backup_file}-${date_format}
echo "##############################################" >> ${perm_backup_file}-${date_format}
find / \( -path ${first_dir_to_ignore} ${dirs_to_ignore_array[@]} \) -prune -type f -name "*" -o -print0 | while IFS= read -r -d '' file; do
        stat -c "chmod %a \"%n\"" "${file}" >> ${perm_backup_file}-${date_format}
        stat -c "chown %U:%G \"%n\"" "${file}" >> ${perm_backup_file}-${date_format}
done
