# Init

> Set up a new wiki vault with the required folder structure and conventions.

## Prerequisites

- Obsidian must be running
- A vault named `wiki` must exist (create in Obsidian first: File → Open vault → Create new vault → name it `wiki`)

## Steps

### Step 1: Verify Vault

Confirm the `wiki` vault exists and is accessible:

```bash
obsidian vault vault=wiki
```

If this fails, the vault doesn't exist yet — direct the user to create it in Obsidian.

### Step 2: Check Existing Structure

```bash
obsidian vault=wiki folders
```

If `sources/`, `projects/`, `topics/`, or `notes/` already exist, warn the user and ask whether to skip existing folders or proceed.

### Step 3: Create Folder Structure

Create a placeholder file in each directory (Obsidian creates folders implicitly when files are created in them):

```bash
obsidian vault=wiki create path="sources/.gitkeep" content=""
obsidian vault=wiki create path="projects/.gitkeep" content=""
obsidian vault=wiki create path="topics/.gitkeep" content=""
obsidian vault=wiki create path="notes/.gitkeep" content=""
```

### Step 4: Create Welcome Page

Create a landing page at the vault root:

```bash
obsidian vault=wiki create path="Welcome.md" content="..."
```

Content should include:
- Brief explanation of the wiki structure
- Links to each folder: `[[sources]]`, `[[projects]]`, `[[topics]]`, `[[notes]]`
- Quick reference for citation format

### Step 5: Confirm

Report what was created. Suggest the user open the vault in Obsidian to verify.

## Success Criteria

- All four directories exist: `sources/`, `projects/`, `topics/`, `notes/`
- Welcome page created with links to each section
- Vault accessible via `obsidian vault vault=wiki`
