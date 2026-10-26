whispr.dev 'Chronomancer'
==========================

Welcome! And thank you for downloading whispr.dev's **whisprer's Eternal Chronomancer v8.2.0.0**.

- Chronomancer is a live wallpaper.
- It displays real-time clock and calendar readouts: a full Julian calendar (including how many weeks and days have passed so far this year) alongside the standard day / week / month / year, a 12-hour local clock, a 24-hour local clock, and a secondary world clock you can set to any time zone.
- Chronomancer runs on Windows 11 (64-bit) only at this time.
- The calendar/clocks never interfere with the normal operation of the Windows 11 desktop, its icons, or any windows you open on top of them.
- It deliberately uses Windows 11 *Efficiency mode* and CPU usage throttling so it never puts more than about **1% CPU** and **~40 MB RAM** on your machine - it can sit in the background of any Windows box without any noticeable impact at all.

Chronomancer is open source under the MIT License - see `LICENSE.txt`.


---

Installation
------------

There are two ways to install. The installer is the easy one.

### Option A - the installer (recommended)

1. Double-click `Chronomancer-8.2.0.0.msi`.
2. Windows will most likely show a blue box saying **"Windows protected your PC"**. This happens because whispr.dev's software isn't code-signed yet (signing is coming once the company registration completes). Click **More info**, then click the **Run anyway** button that appears.
3. Click **Next**, tick **I accept the terms in the License Agreement**, and click **Next**.
4. On the **Options** page, leave **Start Chronomancer automatically when I sign in to Windows** ticked if you want it to start every time you boot, or untick it if you don't. Click **Next**, then **Install**. No administrator password is needed - it installs just for your user account.
5. On the last page, leave **Launch Chronomancer now** ticked and click **Finish**.
6. For the matching backdrop: open File Explorer, paste `%LOCALAPPDATA%\Programs\Chronomancer` into the address bar and press **Enter**, then right-click `Chronomancer-Wallpaper.png` and select **Set as desktop background**.

You should now see your desktop with the Skeletrace logo and the Chronomancer clock display moving live!

The installer also puts a **Chronomancer** shortcut in your Start menu, so you can relaunch it any time.

### Option B - portable (no installer)

1. Unzip the contents of `whispr.dev-Chronomancer-8.2.0.0-portable.zip` into a new folder: `%LOCALAPPDATA%\Chronomancer-portable\` (paste that into File Explorer's address bar to get there; create the folder if it doesn't exist).
2. Right-click `Chronomancer-Wallpaper.png` and select **Set as desktop background**.
3. Double-click `Chronomancer.exe`.
4. Windows will most likely show the blue **"Windows protected your PC"** box. Click **More info**, then **Run anyway**. This only happens the first time you run that `.exe` (or again if you replace it with a fresh copy from the `.zip`).
5. By the time you've minimised or closed the Explorer window you were in, you should see the Chronomancer clock display moving live on your desktop.

To make the portable version start every time you boot Windows:

1. Press **Win + R**, type `shell:startup` and press **Enter**. A folder window opens - leave it open.
2. In your `%LOCALAPPDATA%\Chronomancer-portable\` folder, right-click `Chronomancer.exe` and select **Show more options**, then **Create shortcut**.
3. Drag the new shortcut into the `shell:startup` window from step 1.


---

Colour scheme
-------------

Chronomancer matches your current Windows colour scheme when it launches. It recognises every colour scheme in the Windows 11 Personalization settings, and adapts properly to high-contrast modes too.

If you change your Windows colour settings while it's running, restart Chronomancer to pick up the new scheme:

1. Press **Ctrl + Shift + Esc** to open Task Manager.
2. Click the **Name** column header until the list is in reverse alphabetical order, so `whisprer's Eternal Chronomancer` is near the top.
3. Right-click each `whisprer's Eternal Chronomancer` entry and select **End task**.
4. Relaunch it from the Start menu (installer version) or by double-clicking `Chronomancer.exe` (portable version).


---

Using it
--------

### Set the secondary world clock

1. Press **Ctrl + Alt + E** - Chronomancer comes to the front and becomes interactive.
2. Select the **config** tab.
3. Choose the time zone you want from the drop-down menu.
4. Press **Ctrl + Alt + D** to send Chronomancer back to the background.

Chronomancer stores your world-clock setting in a tiny `.json` file in the same folder as `Chronomancer.exe`.

### Shut it down for now

1. Press **Ctrl + Shift + Esc** to open Task Manager.
2. Right-click each `whisprer's Eternal Chronomancer` entry and select **End task**.

If it's set to start automatically, it will come back the next time you sign in to Windows.

### Stop it starting automatically

Open **Settings** > **Apps** > **Startup** and switch **Chronomancer** off. Switch it back on there whenever you like.

(Or, to remove the startup shortcut completely: press **Win + R**, type `shell:startup`, press **Enter**, and delete the Chronomancer shortcut from the folder that opens.)

Congratulations - you are now yet another proud user of the whispr.dev Chronomancer live desktop!

For support of any kind, email **chronosupport@whispr.dev** - we'll be glad to help.


---

Uninstalling
------------

### Installer version

1. Open **Settings** > **Apps** > **Installed apps**.
2. Find **whisprer's Eternal Chronomancer**, click the **...** button next to it, and select **Uninstall**.

That's it. The uninstaller closes Chronomancer if it's running, and removes the program, its Start menu and startup shortcuts, and its settings file.

### Portable version

1. Shut down any running copies (see **Shut it down for now** above).
2. Delete the whole `%LOCALAPPDATA%\Chronomancer-portable\` folder, including everything in it.
3. If you added a startup shortcut: press **Win + R**, type `shell:startup`, press **Enter**, and delete the Chronomancer shortcut from the folder that opens.
4. Finally, you can safely delete the `whispr.dev-Chronomancer-8.2.0.0-portable.zip` file from wherever you downloaded it. All traces of Chronomancer are now gone from your system.

Thank you from the bottom of our hearts for exploring Chronomancer. If you'd like to tell us why you've stopped using it, send us feedback of any kind, or just talk to the team at whispr.dev, email:

**chronomancer@whispr.dev**


---

Troubleshooting
---------------

| Problem | Solution |
| --- | --- |
| No calendar/clock appears after starting Chronomancer. | Check that your antivirus or anti-malware software isn't blocking it because it isn't a signed Windows app yet. You may need to allow `Chronomancer.exe` in that software. |
| The calendar/clock doesn't start automatically when Windows starts. | Press **Win + R**, type `shell:startup`, press **Enter**. There should be a Chronomancer shortcut in that folder, and it must point to where `Chronomancer.exe` actually lives now. If it's missing or broken, re-run the installer (installer version) or recreate it (portable version - see Option B). |
| The colours don't match my current Windows theme or personalization settings. | Restart Chronomancer - see **Colour scheme** above. |
| The calendar/clock is still there after trying to shut it down or remove it. | Press **Ctrl + Shift + Esc** to open Task Manager, select **Details** in the left-hand column, find every `Chronomancer.exe` entry, right-click each one and select **End task**. |
| The installer says another version is already installed or a file is in use. | Shut Chronomancer down (see **Shut it down for now**), then run the installer again. |

---
