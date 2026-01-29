# Mapping WSL Folder to `H:` Drive on Windows 11  
### (Using `\\wsl.localhost` + `mklink` + `subst`)

Windows 11 blocks traditional drive‑mapping methods (`net use`, `subst` → UNC, Explorer mapping) for WSL paths such as `\\wsl$`.  
However, it **still supports** the modern WSL2 filesystem endpoint:

```
\\wsl.localhost\<DistroName>\
```

Using this endpoint, you can recreate a stable `H:` drive that points into your WSL project.

---

## 1. Create a Windows symlink to your WSL folder

Open **Command Prompt (CMD)** as Administrator and run:

```
mklink /D C:\WSLLink \\wsl.localhost\Ubuntu\home\speddi\dev\icb\highspring
```

This creates a directory symlink at:

```
C:\WSLLink
```

which transparently points into your WSL filesystem.

---

## 2. Map the symlink to drive `H:`

Still in CMD:

```
subst H: C:\WSLLink
```

This gives you a fully functional drive letter:

```
H:\
```

pointing to your WSL project directory.

---

## 3. Verifying the mapping

Run:

```
H:
dir
```

You should see your project files exactly as they appear inside WSL.

---

## 4. Notes

- This method works because `subst` maps a **local folder**, and the folder is a symlink to `\\wsl.localhost`, which Windows 11 still allows.
- Do **not** use `\\wsl$` — it cannot be mapped anymore.
- If WSL restarts, the symlink remains valid.
- If the `H:` mapping disappears after reboot, re‑run:

  ```
  subst H: C:\WSLLink
  ```

  (You can also add this to a startup script if needed.)

---

