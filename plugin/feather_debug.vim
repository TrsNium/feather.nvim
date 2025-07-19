command! -nargs=0 FeatherDebugIcons lua require('feather.debug').check_icon_support()
command! -nargs=0 FeatherTestRender lua require('feather.debug').test_render()