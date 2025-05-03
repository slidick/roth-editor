**0.3.0**
### New Features
  - Support for reading and writing .raw files.
  - Some editing now available.
    - Change textures on walls, floors, and ceilings.
    - Adjust scale, shifting, and all supported flags.
    - Change ceiling and floor height.
    - Change sector and face trigger values.
    - Change map metadata my right clicking map name.
    - Save changes by right clicking map name and selecting save. Will ask for a new name. No retail maps should be overwritten. Maps will be saved to %APPDATA%/Roaming/roth_editor/maps
  - Launch maps directly from the editor.
    - Starting position will be changed to current location in the editor.
    - Press R to run with no enemies, objects, or map transitions.
    - Press T to run with everything.
  - New sound dialog player: Browse and search subtitles and listen to your favorite in-game dialogs.

### Changes
  - Map and texture files are no longer included. Must use own copy of Realms of the Haunting to view maps. 
    - File > Settings to setup installation directory and dosbox configuration.
  
### Bugfixes
  - Search window was incorrectly doing some string comparisons instead of integer.
  - IMAGE_FIT textures shouldn't apply texture shifts.

---

**0.2.0**
  - Feature: Added search mode. Search fields by bit or value.
  - Feature: Added arrow to help find search selection. Toggle with F.
  - Feature: Show basic sound effect information.
  - Feature: Added support for the texture flag DRAW_FROM_BOTTOM. Textures used on walls whose ceiling height changes will now be drawn correctly.
  - Change: Camera position now only set on first map load.
  - Bugfix: Textures wouldn't show up in panel after selecting a face when loading multiple maps that used different das files.
  - Bugfix: Certain textures weren't rotated and mirrored properly.
