add_subdirectory(App)
add_subdirectory(TaskPanel)
if(FREECAD_BUILD_GUI)
    add_subdirectory(Gui)
endif(FREECAD_BUILD_GUI)
install(
    FILES
        Init.py
        InitGui.py
        TaskPanel/TaskPanel.py
    DESTINATION
        Mod/Vend
)
