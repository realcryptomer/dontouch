
# DONTOUCH - Protect Your Files from Unwanted Cursor AI Edits

**Stop worrying about Cursor AI accidentally modifying your critical files, or editing files that it need not touch.** 

DONTOUCH uses Cursor Hooks to **inform you and let you revert any edit in a 'locked' file**. A file is locked by putting a comment line with the word `DONTOUCH` in the first 2 lines of the file.

## Quick Start

### 1. Install

**⚠️ IMPORTANT:** Clone to a permanent location (e.g., `~/tools/dontouch`). The hooks execute scripts from this folder!

**macOS:**
```bash
git clone https://github.com/YOUR_USERNAME/dontouch.git ~/tools/dontouch
cd ~/tools/dontouch
./mac/install_mac.sh
```

**Linux:**
```bash
git clone https://github.com/YOUR_USERNAME/dontouch.git ~/tools/dontouch
cd ~/tools/dontouch
./linux/install_linux.sh
```

**Windows:**
```cmd
git clone https://github.com/YOUR_USERNAME/dontouch.git C:\tools\dontouch
cd C:\tools\dontouch
windows\install_windows.bat
```

Then **restart Cursor**.

### 2. Lock Specific Files

Add `DONTOUCH` as a comment in the **first or second line** of any file you want to lock from Cursor AI edits:

```python
# DONTOUCH - Critical configuration
api_key = "secret123"
```

```javascript
// DONTOUCH - Don't let AI modify this
const config = { ... }
```

```bash
#!/bin/bash
# DONTOUCH - Important build script
./build.sh
```

```css
/* DONTOUCH - Carefully crafted styles */
.important { ... }
```

That's it! Your file is now locked.

## How It Works

**DONTOUCH uses Cursor Hooks** - a powerful feature that lets scripts run automatically when Cursor AI reads or edits files. No manual intervention needed!

### Automatic Protection Flow

1. **Cursor AI reads your locked file** → Cursor Hook automatically creates a backup in `.dontouch/` folder
2. **Cursor AI edits your locked file** → Cursor Hook automatically shows you a popup:

```
Cursor just changed a DONTOUCH file:

config.json

Revert changes?
```

- Click **Yes** → File reverts to the backup (Cursor AI changes undone)
- Click **No** → Changes are kept and backup updates to the new version

**All of this happens automatically** - the moment Cursor AI touches a DONTOUCH file, you're protected!

### What Gets Protected

Any file with `DONTOUCH` in the **first or second line** (case insensitive):
- ✅ `# DONTOUCH` 
- ✅ `// dontouch`
- ✅ `/* DONTOUCH */`
- ✅ `<!-- DONTOUCH -->`
- ✅ Works with shebang lines (`#!/bin/bash` on line 1, `# DONTOUCH` on line 2)
- ✅ Works in any programming language!

**Common typos are supported:**
- ✅ `DONTTOUCH` (double T)
- ✅ `DON'TOUCH` (with apostrophe)
- ✅ `DON'TTOUCH` (apostrophe + double T)

### Backup Management

**Automatic:**
- Backups stored in `.dontouch/` folder in your project root
- Cleanup runs automatically once per day (in background)
- Removes orphaned backups (for deleted files) older than 1 week
- Active file backups are never automatically deleted

**Manual cleanup:**
```bash
./mac/cleanup-backups.sh
```

**Important:** Add `.dontouch/` to your project's `.gitignore` to keep backups local:
```bash
echo ".dontouch/" >> .gitignore
```

---

**MIT License** • Made with ❤️ for developers who want to code with Cursor AI confidence.
