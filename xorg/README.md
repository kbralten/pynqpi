# Xorg Configuration for Xilinx DRM

This configuration file (`xorg.conf`) is designed to run the X Window System on Xilinx Zynq 7000 hardware using the kernel's DRM/KMS subsystem.

## Driver Selection: `modesetting`

We use the generic **modesetting** driver (`Driver "modesetting"`). 

Instead of relying on legacy framebuffer drivers (`fbdev`) or vendor-specific X11 drivers (which may be unmaintained or non-existent), we rely on the modern standard Linux graphics stack (DRM/KMS). The `modesetting` driver is effectively the "universal" driver that works with any kernel that provides a valid DRM (Direct Rendering Manager) interface.

## Referencing the Device

We explicitly target the Xilinx DRM device line:

```xorg
Option "kmsdev" "/dev/dri/card0"
```

The Xilinx kernel drivers present the display subsystem (DisplayPort/HDMI controller) as a DRM device, typically at `/dev/dri/card0`. Setting this option ensures the modesetting driver attaches specifically to the display output controller rather than attempting to attach to a different device (like a render-only GPU node) or failing to auto-detect the correct path.

## Disabling GLX and Acceleration

The configuration intentionally restricts "smart" features to ensure stability and compatibility:

```xorg
Section "Extensions"
    Option "GLX" "Disable"
    Option "Composite" "Disable"
EndSection

Section "Device"
    ...
    Option "AccelMethod" "none"
    ...
EndSection
```

**Why disable these?**
1.  **Stability**: The 2D hardware acceleration (GLAMOR) typically typically requires a working 3D GPU driver (Mali) and a functional EGL/GBM stack. By disabling acceleration (`AccelMethod "none"`), we force **software rendering** (shadow framebuffer). This is CPU-intensive but strictly reliable for basic desktop usage.
2.  **No GLX**: We disable the GLX extension because without a backing 3D hardware driver configured for X11, GLX requests might crash or hang the server.
3.  **No Composite**: Disabling the Composite extension prevents the use of compositing window managers, further simplifying the rendering pipeline to simple bit-blitting.

## Additional Tweaks

*   `Option "AutoAddGPU" "false"`: Prevents Xorg from trying to automatically add other GPU devices it finds, keeping strict control over the primary display device.
*   `Option "SWcursor" "true"`: Forces a software cursor.
