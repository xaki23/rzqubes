# rzqubes
Qubed SelfAdmins
 
## tl;dr
 * desktop compartmentalization
 * "browser far from agent"
 * usable linux desktop
 * goal to make selfadmin migration about as complicated as moving
   desktop to any other unfamiliar desktop oriented linux flavor


## hardware
### minimum
 * 2core, 8GB, 50GB+
 * basicly any NUC will do
### recommended
 * 4core, 16GB, vt-x, ssd
 * maxed NUC
### nicetohave
 * 4core, 32GB, vt-[dx], tpm, 2+ ssd, nvme, 2+ usb controller
 * supernuc or deskmini 110 
### basicly anything semirecent will do
### vt-d
 * strongly recommended, but can be used without
 * requires ignoring some errors and switching
    all vms with hardware access to less-secure
    pv mode virtualization
 * default hw vms: sys-net sys-usb

## installation

-- download
--- verification (of download)
-- bootmedium
--- anything 5gb+
--- just dd to usb
--- verification (of copy)

-- boot installer (basicly fedora anaconda)
-- optional ignore no-vt-d warning
-- pick timezone / language / kbdlayout
-- optional uncheck whonix installation (old version, but you can also just install and delete it later...)
-- partitioning
--- reasonable defaults, just pick a physdev and lukspw
--- optional shrink root
--- optional raid setup
-- start install
-- pick your dom0 username ("admin") and pw (used for login/unlock)
-- wait a longish time


- first boot

-- Q menu top-left
--- terminal emulator
--- system tools -> qube manager

-- optional no-vt-d workaround
--- ignore error about sys-net start
--- start dom0 terminal
---- dom0$ qvm-prefs sys-net virt_mode pv
---- dom0$ qvm-start sys-net
--- or start qube manager and click around

-- install templates
--- dom0$ sudo qubes-dom0-update --clean qubes-template-fedora-28
--- very optional templates
---- dom0$ sudo qubes-dom0-update --clean --enablerepo=qubes-templates-community-testing qubes-template-centos-7
---- dom0$ sudo qubes-dom0-update --clean --enablerepo=qubes-templates-itl-testing qubes-template-fedora-29

-- update all templates (even the ones you just installed)
--- optional dom0$ qvm-prefs template-XY maxmem 1000 
---- can easily update all templates in parallel

--- qube manager: rightclick (fedora-X, debian-Y) templates - update qube
--- or dom0$ qvm-run --service template-XY qubes.InstallUpdatesGUI

--- optional dom0$ qvm-run --user root -p template-XY "fstrim -av"
---- just needed once after install and update to get rid of pkg-blockdevice-import-crud
---- run it after updates completed, before shutting down the template


-- update dom0
--- dom0$ sudo qubes-dom0-update --clean


-- when you are done updating (and no longer need network)
-- apply new template
--- dom0$ qubes-prefs default_template fedora-28
--- shutdown all running appvms (except dom0)
--- switch the appvms template to fedora-28 in qubes manager (and adjust memory limits as needed, see recommendations below)
--- or use qvm-prefs in dom0

-- reboot


- second boot

-- create usb-qube
--- dom0$ sudo qubesctl state.sls qvm.sys-usb
--- dom0$ sudo qubesctl state.sls qvm.usb-keyboard
--- optional and "less secure", but easier recovery if you dont have easy access to non-usb kbd/mouse
---- dom0$ qvm-prefs sys-usb autostart False
---- this means you need to manually start sys-usb after each boot
--- optional no-vtd-d: dom0$ qvm-prefs sys-usb virt_mode pv
--- without ps2 or nonusb notebook keyboard you have one chance to get this right
--- dom0$ qvm-start sys-usb

-- optional restore backup
-- optional mirage fw + agent
-- optional aem/fde/mfa
--- dom0$ qvm-create -l purple -t debian-9 build-mirage-deb9
--- dom0$ qvm-run build-mirage gnome-terminal &
---- sudo sh mirage.sh

-- optional import old desktop
--- create an import/legacy appvm, attach old FS, copy over home/data as needed
--- you can basicly keep working "as is" out of that appvm
--- move out parts of your workflow to other vms at your own pace


- general orientation

-- things to try in a dom0 console:
--- qvm-ls, qvm-prefs, qvm-start, qvm-shutdown, qvm-kill, xentop, xl list, xl console 

-- qubes manager
--- default vms
---- services
----- sys-net
----- sys-firewall
----- sys-usb
---- templates
----- debian + fedora
---- untrusted

-- vm creation/clone/destroy
--- easy/quick enough to "just do it"
-- cut-n-paste
--- like regular c-n-p with an additional shift-ctrl-c / shift-ctrl-v step for copying between vm-cnp-buffer and inter-vm-cnp-buffer
-- vm disk layout
--- root
---- inherited from template (writeable snapshot at boot)
--- private
---- mounted on /rw, contains /home and /usr/local
--- volatile
---- swap and writeable root scratchspace
---- discarded on each appvm start
---- in default configuration 9GB free for additional swap or tmpfs


-- scaling
--- browser vm 2GB-4GB ram
--- ssh vm 500MB-1GB ram
--- hvm vm +150MB ram +10% cpu fuer stub
--- services linux 500MB-1GB ram
--- services mirage 20MB-40MB ram
--- template 10GB disk

-- virt modes
--- pv == software virtualization (less secure)
---- requires guest os with pv support
---- do not use
----- exceptions no-vt-d and special guests (mirage,bsd)
--- pvh == hardware virtualized memory with software drivers
---- requires cpu vt-x/SLAT support
---- requires guest os with pvh support
---- best+default for non-hardware vms
--- hvm == full hardware virtualization
---- usecase exotic guests (no xen support required)
---- usecase vms with delegated hardware (net, usb)
----- requires system with vt-d/IOMMU support 
---- will use a pv-mode stub domain to run qemu
----- adds 150M mem and 10% cpu to requirements
----- adds qemu/pv attack surface



- qubes layout

-- scopes like work, priv, build, onenetwork
--- per scope colors: on orange, work blue, priv yellow, build pink ... 
-- subname according to function

--- work-agent
---- not network connected
--- work-ssh
--- work-mail
---- optional mua/mta separation
--- work-browser
---- optional int/ext separation
--- work-vault
---- not network connected

--- on-tun
--- on-ssh
---- optional on-agent
--- on-browser
--- on-rdp

--- srv-cups

--- build-qubes (feodra templated)
--- build-mirage (debian templated)
--- build-solaris
---- can basicly run anything in hvm mode

--- priv
---- optional agent/ssh/browser separation like for work-*

--- untrusted
---- general browser and traceroute/dig usage




- advanced
-- dvms
-- split ssh
-- split gpg
-- split usb
-- storage pools
--- discard
--- nvme
---- usecase template
---- usecase volatile


- todo
-- common rc.local
-- whonix/tor evaluation
--

- standard problems
-- crashed netvm
-- ipc limits
-- lvm_thin





