local M = {}

-- Constants
M.constants = {
  FOLDER_ICON = "",
  FOLDER_OPEN_ICON = "",
  DEFAULT_FILE_ICON = "",
  DOTFILE_ICON = "",
}

-- Initialize module state
M.setup_done = false
M.has_devicons = false
M.devicons = nil

-- Setup function to integrate with nvim-web-devicons
function M.setup()
  if M.setup_done then return end
  
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    M.has_devicons = true
    M.devicons = devicons
    -- Ensure devicons is set up
    if not devicons.has_loaded() then
      devicons.setup()
    end
  end
  
  M.setup_done = true
end

-- Get icon with highlight group (similar to bufferline)
function M.get_icon(filename, is_dir, opts)
  opts = opts or {}
  
  -- Ensure setup has been called
  if not M.setup_done then
    M.setup()
  end
  
  -- Handle directories
  if is_dir then
    local icon = opts.open and M.constants.FOLDER_OPEN_ICON or M.constants.FOLDER_ICON
    return icon, "FeatherDirectory"
  end
  
  -- Try to use nvim-web-devicons if available
  if M.has_devicons and M.devicons then
    local icon, hl_group = M.devicons.get_icon(filename, nil, { default = true })
    if icon then
      return icon, hl_group
    end
  end
  
  -- Try pattern-based matching first (for framework-specific files)
  local pattern_icon = M.get_pattern_icon(filename)
  if pattern_icon then
    return pattern_icon, "FeatherSpecial"
  end
  
  -- Fallback to our manual mappings for special files
  local icon = M.get_special_file_icon(filename)
  if icon then
    return icon, "FeatherSpecial"
  end
  
  -- Try extension-based icon
  local ext_icon = M.get_icon_by_extension(filename)
  if ext_icon then
    return ext_icon, "FeatherFile"
  end
  
  -- Default file icon
  return M.constants.DEFAULT_FILE_ICON, "FeatherFile"
end

-- Get icon based on pattern matching (framework detection)
function M.get_pattern_icon(filename)
  local pattern_icons = {
    -- JavaScript frameworks
    [".*jquery.*%.js$"] = "",
    [".*angular.*%.js$"] = "",
    [".*backbone.*%.js$"] = "",
    [".*require.*%.js$"] = "",
    [".*materialize.*%.js$"] = "",
    [".*materialize.*%.css$"] = "",
    [".*mootools.*%.js$"] = "",
    [".*vimrc.*"] = "",
    ["Vagrantfile$"] = "",
  }
  
  local lower_name = filename:lower()
  for pattern, icon in pairs(pattern_icons) do
    if lower_name:match(pattern) then
      return icon
    end
  end
  
  return nil
end

-- Get icon for special files that nvim-web-devicons might miss
function M.get_special_file_icon(filename)
  local special_files = {
    -- Git files
    [".gitignore"] = "",
    [".gitattributes"] = "",
    [".gitmodules"] = "",
    [".gitconfig"] = "",
    [".gitkeep"] = "",
    [".gitmessage"] = "",
    [".git-blame-ignore-revs"] = "",
    
    -- Docker files
    ["Dockerfile"] = "",
    ["dockerfile"] = "",
    ["docker-compose.yml"] = "",
    ["docker-compose.yaml"] = "",
    [".dockerignore"] = "",
    ["Dockerfile.dev"] = "",
    ["Dockerfile.prod"] = "",
    
    -- CI/CD files
    [".travis.yml"] = "",
    ["appveyor.yml"] = "",
    [".gitlab-ci.yml"] = "",
    ["Jenkinsfile"] = "",
    ["jenkins"] = "",
    [".circleci/config.yml"] = "󰕙",
    ["azure-pipelines.yml"] = "",
    [".github/workflows"] = "",
    
    -- Package managers
    ["package.json"] = "",
    ["package-lock.json"] = "",
    ["yarn.lock"] = "",
    ["pnpm-lock.yaml"] = "",
    ["bun.lockb"] = "",
    ["Gemfile"] = "",
    ["Gemfile.lock"] = "",
    ["Cargo.toml"] = "",
    ["Cargo.lock"] = "",
    ["go.mod"] = "",
    ["go.sum"] = "",
    ["requirements.txt"] = "",
    ["requirements.in"] = "",
    ["requirements-dev.txt"] = "",
    ["Pipfile"] = "",
    ["Pipfile.lock"] = "",
    ["poetry.lock"] = "",
    ["pyproject.toml"] = "",
    ["composer.json"] = "",
    ["composer.lock"] = "",
    ["pubspec.yaml"] = "",
    ["pubspec.lock"] = "",
    ["mix.exs"] = "",
    ["mix.lock"] = "",
    ["rebar.config"] = "",
    ["erlang.mk"] = "",
    ["Brewfile"] = "",
    ["Brewfile.lock.json"] = "",
    
    -- Build files
    ["Makefile"] = "",
    ["makefile"] = "",
    ["GNUmakefile"] = "",
    ["CMakeLists.txt"] = "",
    ["cmake"] = "",
    ["meson.build"] = "󰔷",
    ["meson_options.txt"] = "󰔷",
    ["SConstruct"] = "",
    ["SConscript"] = "",
    ["build.gradle"] = "",
    ["build.gradle.kts"] = "",
    ["settings.gradle"] = "",
    ["gradlew"] = "",
    ["gradlew.bat"] = "",
    ["pom.xml"] = "",
    ["build.xml"] = "",
    ["build.sbt"] = "",
    ["webpack.config.js"] = "󰜫",
    ["webpack.common.js"] = "󰜫",
    ["webpack.dev.js"] = "󰜫",
    ["webpack.prod.js"] = "󰜫",
    ["rollup.config.js"] = "",
    ["rollup.config.ts"] = "",
    ["vite.config.js"] = "󱐋",
    ["vite.config.ts"] = "󱐋",
    ["snowpack.config.js"] = "",
    ["parcel.config.json"] = "",
    ["esbuild.config.js"] = "",
    ["turbo.json"] = "",
    ["lerna.json"] = "",
    ["nx.json"] = "",
    ["workspace.json"] = "",
    
    -- Config files
    [".editorconfig"] = "",
    [".eslintrc"] = "",
    [".eslintrc.js"] = "",
    [".eslintrc.json"] = "",
    [".eslintrc.yaml"] = "",
    [".eslintrc.yml"] = "",
    [".eslintignore"] = "",
    [".prettierrc"] = "",
    [".prettierrc.js"] = "",
    [".prettierrc.json"] = "",
    [".prettierrc.yaml"] = "",
    [".prettierrc.yml"] = "",
    [".prettierignore"] = "",
    [".stylelintrc"] = "",
    [".stylelintrc.js"] = "",
    [".stylelintrc.json"] = "",
    [".stylelintrc.yaml"] = "",
    [".stylelintrc.yml"] = "",
    ["tsconfig.json"] = "",
    ["tsconfig.base.json"] = "",
    ["tsconfig.build.json"] = "",
    ["jsconfig.json"] = "",
    [".babelrc"] = "",
    [".babelrc.js"] = "",
    [".babelrc.json"] = "",
    ["babel.config.js"] = "",
    ["babel.config.json"] = "",
    ["postcss.config.js"] = "",
    ["tailwind.config.js"] = "",
    ["tailwind.config.ts"] = "",
    
    -- Environment files
    [".env"] = "",
    [".env.local"] = "",
    [".env.development"] = "",
    [".env.production"] = "",
    [".env.test"] = "",
    [".env.example"] = "",
    [".env.sample"] = "",
    
    -- Shell config
    [".bashrc"] = "",
    [".bash_profile"] = "",
    [".bash_aliases"] = "",
    [".bash_logout"] = "",
    [".bash_history"] = "",
    [".zshrc"] = "",
    [".zshenv"] = "",
    [".zprofile"] = "",
    [".zsh_history"] = "",
    [".fishrc"] = "",
    ["config.fish"] = "",
    [".profile"] = "",
    [".inputrc"] = "",
    [".xinitrc"] = "",
    [".xprofile"] = "",
    [".Xresources"] = "",
    [".Xdefaults"] = "",
    
    -- Vim/Neovim
    [".vimrc"] = "",
    ["_vimrc"] = "",
    [".gvimrc"] = "",
    ["_gvimrc"] = "",
    ["init.vim"] = "",
    ["init.lua"] = "",
    ["ginit.vim"] = "",
    [".ideavimrc"] = "",
    [".viminfo"] = "",
    
    -- Documentation
    ["README"] = "",
    ["README.md"] = "",
    ["readme.md"] = "",
    ["README.rst"] = "",
    ["README.txt"] = "",
    ["README.adoc"] = "",
    ["LICENSE"] = "",
    ["LICENSE.md"] = "",
    ["LICENSE.txt"] = "",
    ["COPYING"] = "",
    ["COPYING.LESSER"] = "",
    ["COPYRIGHT"] = "",
    ["CHANGELOG"] = "",
    ["CHANGELOG.md"] = "",
    ["HISTORY"] = "",
    ["HISTORY.md"] = "",
    ["AUTHORS"] = "",
    ["AUTHORS.md"] = "",
    ["CONTRIBUTORS"] = "",
    ["CONTRIBUTING"] = "",
    ["CONTRIBUTING.md"] = "",
    ["TODO"] = "",
    ["TODO.md"] = "",
    ["NOTES"] = "",
    ["NOTES.md"] = "",
    ["INSTALL"] = "",
    ["INSTALL.md"] = "",
    ["MANIFEST"] = "",
    ["MANIFEST.in"] = "",
    ["NOTICE"] = "",
    ["PATENTS"] = "",
    
    -- Dotfiles
    [".DS_Store"] = "",
    ["Thumbs.db"] = "",
    ["desktop.ini"] = "",
    [".directory"] = "",
    [".npmrc"] = "",
    [".nvmrc"] = "",
    [".yarnrc"] = "",
    [".yarnrc.yml"] = "",
    [".npmignore"] = "",
    [".browserslistrc"] = "",
    [".rvmrc"] = "",
    [".ruby-version"] = "",
    [".ruby-gemset"] = "",
    [".versions.conf"] = "",
    [".python-version"] = "",
    [".node-version"] = "",
    [".php-version"] = "",
    [".java-version"] = "",
    [".go-version"] = "",
    [".tool-versions"] = "",
    [".terraform-version"] = "",
    [".terraform.lock.hcl"] = "",
    [".mise.toml"] = "",
    [".mise.local.toml"] = "",
    [".rtx.toml"] = "",
    
    -- IDE/Editor
    [".vscodeignore"] = "",
    [".vscode"] = "",
    [".idea"] = "",
    [".sublime-project"] = "",
    [".sublime-workspace"] = "",
    [".atom"] = "",
    [".brackets.json"] = "",
    [".editorconfig"] = "",
    [".emacs"] = "",
    [".emacs.desktop"] = "",
    [".spacemacs"] = "",
    ["projectile.cache"] = "",
    
    -- Test files
    ["jest.config.js"] = "",
    ["jest.config.ts"] = "",
    ["jest.config.json"] = "",
    ["jest.setup.js"] = "",
    ["jest.setup.ts"] = "",
    ["vitest.config.js"] = "",
    ["vitest.config.ts"] = "",
    ["karma.conf.js"] = "",
    ["protractor.conf.js"] = "",
    ["mocha.opts"] = "☕",
    [".mocharc.js"] = "☕",
    [".mocharc.json"] = "☕",
    [".mocharc.yaml"] = "☕",
    [".mocharc.yml"] = "☕",
    [".rspec"] = "",
    [".rspec_status"] = "",
    ["pytest.ini"] = "",
    ["setup.cfg"] = "",
    ["tox.ini"] = "",
    ["phpunit.xml"] = "",
    ["phpunit.xml.dist"] = "",
    [".phpunit.result.cache"] = "",
    ["codeception.yml"] = "",
    ["behat.yml"] = "",
    ["cypress.json"] = "",
    ["cypress.config.js"] = "",
    ["cypress.config.ts"] = "",
    
    -- Other special files
    ["robots.txt"] = "󰚩",
    ["humans.txt"] = "󰟈",
    ["sitemap.xml"] = "󰗀",
    ["sitemap.xml.gz"] = "󰗀",
    ["security.txt"] = "",
    [".htaccess"] = "",
    [".htpasswd"] = "",
    ["nginx.conf"] = "",
    ["httpd.conf"] = "",
    ["favicon.ico"] = "",
    ["manifest.json"] = "",
    ["manifest.webmanifest"] = "",
    ["browserconfig.xml"] = "",
    [".well-known"] = "",
    ["CNAME"] = "",
    ["crossdomain.xml"] = "",
    ["package.xml"] = "",
    [".gitbook.yaml"] = "",
    ["book.json"] = "",
    ["vercel.json"] = "",
    ["netlify.toml"] = "",
    ["now.json"] = "",
    ["nuxt.config.js"] = "",
    ["nuxt.config.ts"] = "",
    ["next.config.js"] = "",
    ["next.config.ts"] = "",
    ["gatsby-config.js"] = "",
    ["gatsby-node.js"] = "",
    ["gridsome.config.js"] = "",
    ["quasar.conf.js"] = "",
    ["capacitor.config.json"] = "",
    ["ionic.config.json"] = "",
    ["apollo.config.js"] = "",
    ["relay.config.js"] = "",
    ["ormconfig.json"] = "",
    ["ormconfig.js"] = "",
    
    -- Database
    ["database.yml"] = "",
    ["database.json"] = "",
    ["db.json"] = "",
    
    -- Data files
    ["data.json"] = "",
    ["data.yml"] = "",
    ["data.yaml"] = "",
    ["data.toml"] = "",
    ["data.xml"] = "",
    ["data.csv"] = "",
    
    -- Lock files
    ["lockfile"] = "",
    [".lock"] = "",
    ["lock.json"] = "",
    
    -- Gruntfile variations
    ["gruntfile.js"] = "",
    ["Gruntfile.js"] = "",
    ["gruntfile.coffee"] = "",
    ["Gruntfile.coffee"] = "",
    
    -- Gulpfile variations
    ["gulpfile.js"] = "",
    ["Gulpfile.js"] = "",
    ["gulpfile.coffee"] = "",
    ["Gulpfile.coffee"] = "",
    ["gulpfile.ts"] = "",
    ["Gulpfile.ts"] = "",
    
    -- Rakefile variations
    ["rakefile"] = "",
    ["Rakefile"] = "",
    ["rakefile.rb"] = "",
    ["Rakefile.rb"] = "",
    
    -- Procfile (Heroku)
    ["Procfile"] = "",
    ["Procfile.dev"] = "",
    
    -- Appfile (Fastlane)
    ["Appfile"] = "",
    ["Fastfile"] = "",
    ["Matchfile"] = "",
    ["Pluginfile"] = "",
    
    -- Vagrant
    ["Vagrantfile"] = "",
    
    -- Ansible
    ["ansible.cfg"] = "",
    ["hosts"] = "",
    ["playbook.yml"] = "",
    
    -- Kubernetes
    ["deployment.yaml"] = "󱃾",
    ["service.yaml"] = "󱃾",
    ["ingress.yaml"] = "󱃾",
    ["configmap.yaml"] = "󱃾",
    ["secret.yaml"] = "󱃾",
    ["pod.yaml"] = "󱃾",
    ["job.yaml"] = "󱃾",
    ["cronjob.yaml"] = "󱃾",
    ["daemonset.yaml"] = "󱃾",
    ["statefulset.yaml"] = "󱃾",
    ["persistentvolume.yaml"] = "󱃾",
    ["persistentvolumeclaim.yaml"] = "󱃾",
    ["storageclass.yaml"] = "󱃾",
    ["networkpolicy.yaml"] = "󱃾",
    ["resourcequota.yaml"] = "󱃾",
    ["limitrange.yaml"] = "󱃾",
    ["horizontalpodautoscaler.yaml"] = "󱃾",
    ["verticalpodautoscaler.yaml"] = "󱃾",
    ["poddisruptionbudget.yaml"] = "󱃾",
    ["serviceaccount.yaml"] = "󱃾",
    ["role.yaml"] = "󱃾",
    ["rolebinding.yaml"] = "󱃾",
    ["clusterrole.yaml"] = "󱃾",
    ["clusterrolebinding.yaml"] = "󱃾",
    ["namespace.yaml"] = "󱃾",
  }
  
  -- Check exact match first
  if special_files[filename] then
    return special_files[filename]
  end
  
  -- Check patterns
  local lower_name = filename:lower()
  
  -- Git files
  if lower_name:match("^%.git") then
    return ""
  end
  
  -- Lock files
  if lower_name:match("%.lock$") then
    return ""
  end
  
  -- Config files
  if lower_name:match("%.conf$") or lower_name:match("%.config$") then
    return ""
  end
  
  -- RC files
  if lower_name:match("rc$") and lower_name:match("^%.") then
    return ""
  end
  
  -- Test files
  if lower_name:match("%.test%.")  then
    return ""
  end
  
  if lower_name:match("%.spec%.") then
    return ""
  end
  
  if lower_name:match("%.e2e%.") then
    return ""
  end
  
  if lower_name:match("%.e2e-spec%.") then
    return ""
  end
  
  if lower_name:match("%.unit%.") then
    return ""
  end
  
  if lower_name:match("%.integration%.") then
    return ""
  end
  
  if lower_name:match("%.feature%.") then
    return ""
  end
  
  if lower_name:match("%.stories%.") then
    return ""
  end
  
  if lower_name:match("%.story%.") then
    return ""
  end
  
  -- Min files
  if lower_name:match("%.min%.") then
    return ""
  end
  
  -- Map files
  if lower_name:match("%.map$") then
    return ""
  end
  
  -- Backup files
  if lower_name:match("~$") or lower_name:match("%.bak$") or lower_name:match("%.backup$") then
    return ""
  end
  
  if lower_name:match("%.old$") or lower_name:match("%.orig$") then
    return ""
  end
  
  if lower_name:match("%.swp$") or lower_name:match("%.swo$") or lower_name:match("%.swn$") then
    return ""
  end
  
  -- Temporary files
  if lower_name:match("%.tmp$") or lower_name:match("%.temp$") then
    return ""
  end
  
  -- Cache files
  if lower_name:match("%.cache$") then
    return ""
  end
  
  -- Log files
  if lower_name:match("%.log$") then
    return "󰌱"
  end
  
  -- Generic dotfile
  if lower_name:match("^%.")  and not lower_name:match("%.") then
    return M.constants.DOTFILE_ICON
  end
  
  return nil
end

-- Get icon by extension (fallback method)
function M.get_icon_by_extension(filename)
  local ext = filename:match("^.+%.(.+)$")
  if not ext then
    return nil
  end
  
  local extension_icons = {
    -- Programming languages
    -- Web
    js = "",
    mjs = "",
    cjs = "",
    jsx = "",
    ts = "󰛦",
    tsx = "󰜈",
    vue = "󰡄",
    svelte = "",
    astro = "",
    
    -- Backend
    py = "",
    pyc = "",
    pyo = "",
    pyw = "",
    pyi = "",
    pyx = "",
    pxd = "",
    rb = "",
    rbw = "",
    rake = "",
    gemspec = "",
    php = "󰌟",
    phar = "󰌟",
    java = "",
    class = "",
    jar = "",
    war = "",
    ear = "",
    kt = "󱈙",
    ktm = "󱈙",
    kts = "󱈙",
    scala = "",
    sc = "",
    sbt = "",
    
    -- Systems
    c = "",
    h = "",
    cpp = "",
    cc = "",
    cxx = "",
    ["c++"] = "",
    cp = "",
    hpp = "",
    hh = "",
    hxx = "",
    ["h++"] = "",
    rs = "",
    rlib = "",
    go = "󰟓",
    zig = "",
    nim = "󰆥",
    nims = "󰆥",
    nimble = "󰆥",
    v = "",
    vv = "",
    vsh = "",
    d = "",
    di = "",
    
    -- Functional
    hs = "",
    lhs = "",
    elm = "",
    clj = "",
    cljs = "",
    cljc = "",
    edn = "",
    erl = "",
    hrl = "",
    beam = "",
    ex = "",
    exs = "",
    eex = "",
    leex = "",
    ml = "",
    mli = "",
    mll = "",
    mly = "",
    fs = "",
    fsx = "",
    fsi = "",
    fsscript = "",
    rkt = "",
    rktd = "",
    scrbl = "",
    scm = "",
    ss = "",
    
    -- Shell/Scripts
    sh = "",
    bash = "",
    zsh = "",
    fish = "",
    csh = "",
    ksh = "",
    ps1 = "󰨊",
    psm1 = "󰨊",
    psd1 = "󰨊",
    ps1xml = "󰨊",
    psc1 = "󰨊",
    pssc = "󰨊",
    bat = "",
    cmd = "",
    awk = "",
    sed = "",
    
    -- Web technologies
    html = "",
    htm = "",
    xhtml = "",
    xml = "󰗀",
    xaml = "󰗀",
    css = "",
    scss = "",
    sass = "",
    less = "",
    styl = "",
    stylus = "",
    postcss = "",
    sss = "",
    
    -- Data/Config
    json = "󰘦",
    jsonc = "󰘦",
    json5 = "󰘦",
    jsonl = "󰘦",
    ndjson = "󰘦",
    yaml = "",
    yml = "",
    toml = "",
    ini = "",
    cfg = "",
    conf = "",
    config = "",
    properties = "",
    props = "",
    env = "",
    dotenv = "",
    
    -- Documentation
    md = "󰍔",
    mdx = "󰍔",
    markdown = "󰍔",
    mkd = "󰍔",
    mkdn = "󰍔",
    mdwn = "󰍔",
    mdown = "󰍔",
    markdn = "󰍔",
    mdtxt = "󰍔",
    rst = "",
    adoc = "",
    asciidoc = "",
    rdoc = "",
    pod = "",
    txt = "󰈙",
    text = "󰈙",
    log = "󰌱",
    msg = "󰈙",
    tex = "󰙩",
    ltx = "󰙩",
    latex = "󰙩",
    bib = "󱉟",
    man = "",
    roff = "",
    info = "",
    texi = "",
    texinfo = "",
    epub = "",
    
    -- Database
    sql = "",
    mysql = "",
    pgsql = "",
    sqlite = "",
    sqlite3 = "",
    db = "",
    db3 = "",
    sdb = "",
    s3db = "",
    
    -- Images
    jpg = "󰋩",
    jpeg = "󰋩",
    jpe = "󰋩",
    jp2 = "󰋩",
    jpx = "󰋩",
    png = "󰋩",
    apng = "󰋩",
    gif = "󰋩",
    bmp = "󰋩",
    dib = "󰋩",
    ico = "󰋩",
    svg = "󰜡",
    svgz = "󰜡",
    webp = "󰋩",
    avif = "󰋩",
    tiff = "󰋩",
    tif = "󰋩",
    psd = "",
    psb = "",
    ai = "",
    eps = "",
    sketch = "󰗜",
    fig = "󰻿",
    xd = "󰮯",
    pdf = "",
    
    -- Video
    mp4 = "󰕧",
    m4v = "󰕧",
    mkv = "󰕧",
    avi = "󰕧",
    mov = "󰕧",
    qt = "󰕧",
    wmv = "󰕧",
    webm = "󰕧",
    flv = "󰕧",
    f4v = "󰕧",
    mpg = "󰕧",
    mpeg = "󰕧",
    mpe = "󰕧",
    mpv = "󰕧",
    m2v = "󰕧",
    ogv = "󰕧",
    ["3gp"] = "󰕧",
    ["3g2"] = "󰕧",
    h264 = "󰕧",
    h265 = "󰕧",
    hevc = "󰕧",
    
    -- Audio
    mp3 = "󰎆",
    wav = "󰎆",
    wave = "󰎆",
    flac = "󰎆",
    aac = "󰎆",
    m4a = "󰎆",
    wma = "󰎆",
    ogg = "󰎆",
    oga = "󰎆",
    opus = "󰎆",
    spx = "󰎆",
    ape = "󰎆",
    mka = "󰎆",
    aiff = "󰎆",
    aif = "󰎆",
    aifc = "󰎆",
    au = "󰎆",
    snd = "󰎆",
    mid = "󰎆",
    midi = "󰎆",
    
    -- Archives
    zip = "",
    zipx = "",
    rar = "",
    tar = "",
    gz = "",
    gzip = "",
    bz = "",
    bz2 = "",
    bzip = "",
    bzip2 = "",
    xz = "",
    lz = "",
    lzma = "",
    lzo = "",
    z = "",
    Z = "",
    ["7z"] = "",
    cab = "",
    deb = "",
    rpm = "",
    pkg = "",
    dmg = "",
    iso = "󰗮",
    img = "󰗮",
    vhd = "󰗮",
    vhdx = "󰗮",
    wim = "",
    swm = "",
    esd = "",
    appx = "",
    appxbundle = "",
    msix = "",
    msixbundle = "",
    msi = "",
    
    -- Documents
    doc = "󰈬",
    docx = "󰈬",
    docm = "󰈬",
    dot = "󰈬",
    dotx = "󰈬",
    dotm = "󰈬",
    odt = "󰈬",
    ott = "󰈬",
    rtf = "󰈬",
    xls = "󰈛",
    xlsx = "󰈛",
    xlsm = "󰈛",
    xlsb = "󰈛",
    xlt = "󰈛",
    xltx = "󰈛",
    xltm = "󰈛",
    xlam = "󰈛",
    ods = "󰈛",
    ots = "󰈛",
    csv = "󰈛",
    tsv = "󰈛",
    ppt = "󰐩",
    pptx = "󰐩",
    pptm = "󰐩",
    pot = "󰐩",
    potx = "󰐩",
    potm = "󰐩",
    ppam = "󰐩",
    pps = "󰐩",
    ppsx = "󰐩",
    ppsm = "󰐩",
    odp = "󰐩",
    otp = "󰐩",
    
    -- Fonts
    ttf = "",
    ttc = "",
    otf = "",
    otc = "",
    woff = "",
    woff2 = "",
    eot = "",
    fon = "",
    fnt = "",
    pfb = "",
    pfm = "",
    
    -- Other languages
    lua = "",
    vim = "",
    vimrc = "",
    r = "󰟔",
    R = "󰟔",
    rmd = "󰟔",
    Rmd = "󰟔",
    rnw = "󰟔",
    Rnw = "󰟔",
    jl = "",
    pl = "",
    pm = "",
    t = "",
    raku = "",
    p6 = "",
    pm6 = "",
    pod6 = "",
    swift = "",
    dart = "",
    pas = "",
    pp = "",
    pascal = "",
    delphi = "",
    dfm = "",
    dpr = "",
    lpr = "",
    ada = "",
    adb = "",
    ads = "",
    ali = "",
    f = "",
    ["for"] = "",
    ftn = "",
    f90 = "",
    f95 = "",
    f03 = "",
    f08 = "",
    ["f77"] = "",
    forth = "",
    fth = "",
    ["4th"] = "",
    frt = "",
    fs = "",
    fsx = "",
    fsi = "",
    cob = "",
    cbl = "",
    cpy = "",
    vb = "󰏛",
    vba = "󰏛",
    vbs = "󰏛",
    bas = "",
    frm = "",
    vbhtml = "󰏛",
    vbproj = "󰏛",
    sln = "",
    csproj = "󰌛",
    fsproj = "",
    xproj = "",
    props = "",
    targets = "",
    proj = "",
    asm = "",
    s = "",
    S = "",
    a51 = "",
    nasm = "",
    masm = "",
    ld = "",
    lds = "",
    S = "",
    xs = "",
    x = "",
    xi = "",
    xm = "",
    xmi = "",
    
    -- Web Assembly
    wat = "",
    wast = "",
    wasm = "",
    
    -- Cryptocurrency
    sol = "",
    
    -- Game engines
    gd = "",
    tscn = "",
    tres = "",
    godot = "",
    gdscript = "",
    
    -- Unity
    unity = "",
    prefab = "",
    mat = "",
    meta = "",
    controller = "",
    anim = "",
    animset = "",
    overrideController = "",
    mask = "",
    
    -- Unreal
    uasset = "",
    umap = "",
    uc = "",
    upk = "",
    udk = "",
    u = "",
    
    -- 3D/CAD
    obj = "󰆧",
    mtl = "󰆧",
    ["3ds"] = "󰆧",
    blend = "󰂫",
    fbx = "󰆧",
    dae = "󰆧",
    gltf = "󰆧",
    glb = "󰆧",
    stl = "󰆧",
    stp = "󰆧",
    step = "󰆧",
    igs = "󰆧",
    iges = "󰆧",
    fcstd = "󰻬",
    dwg = "󰻬",
    dxf = "󰻬",
    
    -- GIS
    shp = "",
    shx = "",
    dbf = "",
    sbn = "",
    sbx = "",
    cpg = "",
    prj = "",
    qpj = "",
    kml = "",
    kmz = "",
    gpx = "",
    
    -- Jupyter
    ipynb = "",
    
    -- R Markdown
    rmd = "󰟔",
    Rmd = "󰟔",
    
    -- GraphQL
    gql = "",
    graphql = "",
    graphqls = "",
    
    -- Prisma
    prisma = "",
    
    -- Protocol Buffers
    proto = "",
    
    -- CUDA
    cu = "",
    cuh = "",
    
    -- OpenCL
    cl = "",
    opencl = "",
    
    -- GLSL/HLSL
    glsl = "",
    vert = "",
    tesc = "",
    tese = "",
    geom = "",
    frag = "",
    comp = "",
    hlsl = "",
    fx = "",
    fxh = "",
    vsh = "",
    psh = "",
    cginc = "",
    compute = "",
    
    -- HDL
    v = "",
    sv = "",
    svh = "",
    vhd = "",
    vhdl = "",
    ucf = "",
    qsf = "",
    tcl = "",
    
    -- Matlab/Octave
    m = "",
    mat = "",
    fig = "",
    mdl = "",
    slx = "",
    mlx = "",
    p = "",
    mex = "",
    
    -- LabVIEW
    vi = "",
    ctl = "",
    lvproj = "",
    lvlib = "",
    lvclass = "",
    
    -- Misc
    bak = "",
    diff = "",
    patch = "",
    rej = "",
    bin = "",
    exe = "",
    dll = "",
    so = "",
    dylib = "",
    a = "",
    lib = "",
    ko = "",
    pkg = "",
    deb = "",
    rpm = "",
    apk = "",
    ipa = "",
    app = "",
    com = "",
    bat = "",
    ps1 = "󰨊",
    reg = "",
    inf = "",
  }
  
  return extension_icons[ext:lower()]
end

-- Compatibility function for existing code
function M.get_icon_simple(filename, is_dir)
  local icon, _ = M.get_icon(filename, is_dir)
  return icon
end

-- Export for backward compatibility
M.folder_icon = M.constants.FOLDER_ICON
M.folder_open_icon = M.constants.FOLDER_OPEN_ICON
M.default_file_icon = M.constants.DEFAULT_FILE_ICON

return M