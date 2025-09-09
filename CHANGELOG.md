**0.11.0**
### New Features
  #### Command Editor
    - Each command type has a name and at least some flags or args named
    - Each command type's args are set as single-byte or double-byte, signed or unsigned
      - Press enter on a value to perform validation
    - Add searching for every reference of Sector IDs, Face IDs, and Object IDs
    - Add toggles for changing command modifer value
    - Command Editor is now a tab rather than a floating window
    - Changes made in the command editor are applied immediately
    - Only permit allowed command types to be set as entry commands
      - Lock command type while set as entry command
    - All commands should get updated with correct index references after command deletions

  #### Objects
    - Add rendering of simple objects to the 3d view
      - Supports fixed and billboard style rendering
    - Add object selection dialog with recents and favorites
    - Objects panel overhaul with new object flag options
    - Add, copy, paste, and delete objects via the 3d viewport
      - Press the 'Z' key to open the 3d viewport context menu
      - Objects added to a wall will be automatically set to fixed rendering, rotated to match the wall, and moved out a unit
    - Press PgUp/PgDown to autosnap selected object to ceiling/floor
    - Multiple objects can now be selected in the 2d view
      - Only supports moving and deleting for now

  #### Manage Maps
    - Open window renamed to Manage Maps
    - Create new map moved here
    - Maps can now be renamed from right-click menu
    - Run maps directly from here
      - Highlight all maps to be included in run
      - Map with extra highlight will be starting map
    - Import maps
      - New .roth map pack format can be imported
      - Select individual maps to be imported
    - Export maps
      - Maps can be exported as a pack with additional metadata

  #### Editor
    - Remove old info tab
    - Add SFX ID search
    - Maps are now saved with additional metadata
      - Now saves the position of the command nodes in the command editor

### Changes
  - Removed the ability to run a single map with no objects loaded
    
### Bugfixes
  - Don't try and create sectors with zero length or width
  - Fix for issue with raw compiler's deduplication of texture maps
    - Originally I was deduping every shared texture map, but that created issues when the texture was modified by the command system (e.g. breaking a window would break all windows)
    - Then I tried not deduping any face with an id, but that created some strange ordering issues as well as just too many texture maps on a couple maps (e.g. only the backside of the fire in STUDY1 would explode)
    - So now I dedupe every texture except those with a face id AND is used in the command system by certain command types. The checks for now are just the couple that caused issues, but I'm sure there's more that need to be checked for.
  - Entry commands that are a part of another command chain are no longer shown twice
  - Update 2d line thickness when initially opening a map
  - Texture selection dialog's recent and favorites lists use new rotatable list
  - Setting an advanced sister value to *blank* now correctly removes the sister from the face
  - Map name gets updated in the editor and command editor when a map gets save-as'ed



---

**0.10.0**
### New Features
  - Add support for the other versions of RotH
    - UK, Germany, France, Italy, Spain, and US versions now supported
  - Texture loading improvements *significantly* reduce vram usage
  - Delete multiple commands at once
  - Favorite and recent texture support

### Bugfixes
  - Face ID can now be proper length to support door hinges
  - GDV audio shouldn't get out of sync anymore
  - Save-as now does a case insensitive name collision check

---

**0.9.0**
### New Features
  - New Extras Window parses remaining files: DBASE100.DAT, DBASE200.DAT, DBASE300.DAT, .GDV files, FXSCRIPT.SFX, ICONS.ALL, and BACKDROP.RAW
  - Includes the following:
    - Global command list
    - Movie list
      - Subtitles
      - Video Playback
    - Inventory item list
      - Images
      - Animation videos
      - Extra unknown info
    - Interface text list
    - Weapon animations
    - Sound effects
    - Game Icons
    - Backdrop Image

### Changes
  - Moved Dialog Viewer into Extras Window
  - Moved DAS Viewer into Extras Window
  - DAS and GDV parsing are now handled by a c++ extension so there should be a noticeable speed improvement (though not as great as hoped)
    - This means it's no longer a standalone executable; it now requires the accompanying .dll / .so file next to it

---

**0.8.0**
### New Features
  - Command Editor
    - A first iteration command editor is now available
    - Both a simple list view and a visual graph view are available
    - Changes are synced across the views
    - Command Base 59 (Warping/Map Change) has support for entering a map name
    - All other command types require manually entering/understanding all fields for now
    - Has a search feature for all different fields and a couple known types
  - Search the map for sector ids, face ids, and object ids using info tab

### Changes
  - When running a custom map, the file will now be saved and ran using its name
    - Before it was saved as a different file called TEST_MAP.RAW
    - This change allows proper testing of map transitions with custom names
  - When running a builtin map, the file will still be saved as TEST_MAP.RAW

### Bugfixes
  - Save-as is (hopefully) no longer broken

---

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
