# FlClash_PE

[简体中文](README_zh_CN.md)

PE, stands for **Personal Edition**.  
Based on the upstream project, this fork focuses on personal tweaks and customizations.

## Changes

- **System Tray Icon:** ~~The upstream project's system tray icon is relatively small, and the differences between its various states are not sufficiently noticeable.~~ The upstream brought it back in v0.9.2. Therefore, it has been redesigned to more closely resemble the style of earlier versions (before v0.8.7*), with added support for adapting to the OS theme.
- **Dashboard:** Dashboard widgets can now be edited and removed at any window size. By removing components and adjusting their positions, the dashboard can be restored to a layout and interaction style similar to those in earlier versions (v0.8.98 and earlier). The layout is also more suitable for smaller window size.
- **Sidebar:** The hover area of the menu icon on the collapsed sidebar has been increased slightly. Previously, the menu icon was not sufficiently prominent, and its display area and clickable area were somewhat small. And this is also more suitable for smaller window size.
- **i18n:** Korean, French, and Spanish language support has been removed. Personally, I believe these regions have very limited use cases for this software, and supporting too many languages is unnecessary.

## Preview

The following screenshots show the dashboard and sidebar after the adjustments.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="snapshots/preview.png">
    <img alt="FlClash_PE dashboard and sidebar after modifications" src="snapshots/preview-dark.png" width="92%">
  </picture>
</p>

## ToDo

- [ ] **Profiles Layout Improvements**

  Some useful information was removed in newer versions (v0.9.1 and later). The plan is to redesign the configuration page layout using the newer styles and interactions while restoring some of the information displayed in earlier versions.

  Priority: Medium. The current layout also looks quite good.

- [ ] **Start Button Improvements**

  The start button on the dashboard in newer versions (v0.9.1 and later) is not prominent enough, and clicking it is less convenient. However, the upstream author's design considerations are also reasonable: as the UI evolves, using a Material Design-style Floating Action Button (FAB) no longer fits particularly well with the overall design language of the newer interface.

  Priority: Medium. I am still considering how to balance usability with design consistency.

- [ ] **Test and Jump Buttons Improvements**

  Similar to the start button, the test and jump buttons on the Proxies page in newer versions (v0.9.1 and later) have become less convenient to use.

  Priority: Medium. I am still exploring solutions that can improve the user experience without compromising the overall design style.

- [ ] **Restore the Material Design Style**

  I personally prefer the Material You design style. However, restoring this style would require a substantial amount of development work, and as the upstream project continues to evolve, the cost of compatibility and maintenance would continue to increase.

  Therefore, this task can only be assigned a low priority.

## Additional Notes

- **Personal Use:** This fork primarily reflects personal preferences. Feature requests and improvement suggestions are welcome, but there is no guarantee that all suggestions will be accepted or implemented.
- **Support the Upstream Project:** This project builds upon the work of the upstream author and contributors. Please support the upstream project and its developers. For issues specific to FlClash_PE or bugs introduced by its modifications, please report them here first to avoid misattributing fork-specific issues to the upstream project or disturbing its maintainers.
- **Disclaimer:** This project does not provide paid services, proxy nodes, or other commercial services, nor is it intended to facilitate unlawful activities. Users are responsible for understanding and complying with the laws and regulations applicable in their jurisdictions and for their own use of the software.
- **Update Frequency:** To keep maintenance costs manageable, some upstream releases with minor or non-essential changes may be skipped. Other updates may be released shortly after new upstream versions become available.
- **Platform Support:** Considering the platforms used in my daily work and the scope of this fork's modifications, only Windows and Linux are currently maintained. The UI style introduced in newer versions (v0.9.1 and later) is already relatively consistent with the overall design language of macOS, so there are currently no plans to maintain a macOS version. As for Android, support will depend on whether a separate application package name and signing key are used to rebuild the app in the future; otherwise, installing this version alongside the original app would cause a conflict.