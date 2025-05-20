**0.7.0**
### New Features
  - Create brand new maps
  - 2D View:
    - Multiple vertex selecting and moving now available
    - Unmerge vertices by pressing 'u' after selecting vertex
      - Overlapping vertices will remerge after changing edit modes or by clicking and not moving
    - Delete double-sided faces by selecting and pressing 'del'
      - The sector you're deleting from will replace the sister sector.
    - Delete sectors by selecting and pressing 'del'
    - Cycle overlapping sectors by pressing 'n'
    - Objects & SFX - Right-click
      - Create new
      - Copy/Paste
      - Delete
    - Remember last used grid and snap values
  - 3D View:
    - Copy and paste texture ids
      - Point at a face/sector and press 'c' to copy
      - Point at a face/sector and press 'v' to paste
      - Separate copies for faces and sectors
      - Sectors will copy both floor and ceiling textures for now
    - Show sound effect nodes on the floor of the sector instead of at height 0.
  - Edit Panel:
    - Show object textures when editing objects
    - Flip a face around (Fixed the bug that prompted this but will leave in)
    - Manually configure the id of the sister face
  - Delete maps from open map dialog
  - Switch map being edited
    - Right-click map name -> 2D Edit Mode
    - Won't lose changes when switching
    - Still need to select save to save
    - Separate save and save-as options
    - Map launched for test run will be the map open in 2d edit view
  - Edit Unknown Array 02 option
    - Add, remove, edit, and rearrange entries

### Bugfixes
  - Splitting a sector while holding shift on the second vertex no longer fails
  - Concave sector detection no longer fails if the first three vertices of a sector form a straight line
  - Faces no longer flip around when moving a vertex across its neighbor vertex

---

**0.6.0**
### New Features
  - Vertex / Sector Editing
    - Move, delete, and merge vertices
    - Split faces
    - Draw new rectangular sectors
    - Split sectors

*Notes*
  - Features still unimplemented:
    - Vertex unmerging
    - Sector merging / deleting double-sided faces
    - Undo / redo
    - More robust saving
  - Still for experimentation only. Needs more testing.

---

**0.5.0**
### New Features
  - 2D editing view
  - Basic editing of objects and sound effects
  - Select associated faces/sectors from edit panel

---

**0.4.0**
### New Features
  - Platform editing

### Bugfixes
  - Search which was broken in 0.3.0 has been fixed.

---

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
