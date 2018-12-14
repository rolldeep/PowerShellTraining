<#
Example 1

 
User wants to check whether a particular job has failed and retry it in case it does.
 
You need to write a script that will:
 

1. Check and output the latest job status along with job name
  1. Retry the job in case the latest job status is Failed

#>

#Script:


Get-VBRjob
$job = Get-VBRjob -name "Backup Job Failed"
Start-VBRjob -job $job -retrybackup -runasync

<#
Assign the variable $job to the Failed job, just for convince. 
Retry failed job (won’t work unless the status of the job is on “Failed” state)
#>



<#
Example 2

User has enabled Windows deduplication on machine that hosts backup repository role. Now he wants to optimize job settings to achieve the best deduplication ratio.
 
You need to write a script that will:
 

1. Find jobs that are pointed to specific repository
2. Disable inline data deduplication on all of them
3. Set compression level to dedupe-friendly on all of them
#>


#Script:
#1.

$repository =  Get-VBRbackupRepository -Name "Backup Repository 1"
$backups = $repository.getBackups()

#2,3.
foreach ($backup in $backups) {
    get-vbrjob -name $backup.Name | Set-VBRJobAdvancedStorageOptions -EnableDeduplication $False -CompressionLevel 4
}


<#
Example 3

 
User has found that particular backup repository experienced a storage corruption. Now he wants to identify what backup or backup copy jobs are pointed to the problematic repository, clone them and re-point to different backup repository.
 
You need to write a script that:
 

1. Check whether there are backup jobs pointed to specific repository
  1. If there are jobs pointed to specific repository, clone them and change the repository (they are pointed to) to the new one, while cloning


#>
 
#Script:

$repository =  Get-VBRbackupRepository -Name "Backup Repository 1"
$backups = $repository.getBackups()
foreach ($backup in $backups) {
Copy-VBRJob -Job $backup.Name -Repository "Backup Repository 2"
}



<#
Example 4

 
User wants to check whether particular backup job falls out of the desired RPO and execute it in case it does.
 
You need to write a script that will:
 

1. Check and output last run time of particular backup job
2. Check whether the last run time is located within the defined RPO (might be either a constant or defined by user during script execution - console prompt):
  1. If so, output message “Job $Jobname is located within the defined RPO”
  2. Otherwise (job located outside of the defined RPO), run the job
#>

#Script:
#1.

#Last run time
$job = Get-VBRbackup -Name "Backup Job 1"
$points = Get-VBRbackup -Name "Backup Job 1" | get-VBRRestorePoint -Name * | sort CreationTime -Descending
$point  = $points[0].CreationTime

#2.

$rpoHours = read-host -Prompt "Enter RPO in hours"
$rpotime = get-time
if ($point -lt $rpotime.addhours(rpoHours)) {
    write-host 'Job located outside of the defined RPO'
}
else {
    write-host 'Job ' $job.name ' is located within the defined RPO'
}

<#
Example 5

User worries that his backups might be stolen, so he wants to put additional security measures to protect sensitive information. He decides to enable encryption on all existing jobs and run new active full backup to propagate new settings.
 
You need to write a script that will:
 

1. Add new encryption key
2. Enable file encryption on all existing jobs, setting the newly added encryption key as backup file encryption password
3. Run new active full backup on all existing jobs
#>

#Script:
#1.

$securepassword = Read-Host -Prompt "Enter password" -AsSecureString
Add-VBREncryptionKey -Password $securepassword -Description "Veeam Administrator"

 #2.

$jobs = Get-VBRJobs
$key = Get-EncryptionKey -Description "Veeam Administrator"
foreach ($job in $jobs) {
Get-VBRJob -Name $job.name | Set-VBRJobAdvancedStorageOptions -EnableEncryption $True -EncryptionKey $key
Start-VBRJob -Job $job -FullBackup
}


<#
Example 6

 
User has a list of mission critical VMs that are replicated to target host. For those VMs he wants to create a failover plan so that in case of disaster he won’t need to execute them one by one. Also, VMs need to be executed in certain order and with certain boot delay:
 
You need to write a script that will:
 

1. Check list of mission critical VMs (list might be either constants or defined by user during script execution - console prompt)
2. Create a failover plan for those VMs:
3. boot order: whatever you like
4. BootDelay: 10 seconds for first VM, 20 seconds for second VM, etc.
#>

 
#Script:
#1,2.

$VM1 = Find-VBRViEntity -Name "VM1" | New-VBRFailoverPlanObject -BootDelay 0
$VM2 = Find-VBRViEntity -Name "VM2" | New-VBRFailoverPlanObject -BootOrder 1          -BootDelay 10
$VM3 = Find-VBRViEntity -Name "VM2" | New-VBRFailoverPlanObject -BootOrder 2$          -BootDelay 20
Add-VBRFailoverPlan -Name "Fail" -FailoverPlanObject $VM1, $VM2, $VM3                  -Description "Just in case"

<#
Example 7

 
User has a VM named SQL. He wants to add the VM to existing backup job and enable certain application-aware image processing settings for it.
 
You need to create a dummy VM named SQL (or rename existing one) beforehand and then write a script that will:
 

1. Find a VM named SQL
2. Add it to existing backup job
3. Enable application-aware image processing for this job
4. Specify the following application-aware image processing settings for VM named SQL:
  1. Applications: Try application processing, but ignore failures
  2. Transaction logs: Process transaction logs with this job
  3. SQL: Truncate logs

#>

#Script:
#1,2,3.

$job = Get-VBRJob -name "Backup Job 1"
Find-VBRViEntity -Name "SQL" | Add-VBRViJobObject -Job $job
Get-VBRJob -name "Backup Job 1" | Enable-VBRJobVSSIntegration

#4.

$sql = Get-VBRJobObject -Job $job -Name "SQL"
$o = Get-VBRJobObjectVSSOptions -ObjectInJob $sql
#a
$o.VSSSnapshotOptions.IgnoreErrors = $true
#b
$o.VSSSnapshotOptions.IsCopyOnly = $false
#C
$o.SQLBackupOptions.TransactionLogsProcessing = "Truncate"
Set-VBRJobObjectVSSOptions -Object $sql -Options $o
