# Installing ZirClock

This is the detailed version of the installation instructions, including what
to do when something does not go as expected. Jump to your system:

- [**Windows**](#windows) — short version: *download the installer, click
  through the SmartScreen warning, and follow the wizard*.
- [**macOS**](#macos) — short version: *download the `.dmg`, drag ZirClock to
  Applications, and the first time you open it approve it in System Settings →
  Privacy & Security*.

> **Coming from Chronikon or Zirchron?** ZirClock is the same program under a
> new name (Chronikon was 2.0–2.3, Zirchron 1.x). Your project files keep
> opening: `.chronikon` and `.zirchron` are read for good, and new saves use
> `.zirclock`. Your recent-files list and preferences carry over the first time
> ZirClock starts.

---

# Windows

## 1. Check that your PC is compatible

| Requirement | Value |
|---|---|
| Windows | 10 or 11, **64-bit** |
| Processor | any 64-bit Intel or AMD |
| Disk space | about 350 MB |

To check: **Start → Settings → System → About**. Under *Device
specifications*, the line **System type** must say *64-bit operating system*.
ZirClock does not run on 32-bit Windows, nor on Windows 8.1 or earlier.

There is a single Windows download — unlike macOS, you do not have to pick a
processor.

---

## 2. Download

Go to the [Releases](../../releases) page and download
**`ZirClock-3.1-windows-setup.exe`**. It will land in your **Downloads**
folder.

---

## 3. Install

1. **Double-click the downloaded installer.**

2. **Windows will block it.** A blue full-screen panel appears saying
   *"Windows protected your PC"*, with only a **Don't run** button visible.
   Click **More info** — the text expands and a **Run anyway** button appears.
   Click it. (Section 4 explains why this happens; it is expected.)

3. **Choose the install mode.** The installer asks whether to install *for all
   users* (requires an administrator password) or *for me only* (no password
   needed). Either works — pick *for me only* if you are not an administrator
   of the computer, which is the common case on shared laboratory machines.

4. **Follow the wizard:** pick a language (English or Spanish), accept the
   licence (GNU GPL v3 or later), and confirm the destination folder. You can
   leave every default.

5. On the last page you can tick **Launch ZirClock**. Afterwards you will find
   it in the **Start menu**, and on the desktop if you left the shortcut
   option ticked.

You can delete the installer from Downloads once it finishes.

**Updating from Chronikon or Zirchron:** just run the new installer. It
replaces the old version in place — same Start-menu entry, the old program
folder is emptied — and re-points the `.chronikon` and `.zirchron` file types
to ZirClock.

---

## 4. First launch — the SmartScreen warning

Windows shows *"Windows protected your PC"* for any program that is not signed
with a **code-signing certificate** — a paid commercial service, renewed
yearly. ZirClock is distributed directly by its author, unsigned.

**This is not a detection of anything harmful.** SmartScreen is not saying the
file is dangerous; it is saying it does not recognise the publisher, which is
true of every new unsigned program.

To proceed: **More info** → **Run anyway**. You only need to do this once, for
the installer — the installed application starts normally from then on.

**If your antivirus quarantines the file** instead, that is a related
phenomenon: some scanners flag anything bundled with PyInstaller (the tool that
packages Python applications) because malware authors also use it. Restore the
file from quarantine and add an exception for the ZirClock folder if your
scanner keeps intercepting it. The full source code is in this repository, so
you can also build the program yourself.

---

## 5. Opening project files

ZirClock saves your work as `.zirclock` files. The installer registers the file
type (and the older `.chronikon` and `.zirchron`), so **double-clicking a
project opens it in ZirClock immediately** — no need to open the application
first.

If a project does not open with ZirClock, right-click it → **Open with** →
**Choose another app** → select ZirClock and tick *Always use this app*.

---

## Troubleshooting (Windows)

**I only see "Don't run" — there is no "Run anyway" button.**
The button is hidden until you click **More info** on the left side of the
SmartScreen panel. Click that first and the panel expands.

**"This app can't run on your PC."**
Your Windows is 32-bit. ZirClock is 64-bit only (the scientific libraries it
uses are not published for 32-bit Windows). Check under Settings → System →
About → *System type*.

**The installer finishes but nothing opens.**
Look for ZirClock in the Start menu and open it from there. If it still does
not appear, reinstall and make sure you did not change the destination folder
to a location you lack permission to write to.

**The first launch takes several seconds.**
Normal. On the very first run the application builds an internal font cache.
Later launches are faster.

**Antivirus removed the program after installing.**
Add an exception for the installation folder (by default
`C:\Users\<you>\AppData\Local\Programs\ZirClock`, or
`C:\Program Files\ZirClock` if you installed for all users) and reinstall.

---

## Uninstalling (Windows)

**Settings → Apps → Installed apps → ZirClock → Uninstall.** That removes the
application and its file associations. Your project files are ordinary
documents and are not affected — delete them yourself if you no longer need
them.

---

# macOS

## 1. Check that your Mac is compatible

| Requirement | Apple Silicon | Intel |
|---|---|---|
| macOS | 14 (Sonoma) or later | 13 (Ventura) or later |
| Disk space | about 500 MB | about 500 MB |

To check both at once: click the **** menu in the top-left corner of the
screen → **About This Mac**.

- The **Chip** / **Processor** line tells you which file to download:

| That line says | Your download |
|---|---|
| **Chip:** Apple M1, M2, M3, M4 or M5 | `ZirClock-3.1-arm64.dmg` |
| **Processor:** Intel Core i5 / i7 / i9, or Xeon | `ZirClock-3.1-intel.dmg` |

- The **macOS** line must show at least the version in the first table.

Each file holds the same application, compiled for that processor. You do not
need Rosetta, and picking the wrong one cannot damage anything — macOS just
refuses to open it, and you download the other.

---

## 2. Download

Go to the [Releases](../../releases) page of this repository and download the
file that matches your processor (step 1). It will land in your **Downloads**
folder.

---

## 3. Install

A `.dmg` file is a *disk image*: opening it mounts a temporary virtual disk,
much like plugging in a USB drive. Installing means copying the application out
of it.

1. **Double-click the `.dmg` you downloaded.** A Finder window opens showing
   the **ZirClock** icon and a shortcut to your **Applications** folder.

2. **Drag the ZirClock icon onto the Applications folder** and release. macOS
   copies the application. This is the entire installation — Mac applications
   are self-contained bundles, so there is no setup wizard.

3. **Eject the disk image.** In the Finder sidebar, find *ZirClock 3.1* under
   *Locations* and click the ⏏ symbol next to it. You can then delete the
   `.dmg` from Downloads.

**Updating from Chronikon or Zirchron:** macOS treats the renamed program as a
different application, so the old one stays in Applications and keeps
claiming the old file types. Drag `Chronikon.app` (or `Zirchron.app`) to the
Trash so that double-clicking your projects opens ZirClock.

---

## 4. First launch

Open ZirClock from **Launchpad**, from your **Applications** folder, or with
Spotlight (⌘ Space, then type "ZirClock").

The first time, macOS will **refuse to open it** and show a dialog saying that
it cannot verify the app is free of malware, or that the developer cannot be
identified.

**This is expected and it is not a sign that something is wrong with the file.**
Apple shows this for any application that has not been *notarized* — a paid
service that requires an Apple Developer account. ZirClock is distributed
directly by its author, unnotarized.

To allow it to run:

1. Click **Done** / **Cancel** to dismiss the warning.
2. Open the  menu → **System Settings**.
3. Go to **Privacy & Security** in the sidebar.
4. Scroll down to the **Security** section. You will see a message:
   *"ZirClock" was blocked to protect your Mac.*
5. Click **Open Anyway**.
6. Authenticate with your password or Touch ID if asked, then click **Open**
   in the confirmation dialog.

**You only need to do this once.** From then on, ZirClock opens like any other
application, and you can right-click its Dock icon → *Options* → *Keep in Dock*.

---

## 5. Opening project files

ZirClock saves your work as `.zirclock` files. After you have opened the
application at least once, macOS learns the association and **double-clicking a
project opens it directly in ZirClock** — `.chronikon` and `.zirchron` files
too.

If a project does not open with ZirClock, right-click it → **Open With** →
*ZirClock*. To make it permanent, right-click → **Get Info** → under
*Open with:* choose ZirClock → **Change All…**

---

## Troubleshooting (macOS)

**"The application is damaged and can't be opened."**
This usually means the download was incomplete or the file was altered in
transit. Delete it and download the `.dmg` again from the Releases page. If it
persists, the quarantine attribute can be cleared by opening **Terminal** and
running:

```
xattr -cr /Applications/ZirClock.app
```

**The app bounces in the Dock and quits, or macOS says the application "cannot
be opened on this Mac".**
Almost always this means you downloaded the file built for the *other*
processor. Go back to step 1, check the **Chip** / **Processor** line, and
download the matching `.dmg`.

**macOS says ZirClock requires a newer macOS.**
Exactly what it says: your system is too old for this build (see the table in
step 1). Updating macOS is the only route.

**The first launch takes several seconds.**
Normal. On the very first run the app builds an internal font cache and macOS
performs a one-time security scan of the bundle. Later launches are faster.

**I do not see "Open Anyway" in Privacy & Security.**
The entry only appears shortly after a blocked launch attempt. Try opening
ZirClock once more, then go straight back to System Settings → Privacy &
Security.

---

## Uninstalling (macOS)

Drag `ZirClock.app` from your Applications folder to the Trash. That removes
the application. Your project files are ordinary documents and are not
affected — delete them yourself if you no longer need them.

---

---

# Getting help

If none of the above resolves the problem, please
[open an issue](../../issues) describing what you tried, and say which system
you are on — Windows 10 or 11, or your macOS version and Mac model.
