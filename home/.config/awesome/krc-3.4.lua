-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Libraries defined by user
require("awful.remote")
vicious = require("vicious")
require("blingbling")
require("scratch")

-- Set locale
os.setlocale(os.getenv("LANG"))

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
theme_path = awful.util.getdir("config") .. "/themes/my"
-- theme_path = "/usr/share/awesome/themes/default/theme.lua"
-- theme_path = "/usr/share/awesome/themes/zenburn"
beautiful.init(theme_path .. "/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvtc"
-- editor = os.getenv("EDITOR") or "nano"
-- editor_cmd = terminal .. " -e " .. editor
editor = "xdg-open"
editor_cmd = editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Transparency settings (make unfocussed clients transparent)
focus_trans = true
opacity_normal = 0.93
opacity_focus = 1
opacity_toggle = 0.6
opacity_step = 0.05

-- Transparent notifications
naughty.config.presets.normal.opacity = 0.85
naughty.config.presets.low.opacity = 0.85
naughty.config.presets.critical.opacity = 0.85

-- Dynamic client properties table
clienttable = {}

-- Autostart apps directory
autostart_dir = awful.util.getdir("config") .. "/autostart"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}
-- }}}

-- {{{ Functions
-- Autostart function
function autostart(dir)
    if not dir then
        do return nil end
    end
    local fd = io.popen("ls -1 -F " .. dir)
    if not fd then
        do return nil end
    end
    for file in fd:lines() do
        local c= string.sub(file,-1)   -- last char
        if c=='*' then  -- executables
            executable = string.sub( file, 1,-2 )
            print("Awesome Autostart: Executing: " .. executable)
            awful.util.spawn_with_shell(dir .. "/" .. executable .. "") -- launch in bg
        elseif c=='@' then  -- symbolic links
            print("Awesome Autostart: Not handling symbolic links: " .. file)
        else
            print ("Awesome Autostart: Skipping file " .. file .. " not executable.")
        end
    end
    io.close(fd)
end

-- Clients table managing
 -- Create an entry in the client table
function createctable(c)
    if clienttable[c] == nil then
        clienttable[c] = {}
    end
end
function custom_trans_on(c)
    createctable(c)
    if not clienttable[c].custom_trans then
        clienttable[c].custom_trans = true
    end
end

-- setFg: put colored span tags around a text, useful for wiboxes
function setFg(fg,s)
    return "<span color=\"" .. fg .. "\">" .. s .."</span>"
end
colored_on = setFg("green", "on")
colored_off = setFg("red", "off")

-- Collect client infos
function get_fixed_client_infos(c)
    local txt = ""
    if c.name then txt = txt .. setFg("white", "Name: ") .. c.name .. "\n" end
    if c.pid then txt = txt .. setFg("white", "PID: ") .. c.pid .. "\n" end
    if c.class then txt = txt .. setFg("white", "Class: ") .. c.class .. "\n" end
    if c.instance then txt = txt .. setFg("white", "Instance: ") .. c.instance .. "\n" end
    if c.role then txt = txt .. setFg("white", "Role: ") .. c.role .. "\n" end
    if c.type then txt = txt .. setFg("white", "Type: ") .. c.type .. "\n" end
    return txt
end

function get_dyn_client_infos(c)
    local txt = ""
    if c.screen then txt = txt .. setFg("white", "Screen: ") .. c.screen .. "\n" end
    if awful.client.floating.get(c) then txt = txt .. setFg("white", "Floating: ") .. colored_on .. "\n" end
    if c.ontop then txt = txt .. setFg("white", "On top: ") .. colored_on .. "\n" end
    if c.fullscreen then txt = txt .. setFg("white", "Fullscreen: ") .. colored_on .. "\n" end
    if c.titlebar then txt = txt .. setFg("white", "Titlebar: ") .. colored_on .. "\n" end
    if c.opacity then txt = txt .. setFg("white", "Opacity: ") .. c.opacity .. "\n" end
    if c.icon_path then txt = txt .. setFg("white", "Icon_path: ") .. c.icon_path .. "\n" end
    return txt
end

-- Show some client infos in a naughy box
function show_client_infos(c)
    txt = get_fixed_client_infos(c)
    txt = txt .. "\n" .. get_dyn_client_infos(c)
    naughty.notify({ title = "Client info", text = txt, timeout = 6 })
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
tags.setup = {
    { name = "Kct",  layout = layouts[1]  },
    { name = "IM", layout = layouts[3]  },
    { name = "Web",   layout = layouts[1]  },
    { name = "RSS",  layout = layouts[1]  },
    { name = "FM",    layout = layouts[1],  },
    { name = "P2P",     layout = layouts[1],  },
    { name = "Vid",     layout = layouts[1],  },
    { name = "Img",   layout = layouts[1]  },
    { name = "Snd", layout = layouts[1]  },
    { name = "VM", layout = layouts[1]  },
    { name = "Txt", layout = layouts[1]  },
    { name = "VoN", layout = layouts[1]  }
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = {}
    for i, t in ipairs(tags.setup) do
        t.screen = s
        table.insert(tags[s], i, awful.tag.add(t.name, t))
    end
    tags[s][1].selected = true
--    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Load user  widgets
dofile(awful.util.getdir("config") .. "/kbd-3.4.lua")
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
-- mytextclock = awful.widget.textclock({ align = "right" })
mytextclock = awful.widget.textclock({ align = "right" }, " %a %d %b, %R ")
-- mytextclock = awful.widget.textclock({ align = "right" }, " %a %d %b ")


-- {{{ BlingBling
    --widget separator
    separator = widget({ type = "textbox", name = "separator"})
    separator.text = "  "

    --pango
    function setFs(fs,t)
	return "<span size=\"" .. fs .. "\">" .. t .."</span>"
    end

    --shutdown widget
    shutdown=blingbling.system.shutdownmenu(beautiful.icon_shutdown,
                                            beautiful.icon_accept,
                                            beautiful.icon_cancel)
--     shutdown.resize= false
    awful.widget.layout.margins[shutdown]={top=4}
    --reboot widget
    reboot=blingbling.system.rebootmenu(beautiful.icon_reboot, 
                                        beautiful.icon_accept, 
                                        beautiful.icon_cancel)
--     reboot.resize = false
    awful.widget.layout.margins[reboot]={top=4}

    --Cpu widget
    cpulabel= widget({ type = "textbox" })
    cpulabel.text='CPU: '
    cpuwidget = widget({ type = "textbox" })
    vicious.register(cpuwidget, vicious.widgets.cpu, "<span size=\"large\">$1%</span>")
    cpu=blingbling.classical_graph.new()
    cpu:set_font_size(12)
    cpu:set_height(22)
    cpu:set_width(60)
    cpu:set_show_text(true)
    cpu:set_label("$percent %")
    cpu:set_graph_color(beautiful.graph_color)
    cpu:set_graph_line_color(beautiful.graph_line_color)
    cpu:set_text_color(beautiful.text_color)
    cpu:set_background_text_color(beautiful.background_text_color)
--     cpu:set_tiles_color("#00000022")
    cpu:set_h_margin(2)
    vicious.register(cpu, vicious.widgets.cpu, '$1',8)

    -- GPUt widget
    gputlabel= widget({ type = "textbox" })
    gputlabel.text='GPUt: '
    gputwidget = widget({ type = "textbox" })
    gputwidget.width = "25"
    function update_nvidia()
	local perf = assert(io.popen("nvidia-settings -q gpucurrentperflevel -t", "r"))
	local temp = assert(io.popen("nvidia-settings -q gpucoretemp -t", "r"))
	local myperf = perf:read()
	local mytemp = temp:read()
	if not myperf then myperf = "na" end
	if not mytemp then mytemp = "na" end
	gputwidget.text = myperf .. ":" .. mytemp
	perf:close()
	temp:close()
    end
    update_nvidia()
    gputwidgettimer = timer({ timeout = 8 })
    gputwidgettimer:add_signal("timeout", function() update_nvidia() end)
    gputwidgettimer:start()

    -- GPUt graph widget
    gput = blingbling.value_text_box.new()
    gput:set_height(22)
    gput:set_width(25)
    gput:set_rounded_size(0.6)
    gput:set_values_text_color({{"#00ffdfff" ,0},{"#ffce1bff", 70},{"#ff4b25ff",85}})
    gput:set_font_size(12)
    gput:set_background_color("#00000022")
    gput:set_label("$percent°C")
    function update_nvidia2()
	local temp = assert(io.popen("nvidia-settings -q gpucoretemp -t", "r"))
	local mytemp = temp:read()
	if not mytemp then mytemp = 0 end
	gput:add_value(mytemp/100)
	temp:close()
    end
    update_nvidia2()
    gputtimer = timer({ timeout = 8 })
    gputtimer:add_signal("timeout", function() update_nvidia2() end)
    gputtimer:start()

    -- CPUt widget
    cputlabel= widget({ type = "textbox" })
    cputlabel.text='CPUt: '
    cput = blingbling.value_text_box.new()
    cput:set_height(22)
    cput:set_width(25)
    cput:set_rounded_size(0.6)
    cput:set_values_text_color({{"#00ffdfff" ,0},{"#ffce1bff", 70},{"#ff4b25ff",85}})
    cput:set_font_size(12)
    cput:set_background_color("#00000022")
    cput:set_label("$percent°C")
    vicious.register(cput, vicious.widgets.thermal, '$1',8, "thermal_zone0")

    hddtlabel= widget({ type = "textbox" })
    hddtlabel.text='HDDt: '
    hddtempwidget = widget({ type = "textbox" })
    vicious.register(hddtempwidget, vicious.widgets.hddtemp, "${/dev/sda} °C", 19)

  -- Mem Widget
    memlabel= widget({ type = "textbox" })
    memlabel.text='MEM: '
    memwidget = blingbling.classical_graph.new()
    memwidget:set_font_size(12)
    memwidget:set_height(22)
    memwidget:set_width(60)
    memwidget:set_show_text(true)
    memwidget:set_label("$percent %")
    memwidget:set_graph_color(beautiful.graph_color)
    memwidget:set_graph_line_color(beautiful.graph_line_color)
    memwidget:set_text_color(beautiful.text_color)
    memwidget:set_background_text_color(beautiful.background_text_color)
--     memwidget:set_tiles_color("#00000022")
    memwidget:set_h_margin(2)
    vicious.register(memwidget, vicious.widgets.mem, "$1", 5)

    --Cores Widgets
    mycore1=blingbling.progress_graph.new()
    mycore1:set_height(22)
    mycore1:set_width(7)
    mycore1:set_filled(true)
    mycore1:set_h_margin(1)
--     mycore1:set_filled_color("#00000033")
    mycore1:set_graph_color(beautiful.graph_color)
    mycore1:set_graph_line_color(beautiful.graph_line_color)
    vicious.register(mycore1, vicious.widgets.cpu, "$2")

    mycore2=blingbling.progress_graph.new()
    mycore2:set_height(22)
    mycore2:set_width(7)
    mycore2:set_filled(true)
    mycore2:set_h_margin(1)
--     mycore2:set_filled_color("#00000033")
    mycore2:set_graph_color(beautiful.graph_color)
    mycore2:set_graph_line_color(beautiful.graph_line_color)
    vicious.register(mycore2, vicious.widgets.cpu, "$2")

    mycore3=blingbling.progress_graph.new()
    mycore3:set_height(22)
    mycore3:set_width(7)
    mycore3:set_filled(true)
    mycore3:set_h_margin(1)
--     mycore3:set_filled_color("#00000033")
    mycore3:set_graph_color(beautiful.graph_color)
    mycore3:set_graph_line_color(beautiful.graph_line_color)
    vicious.register(mycore3, vicious.widgets.cpu, "$2")

    mycore4=blingbling.progress_graph.new()
    mycore4:set_height(22)
    mycore4:set_width(7)
    mycore4:set_filled(true)
    mycore4:set_h_margin(1)
--     mycore4:set_filled_color("#00000033")
    mycore4:set_graph_color(beautiful.graph_color)
    mycore4:set_graph_line_color(beautiful.graph_line_color)
    vicious.register(mycore4, vicious.widgets.cpu, "$2")

    --Mpd widgets
    mpdlabel= widget({ type = "textbox" })
    mpdlabel.text='MPD: '
    my_mpd=blingbling.mpd_visualizer.new()
    my_mpd:set_height(22)
    my_mpd:set_width(300)
    my_mpd:update()
    my_mpd:set_line(true)
    my_mpd:set_h_margin(2)
    my_mpd:set_mpc_commands()
    my_mpd:set_launch_mpd_client(terminal .. " -e ncmpcpp")
    my_mpd:set_show_text(true)
    my_mpd:set_font_size(12)
    my_mpd:set_graph_color(beautiful.graph_line_color)
    my_mpd:set_text_color(beautiful.text_color)
    my_mpd:set_background_text_color("#00000066")
    my_mpd:set_label("$artist > $title")

    my_mpd_volume=blingbling.volume.new()
    my_mpd_volume:set_height(22)
    my_mpd_volume:set_width(30)
    my_mpd_volume:set_v_margin(3)
    my_mpd_volume:update_mpd()
    my_mpd_volume:set_bar(true)
    my_mpd_volume:set_background_graph_color("#00000066")
    my_mpd_volume:set_graph_color(beautiful.graph_line_color)

    --udisks-glue menu
    udisks_glue=blingbling.udisks_glue.new(beautiful.icon_udisks_glue)
    udisks_glue:set_mount_icon(beautiful.icon_accept)
    udisks_glue:set_umount_icon(beautiful.icon_cancel)
    udisks_glue:set_detach_icon(beautiful.icon_cancel)
    udisks_glue:set_Usb_icon(beautiful.icon_usb)
    udisks_glue:set_Cdrom_icon(beautiful.icon_cdrom)
    awful.widget.layout.margins[udisks_glue.widget]= { top = 4}
--     udisks_glue.widget.resize= false

    -- FS Widget
    fs_my_home_label= widget({ type = "textbox", name = "fs_my_home_label" })
    fs_my_home_label.text= setFs("large","~: ")
    fs_my_home = blingbling.value_text_box.new()
    fs_my_home:set_height(22)
    fs_my_home:set_width(25)
    fs_my_home:set_rounded_size(0.6)
    fs_my_home:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_my_home:set_font_size(12)
    fs_my_home:set_background_color("#00000028")
    fs_my_home:set_label("$percent%")
    vicious.register(fs_my_home, vicious.widgets.fs, "${/home/user used_p}", 120 )

    fs_archive_label= widget({ type = "textbox", name = "fs_archive_label" })
    fs_archive_label.text= setFs("large","archive: ")
    fs_archive = blingbling.value_text_box.new()
    fs_archive:set_height(22)
    fs_archive:set_width(25)
    fs_archive:set_rounded_size(0.6)
    fs_archive:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_archive:set_font_size(12)
    fs_archive:set_background_color("#00000028")
    fs_archive:set_label("$percent%")
    vicious.register(fs_archive, vicious.widgets.fs, "${/mnt/archive used_p}", 120 )

    fs_media_label= widget({ type = "textbox", name = "fs_media_label" })
    fs_media_label.text= setFs("large","media: ")
    fs_media = blingbling.value_text_box.new()
    fs_media:set_height(22)
    fs_media:set_width(25)
    fs_media:set_rounded_size(0.6)
    fs_media:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_media:set_font_size(12)
    fs_media:set_background_color("#00000028")
    fs_media:set_label("$percent%")
    vicious.register(fs_media, vicious.widgets.fs, "${/mnt/media used_p}", 120 )

    fs_usr_label= widget({ type = "textbox", name = "fs_usr_label" })
    fs_usr_label.text= setFs("large","usr: ")
    fs_usr = blingbling.value_text_box.new()
    fs_usr:set_height(22)
    fs_usr:set_width(25)
    fs_usr:set_rounded_size(0.6)
    fs_usr:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_usr:set_font_size(12)
    fs_usr:set_background_color("#00000028")
    fs_usr:set_label("$percent%")
    vicious.register(fs_usr, vicious.widgets.fs, "${/usr used_p}", 120 )

    fs_opt_label= widget({ type = "textbox", name = "fs_opt_label" })
    fs_opt_label.text= setFs("large","opt: ")
    fs_opt = blingbling.value_text_box.new()
    fs_opt:set_height(22)
    fs_opt:set_width(25)
    fs_opt:set_rounded_size(0.6)
    fs_opt:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_opt:set_font_size(12)
    fs_opt:set_background_color("#00000028")
    fs_opt:set_label("$percent%")
    vicious.register(fs_opt, vicious.widgets.fs, "${/opt used_p}", 120 )

    fs_var_label= widget({ type = "textbox", name = "fs_var_label" })
    fs_var_label.text= setFs("large","var: ")
    fs_var = blingbling.value_text_box.new()
    fs_var:set_height(22)
    fs_var:set_width(25)
    fs_var:set_rounded_size(0.6)
    fs_var:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_var:set_font_size(12)
    fs_var:set_background_color("#00000028")
    fs_var:set_label("$percent%")
    vicious.register(fs_var, vicious.widgets.fs, "${/var used_p}", 120 )

    fs_root_label= widget({ type = "textbox", name = "fs_root_label" })
    fs_root_label.text= setFs("large","root: ")
    fs_root = blingbling.value_text_box.new()
    fs_root:set_height(22)
    fs_root:set_width(25)
    fs_root:set_rounded_size(0.6)
    fs_root:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_root:set_font_size(12)
    fs_root:set_background_color("#00000028")
    fs_root:set_label("$percent%")
    vicious.register(fs_root, vicious.widgets.fs, "${/ used_p}", 120 )

    fs_storage_label= widget({ type = "textbox", name = "fs_storage_label" })
    fs_storage_label.text= setFs("large","storage: ")
    fs_storage = blingbling.value_text_box.new()
    fs_storage:set_height(22)
    fs_storage:set_width(25)
    fs_storage:set_rounded_size(0.6)
    fs_storage:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_storage:set_font_size(12)
    fs_storage:set_background_color("#00000028")
    fs_storage:set_label("$percent%")
    vicious.register(fs_storage, vicious.widgets.fs, "${/mnt/usb_storage used_p}", 120 )

    fs_home_label= widget({ type = "textbox", name = "fs_home_label" })
    fs_home_label.text= setFs("large","home: ")
    fs_home = blingbling.value_text_box.new()
    fs_home:set_height(22)
    fs_home:set_width(25)
    fs_home:set_rounded_size(0.6)
    fs_home:set_values_text_color({{"#00ffdfff",0},{"#ffce1bff", 0.70},{"#ff4b25ff",0.85}})
    fs_home:set_font_size(12)
    fs_home:set_background_color("#00000028")
    fs_home:set_label("$percent%")
    vicious.register(fs_home, vicious.widgets.fs, "${/home used_p}", 120 )

  --Volume
    volume_label = widget({ type = "textbox"})
    volume_label.text= setFs("large","Vol.: ")
    my_volume=blingbling.volume.new()
    my_volume:set_height(22)
    my_volume:set_v_margin(3)
    my_volume:set_width(30)
    my_volume:update_master()
    my_volume:set_master_control()
    my_volume:set_bar(true)
    my_volume:set_background_graph_color("#00000066")
    my_volume:set_graph_color(beautiful.graph_line_color)

--}}}

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mywibox2 = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)
    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        s == 1 and mytextclock or nil,
        kbdwidget,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }

    -- BlingBling
    if s == 1 then
    mywibox2[s] = awful.wibox({ position = "bottom", screen = s, height = 22 })

      -- Add widgets to the wibox - order matters
    mywibox2[s].widgets={
	{
		separator,
		cpulabel,
-- 		cpuwidget,
-- 		separator,
		mycore1.widget,
		mycore2.widget,
		mycore3.widget,
		mycore4.widget,
-- 		separator,
		cpu.widget,
		separator,
		memlabel,
		memwidget.widget,
		separator,
		cputlabel,
-- 		cputemp,
		cput.widget,
		separator,
		gputlabel,
-- 		gputwidget,
		gput.widget,
-- 		separator,
-- 		hddtlabel,
-- 		hddtempwidget,
-- 		hddt.widget,
		separator,
		fs_my_home_label,
		fs_my_home.widget,
		separator,
		fs_media_label,
		fs_media.widget,
		separator,
-- 		fs_home_label,
-- 		fs_home.widget,
-- 		separator,
-- 		fs_root_label,
-- 		fs_root.widget,
-- 		separator,
		fs_opt_label,
		fs_opt.widget,
		separator,
		fs_usr_label,
		fs_usr.widget,
		separator,
		fs_var_label,
		fs_var.widget,
		separator,
		fs_archive_label,
		fs_archive.widget,
		separator,
-- 		fs_storage_label,
-- 		fs_storage.widget,
-- 		separator,
-- 		mpdlabel,
-- 		separator,
-- 		my_mpd_volume,
-- 		separator,
-- 		my_mpd.widget,
-- 		separator,
		layout=awful.widget.layout.horizontal.leftright
	},
		separator,
		shutdown,
		separator,
		reboot,
		separator,
		udisks_glue.widget,
-- 		separator,
-- 		mysystray,
		separator,
		my_volume.widget,
-- 		volume_label,
		separator,
		my_mpd.widget,
		separator,
		mpdlabel,
		separator,
		layout=awful.widget.layout.horizontal.rightleft
	}
    end
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "F1",     function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey }, "F4",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
--    keynumber = math.min(9, math.max(#tags[s], keynumber));
   keynumber = math.min(12, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- My keybindngs
globalkeys = awful.util.table.join(globalkeys,
    awful.key({ "Control"         }, "Escape", function () awful.util.spawn("xkill") end),
    awful.key({ modkey, "Mod1"    }, "1",     function () os.execute(kbd_dbus_sw_cmd .. "0") end),
    awful.key({ modkey, "Mod1"    }, "2",     function () os.execute(kbd_dbus_sw_cmd .. "1") end),
    awful.key({ modkey, "Mod1"    }, "3",     function () os.execute(kbd_dbus_sw_cmd .. "2") end),
    awful.key({ modkey, "Mod1"    }, "4",     function () os.execute(kbd_dbus_sw_cmd .. "3") end),
    awful.key({  "Control",  "Shift"  }, "Menu",     function () os.execute(kbd_dbus_prev_cmd) end),
    -- Scratch
    awful.key({ }, "F12", function () scratch.drop("urxvtc -pe tabbed -e screen -D -R -c /home/user/.screenrc-urxvt", "top", "center", 1, 0.37, true, 1) end),
    awful.key({ modkey, "Control" }, "F12", function () scratch.pad.toggle() end),
    -- Screen lock on Break key
    awful.key({ modkey }, "#110",    function () awful.util.spawn('/usr/lib/kde4/libexec/kscreenlocker --forcelock') end),
    -- Prompts 
    awful.key({ modkey, "Mod1"    }, "F1",     function () awful.util.spawn("dmenu_run -p 'Run:' -nb '" .. beautiful.dmenu_bg_normal .. "' -nf '" .. beautiful.dmenu_fg_normal .. "' -sb '" .. beautiful.dmenu_bg_focus .. "' -sf '" .. beautiful.dmenu_fg_focus .. "'") end),
    awful.key({ modkey ,    }, "F2", function ()
                  local s = mouse.screen
                  awful.prompt.run({ prompt = "Calc: " },
                  mypromptbox[s].widget,
                  function (expr)
                        local result = awful.util.eval("return (" .. expr .. ")")
--                         mypromptbox[s].widget.text = "Calc: " expr .. " = " .. result
                        naughty.notify({ text = expr .. " = " .. result, timeout = 10, screen = s, position = "top_left" })
                  end,
                  nil,
                  awful.util.getdir("cache") .. "/history_calc" )
    end)
--    -- Manipulating Conky window
--     awful.key({ modkey }, "F10",
-- 	function ()
-- 		conky = clnt_table["conky"]
-- 		if conky.hidden then
-- 		    conky:tags({})
-- 		    awful.client.movetoscreen(conky, mouse.screen)
-- 		    awful.tag.withcurrent(conky)
-- 		    awful.placement.centered(conky)
-- 		end
-- 		conky.hidden = not conky.hidden
-- 	end)
)

clientkeys = awful.util.table.join(clientkeys,
    awful.key({ "Mod1" }, "F4", function (c) c:kill() end),
    -- Scratch
    awful.key({ modkey, "Mod1" }, "F12", function (c) scratch.pad.set(c, 0.60, 0.60, true) end),
    -- Info
    awful.key({ modkey, "Mod1" }, "i",  function (c) show_client_infos(c) end),
    -- Opacity
    awful.key({ modkey, "Mod1" }, "o",
       function (c)
            createctable(c)
            if clienttable[c].custom_trans then
                clienttable[c].custom_trans_value = c.opacity
                c.opacity = opacity_focus
                clienttable[c].custom_trans = false
                if trans_notify then naughty.destroy(trans_notify) end
                trans_notify = naughty.notify({ title = "Transparency",
                text = "Custom transparency turned " .. colored_off,
                screen = mouse.screen })
            else
                if clienttable[c].custom_trans_value then
                     c.opacity = clienttable[c].custom_trans_value
                else
                     c.opacity = opacity_toggle
                end
                clienttable[c].custom_trans = true
                if trans_notify then naughty.destroy(trans_notify) end
                trans_notify = naughty.notify({ title = "Transparency",
                text = "Custom transparency turned " .. colored_on
                   .. " (" .. math.floor(100 - c.opacity*100) .. "%)",
                screen = mouse.screen })
            end
       end),
    awful.key({ modkey, "Shift"   }, "Left", function (c)
        local curidx = awful.tag.getidx(c:tags()[1])
        if curidx == 1 then
            c:tags({screen[mouse.screen]:tags()[9]})
        else
            c:tags({screen[mouse.screen]:tags()[curidx - 1]})
        end
    end),
    awful.key({ modkey, "Shift"   }, "Right", function (c)
        local curidx = awful.tag.getidx(c:tags()[1])
        if curidx == 9 then
            c:tags({screen[mouse.screen]:tags()[1]})
        else
            c:tags({screen[mouse.screen]:tags()[curidx + 1]})
        end
    end)
)

clientbuttons = awful.util.table.join(clientbuttons,
    awful.button({ modkey }, 4, function(c)
            if c.opacity <= 1 - opacity_step then
                c.opacity = c.opacity + opacity_step
            else
                c.opacity = 1
            end
            custom_trans_on(c)
            if trans_notify then naughty.destroy(trans_notify) end
            trans_notify = naughty.notify({ title = "Transparency",
                text = "Custom transparency set to " .. math.floor(100 - c.opacity*100) .. "%",
                screen = mouse.screen })
        end),
    awful.button({ modkey }, 5, function(c)
            if c.opacity >= opacity_step then
                c.opacity = c.opacity - opacity_step
            else
                c.opacity = 0
            end
            custom_trans_on(c)
            if trans_notify then naughty.destroy(trans_notify) end
            trans_notify = naughty.notify({ title = "Transparency",
                text = "Custom transparency set to " .. math.floor(100 - c.opacity*100) .. "%",
                screen = mouse.screen })
        end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
   { rule_any = { class = { "MPlayer", "Smplayer", "xine", "VLC" } },
      properties = { opacity = 1 },
            callback = function(c)
                  local s = mouse.screen t = 7
                  awful.client.movetotag(tags[s][t], c)
                  awful.tag.viewonly(tags[s][t])
                  custom_trans_on(c)
            end },
    { rule_any = { class = { "pinentry", "tilda", "Yakuake", "Conky", "splash", "Plasma", "Plasma-desktop", "Nepomukservicestub"  }  },
      properties = { floating = true } },
    { rule = { class = "URxvt" },
      properties = { opacity = 0.85 },
            callback = function(c)
                  custom_trans_on(c)
            end },
--    { rule = { class = "Toplevel" },
--       properties = { floating = true } },
    { rule = { class = "Stardict", name =  "StarDict starting..." },
      properties = { floating = true } },
    { rule = { class = "Dialog" },
      callback = awful.placement.centered },
    { rule = { class = "Menu" },
      callback = awful.placement.no_offscreen },
--     { rule = { class = "Balloon" },
--       callback = awful.placement.no_offscreen },
    { rule_any = { class = { "Kontact" } },
      properties = { tag = tags[1][1] } },
    { rule_any = { class = { "Tkabber", "Toplevel", "Psi-plus" } },
      properties = { tag = tags[1][2] } },
    { rule_any = { class = { "Chromium-browser", "Firefox", "Seamonkey-bin", "Konqueror", "Leechcraft", "Qupzilla", "Opera", "OperaNext" } },
      properties = { tag = tags[1][3] } },
    { rule_any = { class = { "Bilbo", "Thunderbird" } },
      properties = { tag = tags[1][4] } },
    { rule_any = { class = { "Krusader" } },
      properties = { tag = tags[1][5] } },
    { rule_any = { class = { "Ktorrent" } },
      properties = { tag = tags[1][6] } },
    { rule_any = { class = { "Gimp*" } },
      properties = { tag = tags[1][8] } },
    { rule_any = { class = { "Amarok","Deadbeef", "Pavucontrol" } },
      properties = { tag = tags[1][9] } },
    { rule_any = { class = { "VirtualBox", "VBoxSDL" } },
      properties = { tag = tags[1][10] } },
    { rule_any = { class = { "Skype" } },
      properties = { tag = tags[1][12] } }
--     { rule = { class = "Conky" },
--         properties = { floating = true, hidden = false },
--         callback = function(c)
--         clnt_table["conky"] = c end }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

-- client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
-- client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus
    -- decrease transparency
    if focus_trans and ( clienttable[c] == nil or not clienttable[c].custom_trans ) then
        c.opacity = opacity_focus
    end
end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal
    -- Increase transparency
    if focus_trans and ( clienttable[c] == nil or not clienttable[c].custom_trans ) then
        c.opacity = opacity_normal
    end
end)

-- }}}

-- Run autostart applications
autostart(autostart_dir)
