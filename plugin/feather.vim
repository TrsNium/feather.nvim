if exists('g:loaded_feather')
  finish
endif
let g:loaded_feather = 1

command! -nargs=0 Feather lua require('feather').toggle()
command! -nargs=0 FeatherToggle lua require('feather').toggle()
command! -nargs=0 FeatherOpen lua require('feather').open()
command! -nargs=0 FeatherClose lua require('feather').close()