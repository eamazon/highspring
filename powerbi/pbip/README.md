# Power BI PBIP Workflow

Use this folder as the source-controlled location for your Power BI Project files.

Recommended save location from Power BI Desktop:
- `H:\powerbi\pbip\High_Spring\`

Notes:
- `H:` should be mapped to `\\wsl$\Ubuntu\home\speddi\dev\icb\highspring`.
- Keep your large local working file (`High_Spring.pbix`) on Desktop as needed.
- Save/maintain the `.pbip` project in this folder for Git tracking.
- `.pbix` is ignored by Git in this repo.
- Local PBIP cache folders (`.pbi`, `.pbiworkspace`) are ignored by Git.

Daily workflow:
1. Open the `.pbip` project from `H:\powerbi\pbip\High_Spring\`.
2. Make UI/model changes in Desktop.
3. Save.
4. Commit changed files from this repo (WSL or Windows Git, not both at once).
