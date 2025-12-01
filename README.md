# CleanWSLDrives.ps1 — Compact WSL ext4.vhdx files

This PowerShell script compacts WSL (Windows Subsystem for Linux) ext4.vhdx virtual disk files to free physical disk space.

⚠️ Important: Before running the script you should first clean up Docker artifacts (containers, images, volumes, networks) because the WSL virtual disk can contain Docker data and unused Docker artifacts will prevent reclaiming space effectively.

---

## Quick summary

- Script: `CleanWSLDrives.ps1`
- Purpose: Shut down WSL and run DiskPart `compact vdisk` on any `ext4.vhdx` files found under `%LOCALAPPDATA%\Packages` to reduce their on-disk size.
- Requires: Administrator PowerShell, WSL installed (with at least one distro using an `ext4.vhdx`).

---

## Before you run — clean Docker first (recommended)

If your WSL disks hold Docker images, containers and volumes, reclaiming space requires removing unused Docker objects before compacting. The following commands are destructive: they permanently remove stopped containers, unused images, volumes, and networks.

Use these intentionally and only after making backups of any important images or volumes.

Recommended checks and cleanup steps:

1. Inspect disk usage:

```powershell
docker system df
docker ps -a
docker images
docker volume ls
```

2. Stop containers you don't need:

```powershell
docker stop <container-id-or-name>
```

3. Remove stopped containers:

```powershell
docker container prune    # prompts for confirmation
```

4. Remove dangling and unused images:

```powershell
docker image prune -a     # removes images not referenced by any container
```

5. Remove unused volumes (DANGEROUS — this may delete persistent data):

```powershell
docker volume prune       # prompts for confirmation
# Or to remove everything:
docker system prune -a --volumes
```

6. Remove unused networks (optional):

```powershell
docker network prune
```

7. For docker-compose projects you may need to remove named volumes on `down`:

```powershell
docker-compose down -v
```

Danger / Notes:

- `docker system prune -a --volumes` will remove unused containers, networks, images (both dangling and unreferenced), and volumes. This will delete persistent data stored in volumes — backup first.
- If you depend on images that aren't pushed to a registry, consider saving them with `docker save` or `docker tag` + `docker push` before removing.
- If a running container is using a volume with valuable data, back it up first (copy files or use `docker cp`).

---

## How to run `CleanWSLDrives.ps1`

1. Open PowerShell as **Administrator** (Right-click → Run as Administrator).

2. (Optional) If you need to allow execution temporarily (the script itself uses a process-scoped bypass), you can run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# or for a single session (script already sets bypass):
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

3. Recommended: Do the Docker cleanup steps above first.

4. Change to the repository folder (where the script is located) and run the script:

```powershell
cd C:\Users\<your-user>\Projects
.\CleanWSLDrives.ps1
```

The script will:

- Ensure it runs elevated (Admin). If not elevated it exits with an error.
- Shut down WSL (`wsl --shutdown`) so disk files are safe to compact.
- Locate `ext4.vhdx` files under `$env:LOCALAPPDATA\Packages` and run a DiskPart compact command for each.

Example output (trimmed):

```
Compacting: C:\Users\Renn\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu_79rhkp1fndgsc\LocalState\ext4.vhdx
  Size before: 200 GB
  Size after :  11 GB
  Freed      :  189 GB

✅ All WSL disks processed.
```

---

## Why this works / background

WSL stores Linux distributions as VHDX files. Over time these virtual disks grow and do not automatically shrink even when files are deleted inside the WSL instance. Disk compaction reclaims unused blocks inside the VHDX file, reducing the host's allocated disk size.

Cleaning Docker artifacts helps because Docker images/containers/volumes stored in WSL can occupy significant space. Removing them first enables `compact vdisk` to free more space.

---

## Troubleshooting

- Permission/Administrator error: Make sure PowerShell was started as Administrator. The script checks for elevation and will exit with an informative error if not running elevated.

- No `ext4.vhdx` files found: If you see no files, you might not have WSL distros installed or your distro stores data in a different location. Check `wsl --list --verbose` and inspect `\wsl$` or your `%LOCALAPPDATA%\Packages` folder.

- DiskPart failed / compact did not shrink file: Disk compaction can only reclaim unused space. If the VHDX file is sparse or still holds data, compacting may not change size noticeably. Ensure:
  - WSL is shut down (`wsl --shutdown`) before compaction.
  - You cleaned Docker and removed files within your Linux distros that you no longer need.
  - Try compacting again after ensuring there is free space inside the distro.

- PowerShell Execution Policy refuses to run the script: The script sets a process-level bypass so it should run regardless, but if your corporate policy or antivirus blocks that, temporary change your execution policy or run the script from an elevated session.

- Antivirus or security blocking DiskPart / VHDX access: Some security products may block `diskpart` or virtual disk manipulation. Consult your security administrator or temporarily disable the blocking rule.

---

## Safety & backup recommendations

- Backup important WSL data before making sweeping changes. You can export WSL distributions:

```powershell
wsl --export <distroName> C:\path\to\backups\distro.tar
```

- Backup Docker volumes and images you need (use `docker save`, `docker push`, `docker cp` for data in containers, or copy raw volume data) before pruning.

---

## Example safe workflow

1. Backup critical WSL distro(s): `wsl --export`.
2. Export or push important Docker images, and backup volumes if required.
3. Stop or remove unnecessary containers and images using the Docker commands in the Docker cleanup section.
4. Confirm Docker disk usage dropped (`docker system df`).
5. Run `.\CleanWSLDrives.ps1` from Admin PowerShell.

---

## FAQ

- Q: Do I need to uninstall Docker or WSL to shrink the files?  
  A: No. Stopping WSL and cleaning up data inside the distro(s) is sufficient in most cases.

- Q: Will this break my WSL distributions?  
  A: No — compacting only reduces allocated space in the virtual disk. It does not change the filesystem content.

- Q: How often should I run this?  
  A: When your Windows drive gets tight or after large cleanup operations inside WSL (e.g., removing lots of images/files), run compact to reclaim unused space.

---

## Contact / support

If you run into issues not covered here, open an issue explaining:

- Exact command you ran
- Full output or error messages
- The content of your WSL disk sizes (`Get-ChildItem -Recurse -Filter ext4.vhdx`), and the results of `docker system df` if relevant

---

This README was generated to pair with `CleanWSLDrives.ps1` located at the repository root. Use carefully and back up important data before destructive Docker or disk operations.
