# PS-SinglePartitionMaker.ps1
PS-SinglePartitionMaker.ps1 is an interactive PowerShell script that securely wipes a selected disk, removes all partitions (including OEM), and creates a single NTFS partition with a custom label. It automatically adapts its prompts and messages to the system language (French or English).

## Usage
Run PS-SinglePartitionMaker.ps1 as Administrator.

## Main features:
- Automatic language detection – Displays prompts in French or English based on system locale.
- Disk listing – Shows all available disks with their details.
- Disk selection & validation – Ensures the chosen disk exists before proceeding.
- Partition overview – Displays current partitions on the selected disk.
- Double confirmation safety – Requires two explicit confirmations before erasing data.
- Custom volume label – Lets the user name the new partition.
- Full disk wipe – Removes all data and OEM partitions.
- GPT initialization – Sets the disk to GPT partition style.
- Single partition creation – Uses the full disk space and assigns a drive letter.
- NTFS formatting – Formats the partition with the chosen label.
- Clear status messages – Color-coded feedback for each step.


## License
[MIT](https://choosealicense.com/licenses/mit/)
