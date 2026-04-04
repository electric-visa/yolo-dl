UI rewrite rules: 

1. The window's size must remain constant, unless overriden by Dynamic Type or other accessibility settings.

2. The window must not feel cramped.

3. The UI flow from top to bottom will be: 
   
   - Toolbar with app mode switch
   
   - Empty space (Download mode) / Source picker (Record mode)
   
   - File naming picker (Download mode) / Recording timer (Record mode)
   
   - URL field (Download mode & Recording mode) / Channel picker (Recording mode with live TV source)
   
   - Folder path display
   
   - Action Button & Choose Folder button
   
   - Progress Bar
   
   - Status Strip

4. In Download mode, there will be empty space between the URL field and the toolbar.

5. In Record mode, this empty space will be populated by the Source picker and the Time picker. Time picker includes its Text blocks.

6. The Source picker & Time picker will be hidden in Download mode.

7. The Source picker & Time picker must be vertically centered between the URL field's top border and the toolbar, with adequate breathing space above and below it. If this needs iteration and manual adjustment, provide clear instructions on how to experiment.

8. The Source picker & Time picker appearing or disappearing should be done with an animation that gives an illusion of the picker being revealed from behind the toolbar or hidden back there.

9. When the Source picker & Time picker appear, they should not push down the URL field or the Channel picker or cause any other UI elements to shift.

10. Whenever designing or implementing a solution, or parts of a solution, remember all of the above goals at all times.

11. ContentView must not become bloated. Other views must be extracted from ContentView to their own files when necessary.

12. Whenever a view in a separate file is touched, examine how it possibly affects ContentView.

13. Avoid improvisation. Make sure to discuss the design and architecture from all angles that are related to the rewrite goals.

14. Only start implementing after you have confirmed that the design discussion is finished and the architecture has been decided on.

15. Implementation should be done in small steps to avoid Claude's context bloating and causing hallucination.

16. Don't write any code or provide any Claude Code prompts before confirming that the next step is ready for implementation.

General project instructions apply with one exception: If you notice a need to use sosumi to search Apple documentation, first ask for permission and provide a brief explanation of what and why will you be searching.
