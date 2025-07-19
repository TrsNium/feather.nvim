command! -nargs=0 FeatherDebugIcons lua require('feather.debug').check_icon_support()
command! -nargs=0 FeatherTestRender lua require('feather.debug').test_render()
command! -nargs=0 FeatherDebugConfig lua require('feather.debug').check_config()
command! -nargs=0 FeatherForceReload lua require('feather.debug').force_reload_and_setup()