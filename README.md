PORTZ - local port system
===================

Well, next tool like mingw-port, homebrew, easy_install, macportz, FreeBSD portz. That is just tailored to my needs:

 - works on MSys/Mingw32, Linux, OSX and FreeBSD
 - is designed to target private trees ($HOME/usr, $HOME/project-sdk etc)
 - have ports for packages i use :)
 - supports basic cross compilation env (work in progress)

It's dirty hack allowing to automagically install developer 
soft on windows machines just like FreeBSD ports do or apt 
on Debian.

It's aimed for developers.


Author:
Zbigniew Zagorski <z.zagorski@gmail.com>

Prerequisite
------------

You need to have bashfoo inside portz

    git clone https://github.com/zbigg/bashfoo.git

How to use
----------

Easy install sample usage:

    prefix=$HOME/foo portz easy_install name=wget http://ftp.gnu.org/gnu/wget/wget-1.13.tar.xz
 
Installs:

    /home/zbigg/foo/lib/portz/wget.MANIFEST
    /home/zbigg/foo/lib/portz/wget.PKGINFO 
    (...)
    /home/zbigg/foo/share/locale/be/LC_MESSAGES/wget.mo
    (...)
    ./home/zbigg/foo/share/locale/pt_BR/LC_MESSAGES/wget.mo
    (...)
    /home/zbigg/foo/share/man/man1/wget.1
    /home/zbigg/foo/share/info/wget.info
    /home/zbigg/foo/share/info/dir
    /home/zbigg/foo/etc/wgetrc
    /home/zbigg/foo/bin/wget

Prepared packages usage:

    portz install pcre
    
See `repo/pcre.portz` for package definition.

Supported parameters, passed via environment:

 - `prefix`      - prefix for noarch files
 - `exec_prefix` - prefix for arch specific files, eg. binaries
 - `arch`        - autoconf style arch name (`x86_64-unknown-linux-gnu`, `i586-mingw32msvc`)

See `portz --help` for all featured commands.

Options
-------------

If environment variable `PORTZ_SEPARATE_EXEC` is equal to 1 then
portz will automagically differentiate exec prefix for installed packages. It will be:

    ${prefix}/platforms/$(uname -m)

which will result in:

    ${prefix}/platforms/{i686|x86_64|sun4u}

or something (setting arch, implictly enables `PORTZ_SEPARATE_EXEC`).

SITE DEFAULTS
-------------

If one wishes to have whole "site" of software compiled in particular way, then <site>
feature can be used.

When portz script is executed with `site=DIR` variable set, then
it reads defaults from `$site/.portz.conf`. This file can/should contains defaults
like specification of compiler, compilation flags etc.

`site=DIR` implies following:

 - inclusion of `$site/bin` in `$PATH` (not in cross-compilation mode)
 - inclusion of `$site/lib` in `$LD_LIBRARY_PATH` (not in cross-compilation)
 - inclusion of `$site/lib` in `$LIBRARY_PATH`
 - ... `$site/include` in `C_INCLUDE_PATH` and `CPLUS_INCLUDE_PATH`
 - ... `$site/lib/pkgconfig` in `PKG_CONFIG_PATH`
 - ... `$site/lib/pythhon{X.Y}/site-packages` in `PYTHON_PATH`

Example, site for cross-compilation to mingw32:

    ~/site/mingw32 $ cat .portz.conf
    CC=i586-mingw32msvc-cc
    CXX=i586-mingw32msvc-c++
	
    arch=i586-mingw32msvc

Usage:

    $ site=/home/zbigg/site/mingw32 portz install pcre
    portz_install pcre: prefix      = /home/zbigg/site/mingw32
    portz_install pcre: exec_prefix = /home/zbigg/site/mingw32
    (...)
    portz_install pcre: [!] ./configure --prefix=/home/zbigg/site/mingw32 --exec-prefix=/home/zbigg/site/mingw32 --host=i586-mingw32msvc --enable-utf8 --disable-cpp
    configure: WARNING: if you wanted to set the --build type, don't use --host.
        If a cross compiler is detected then cross compile mode will be used
    checking for a BSD-compatible install... /usr/bin/install -c
    checking whether build environment is sane... yes
    checking for i586-mingw32msvc-strip... i586-mingw32msvc-strip
    (...) -- installed files
    ./home/zbigg/site/mingw32/include/pcreposix.h
    ./home/zbigg/site/mingw32/bin/
    ./home/zbigg/site/mingw32/bin/pcretest.exe
    ./home/zbigg/site/mingw32/bin/pcre-config
    ./home/zbigg/site/mingw32/bin/pcregrep.exe
    $

Package file format
-------------------

Currently package file format is just a shell script with some key
variable settings.

Canonical example:

    # repo/pcre.portz
    version=8.31
    baseurl=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${version}.tar.bz2
    web=http://www.pcre.org/
    configure_options="--enable-utf8 --enable-unicode-properties"
    stereotype="gnu"

It described pcre (http://pcre.org) in version 8.31 and download URL. It tells
also that it's a `gnu` type of package, so portz will expect canonical
`configure & make & make install DESTDIR=tmp_staging_folder` working.

(GNU Sterotype is autodetected if configure & Makefile.in exists, so stereotype
 settings is redundant here)

So, basically portz supports out-of-the-box following "steretypes":

 - gnu (configure & make packages)
 - python (featuring distutils compatible setup.py)

Portz can fetch source from using:

 - `baseurl`, it just fetched tgz,tbz2,zip etc
   (if `sha1sum` is defined, then downloaded file is checked for integrity/authenticity)
 - svn url & revision
 - monotone url & revision
 - git url and & ref

Definitions:

* downloaded packages

  * `baseurl` -> from where wget or curl shall fetch source package
  * `sha1sum` -> expected sha1sum of downloaded package
  
* sources from svn:
  
  * `svn_path` - SVN url
  * `revision` - optional, HEAD is the default

* sources from monotone:

  * `mtn_url` - monotone database pull URL
  * `revision` - mandatory, a monotone selector: h:branch, t:tag, HASH

* sources from git:

  * `git_url` - specifies from where we shall pull changes; by default
    whole repo is cloned
  * `git_ref` is used for this (`git_tag` has precedence)
  * `git_tag` specifies what tag shall be cheked out; optionally
  * `git_fetch_options` are passed to fetch command

Package Examples
--------

Some examples below ...

### Archive based ###

Git build easily with with defaults:

    version=1.8.0.1
    baseurl=http://git-core.googlecode.com/files/git-${version}.tar.gz
    web=http://code.google.com/p/git-core/

### Git based ###

Following package file (`repo/tinfra.portz`):

    git_url=https://github.com/zbigg/tinfra.git
    git_tag=foo-1.2.3
    git_ref=master
   
Clones https://github.com/zbigg/tinfra.git and checkouts tag `foo-1.2.3`.
Then, usual build occurs.

Cross compilation
--------

Install i386-libs/headers of expat x86_64 linux:

    arch=i386-unknown-linux-gnu prefix=$HOME/s2 portz install expat
        
installs:

    /home/zbigg/s2/include/expat.h
    /home/zbigg/s2/include/expat_external.h
    (...)
    /home/zbigg/s2/platforms/i386-unknown-linux-gnu/lib/libexpat.so
    /home/zbigg/s2/platforms/i386-unknown-linux-gnu/lib/libexpat.so.1
    /home/zbigg/s2/platforms/i386-unknown-linux-gnu/lib/libexpat.a
    (...)
    /home/zbigg/s2/platforms/i386-unknown-linux-gnu/bin/xmlwf

Same works with `portz easy_install`, i386-tinfra installed on x86_64 linux:
    
    arch=i386-unknown-linux-gnu prefix=$HOME/s2 portz easy_install \
        name=tinfra http://idf.hotpo.pl/index.php/p/tinfra/downloads/get/tinfra-dev-0.0.2.zip

Real cross compilation, also works (tested @Linux, build for mingw32), (REQUIRES 
mingw32 installed, i.e i586-mingw32msvc-gcc and friends):
    
    $ arch=i586-mingw32msvc prefix=$HOME/s2 portz install expat
    (...)
    portz_install expat: [!] ./configure --prefix=/home/zbigg/s2 --exec-prefix=/home/zbigg/s2/platforms/i586-mingw32msvc --host=i586-mingw32msvc
        configure: WARNING: If you wanted to set the --build type, don't use --host.
    If a cross compiler is detected then cross compile mode will be used.
    checking build system type... x86_64-unknown-linux-gnu
    checking host system type... i586-pc-mingw32msvc
    (...)
    portz_install expat: [!] make
    /bin/bash ./libtool --silent --mode=compile i586-mingw32msvc-cc -I./lib -I. -g -O2  -Wall -Wmissing-prototypes -Wstrict-prototypes -fexceptions  -DHAVE_EXPAT_CONFIG_H -o lib/xmlparse.lo -c lib/xmlparse.c
    /bin/bash ./libtool --silent --mode=compile i586-mingw32msvc-cc -I./lib -I. -g -O2  -Wall -Wmissing-prototypes -Wstrict-prototypes -fexceptions  -DHAVE_EXPAT_CONFIG_H -o lib/xmltok.lo -c lib/xmltok.c
    (...)
    /home/zbigg/s2/platforms/i586-mingw32msvc/lib/libexpat.dll.a
    /home/zbigg/s2/platforms/i586-mingw32msvc/lib/libexpat.a
    /home/zbigg/s2/platforms/i586-mingw32msvc/lib/portz/expat.MANIFEST
    /home/zbigg/s2/platforms/i586-mingw32msvc/bin/xmlwf
    /home/zbigg/s2/platforms/i586-mingw32msvc/bin/libexpat-1.dll
    
    $ file /home/zbigg/s2/platforms/i586-mingw32msvc/bin/libexpat-1.dll
    /home/zbigg/s2/platforms/i586-mingw32msvc/bin/libexpat-1.dll: PE32 executable for MS Windows (DLL) (console) Intel 80386 32-bit
    
    $ file /home/zbigg/s2/platforms/i586-mingw32msvc/bin/xmlwf
    /home/zbigg/s2/platforms/i586-mingw32msvc/bin/xmlwf: PE32 executable for MS Windows (console) Intel 80386 32-bit
    
    $ wine /home/zbigg/s2/platforms/i586-mingw32msvc/bin/xmlwf -h
    usage: Z:\home\zbigg\s2\platforms\i586-mingw32msvc\bin\xmlwf [-n] [-p] [-r] [-s] [-w] [-x] [-d output-dir] [-e encoding] file ...


