dnl SYNOPSIS: OPTION_APPEND
dnl EXAMPLE: none. used internally by OPTION_DEFAULT_ENABLE and friends
dnl note: provides a shell function that appends to var a value.
dnl redundant with as_fn_append as of autoconf 2.68, but earlier versions lack.
AC_DEFUN([OPTION_APPEND],[
# option_fn_append varname value
option_fn_append ()
  {
    eval $[]1=\$$[]1\$[]2
  }
])
dnl SYNOPSIS: OPTION_DEFAULT_ENABLE([name], [enable_flag_var])
dnl EXAMPLE: OPTION_DEFAULT_ENABLE([mysql], [ENABLE_MYSQL])
dnl note: supports hyphenated feature names now.
AC_DEFUN([OPTION_DEFAULT_ENABLE], [
AC_REQUIRE([OPTION_APPEND])
AC_ARG_ENABLE($1, [  --disable-$1     Disable the $1 module],
        [       if test "x$enableval" = "xno" ; then
                        disable_]m4_translit([$1], [-+.], [___])[=yes
                        enable_]m4_translit([$1], [-+.], [___])[=no
			AC_MSG_NOTICE([Disable $1 module requested ])
			option_fn_append ac_configure_args " '--disable-]m4_translit([$1], [-+.], [___])['"
		else
                        enable_]m4_translit([$1], [-+.], [___])[=yes
                        disable_]m4_translit([$1], [-+.], [___])[=no
			option_fn_append ac_configure_args " '--enable-]m4_translit([$1], [-+.], [___])['"
                fi
        ], [ AC_MSG_NOTICE([Disable $1 module NOT requested])
		enable_]m4_translit([$1], [-+.], [___])[=yes
		disable_]m4_translit([$1], [-+.], [___])[=no
		option_fn_append ac_configure_args " '--enable-]m4_translit([$1], [-+.], [___])['"
	])
AM_CONDITIONAL([$2], [test "$disable_]m4_translit([$1], [-+.], [___])[" != "yes"])
])

dnl SYNOPSIS: OPTION_DEFAULT_DISABLE([name], [enable_flag_var])
dnl EXAMPLE: OPTION_DEFAULT_DISABLE([mysql], [ENABLE_MYSQL])
dnl note: supports hyphenated feature names now.
AC_DEFUN([OPTION_DEFAULT_DISABLE], [
AC_REQUIRE([OPTION_APPEND])
AC_ARG_ENABLE($1, [  --enable-$1     Enable the $1 module: $3],
        [       if test "x$enableval" = "xyes" ; then
                        enable_]m4_translit([$1], [-+.], [___])[=yes
                        disable_]m4_translit([$1], [-+.], [___])[=no
			AC_MSG_NOTICE([Enable $1 module requested])
			option_fn_append ac_configure_args " '--enable-]m4_translit([$1], [-+.], [___])['"
		else
                        disable_]m4_translit([$1], [-+.], [___])[=yes
                        enable_]m4_translit([$1], [-+.], [___])[=no
			option_fn_append ac_configure_args " '--disable-]m4_translit([$1], [-+.], [___])['"
                fi
        ], [ AC_MSG_NOTICE([Enable $1 module NOT requested])
		disable_]m4_translit([$1], [-+.], [___])[=yes
		enable_]m4_translit([$1], [-+.], [___])[=no
		option_fn_append ac_configure_args " '--disable-]m4_translit([$1], [-+.], [___])['"
	])
AM_CONDITIONAL([$2], [test "$enable_]m4_translit([$1], [-+.], [___])[" == "yes"])
])

dnl SYNOPSIS: OPTION_WITH([name], [VAR_BASE_NAME])
dnl EXAMPLE: OPTION_WITH([xyz], [XYZ])
dnl NOTE: With VAR_BASE_NAME being XYZ, this macro will set XYZ_INCIDR and
dnl 	XYZ_LIBDIR to the include path and library path respectively.
AC_DEFUN([OPTION_WITH], [
dnl reset withval, or prior option_with uses bleed in here.
withval=""
AC_ARG_WITH(
	$1,
	[AS_HELP_STRING(
		[--with-$1@<:@=path@:>@],
		[Specify $1 path @<:@default=$3@:>@])]
	,
	[WITH_$2=$withval
		HAVE_$2=yes
	],
	[WITH_$2=$3]
)

case "x$withval" in
xyes | x/usr | x)
	:
	;;
*)
	if test "$enable_]m4_translit([$1], [-+.], [___])[" = "yes"; then
		AC_MSG_NOTICE([$WITH_$2 from $withval ])
	fi
	if test -d $WITH_$2/lib; then
		$2_LIBDIR=$WITH_$2/lib
		$2_LIBDIR_FLAG="-L$WITH_$2/lib"
		LDFLAGS="$LDFLAGS -Wl,-rpath-link=$WITH_$2/lib"
	fi
	havelibdir=""
	havelib64dir=""
	if test "x$2_LIBDIR" = "x"; then
		havelibdir="yes"
		$2_LIBDIR=$WITH_$2/lib64
		$2_LIBDIR_FLAG=-L$WITH_$2/lib64
		LDFLAGS="$LDFLAGS -Wl,-rpath-link=$WITH_$2/lib64"
	fi
	if test -d $WITH_$2/lib64; then
		havelib64dir="yes"
		$2_LIB64DIR=$WITH_$2/lib64
		$2_LIB64DIR_FLAG="-L$WITH_$2/lib64"
		LDFLAGS="$LDFLAGS -Wl,-rpath-link=$WITH_$2/lib64"
	fi
	if test -d $WITH_$2/include; then
		$2_INCDIR=$WITH_$2/include
		$2_INCDIR_FLAG=-I$WITH_$2/include
	fi
	if test -n "$havelibdir" -a -n "$havelib64dir"; then
		AC_MSG_NOTICE([For $2 both lib and lib64 exist. Expect the unexpected.])
	fi
	;;
esac

AC_SUBST([$2_LIBDIR], [$$2_LIBDIR])
AC_SUBST([$2_LIB64DIR], [$$2_LIB64DIR])
AC_SUBST([$2_INCDIR], [$$2_INCDIR])
AC_SUBST([$2_LIBDIR_FLAG], [$$2_LIBDIR_FLAG])
AC_SUBST([$2_LIB64DIR_FLAG], [$$2_LIB64DIR_FLAG])
AC_SUBST([$2_INCDIR_FLAG], [$$2_INCDIR_FLAG])
])

dnl SYNOPSIS: OPTION_WITH_PORT([name])
dnl EXAMPLE: OPTION_WITH_PORT([XYZ],[411])
dnl sets default value of XYZPORT, using second argument as value if not given
AC_DEFUN([OPTION_WITH_PORT], [
AC_ARG_WITH(
	$1PORT,
	AS_HELP_STRING(
		[--with-$1PORT@<:@=NNN@:>@],
		[Specify $1 runtime default port @<:@default=$2@:>@]
	),
	[$1PORT=$withval],
	[$1PORT=$2; withval=$2]
)
$1PORT=$withval
if printf "%d" "$withval" >/dev/null 2>&1; then
	:
else
	AC_MSG_ERROR([--with-$1PORT given non-integer input $withval])
fi
AC_DEFINE_UNQUOTED([$1PORT],[$withval],[Default port for $1 to listen on])
AC_SUBST([$1PORT],[$$1PORT])
])

dnl SYNOPSIS: OPTION_WITH_OR_BUILD(featurename,reldir,libsubdirs,
dnl		configfile,package_name,buildlocation)
dnl REASON: configuring against peer subprojects needs a little love.
dnl ERGONOMICS: hyphenated feature-names are allowed.
dnl EXAMPLE: OPTION_WITH_OR_BUILD([lib],[../lib/src],[])
dnl NOTE: With featurename being sos, this macro will set SOS_INCDIR and
dnl 	SOS_LIBDIR to the include path and library path respectively.
dnl N.B.: avoid any extra space (including CR/LF) in argument list.
dnl
dnl If user specifies --with-FEATURE=/path, path should be the prefix
dnl of a prior install of FEATURE.
dnl
dnl If user does not specify prefix of a prior INSTALL or specifies
dnl --with-FEATURE=build, then the dnl source tree at relative location
dnl $srcdir/$reldir will be used and
dnl the corresponding object tree must already have been configured
dnl at location $reldir.
dnl
dnl The list of libsubdirs (relative to $reldir) will be added to the
dnl link search paths.
dnl The list of libsubdirs (relative to $srcdir/$reldir) and $reldir
dnl will be added to the include search paths so headers and generated
dnl headers will be found.
dnl
dnl The named configfile (an sh fragment for sharing configure info)
dnl will be (if present) loaded from:
dnl -- libdir/package_name/configfile (if --with-FEATURE=/path used)
dnl or
dnl -- buildlocation/configfile (if --with-FEATURE=build used)
dnl Missing configfiles are silently ignored.
dnl If there's nothing to share, use 'dummy' as the configfile.
dnl This configfile approach works without a full install of pkg-config data.
dnl
dnl SYNOPSIS: OPTION_WITH_OR_BUILD(featurename,reldir,libsubdirs,
dnl		configfile,package_name,buildlocation)
dnl argument catalog:
dnl - featurename: variable prefix
dnl - reldir: relative location of in-tree build and sources
dnl - libsubdirs: search locations, relative to reldir, for lib,header.
dnl - configfile: name of sh vars file to load
dnl - package_name: subdir of installed libdir for preinstalled featurename
dnl - buildlocation: build location relative to reldir of configfile
dnl
AC_DEFUN([OPTION_WITH_OR_BUILD], [
AC_ARG_WITH(
	$1,
	AS_HELP_STRING(
		[--with-$1@<:@=path@:>@],
		[Specify $1 path @<:@default=in build tree@:>@]
	),
	[WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[=$withval
	 AM_CONDITIONAL([ENABLE_]m4_translit([$1], [-+.a-z], [___A-Z])[], [true])
	],
	[WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[=build]
)

[if test "x$WITH_]m4_translit([$1], [-a-z], [_A-Z])[" != "xbuild"; then
	case "x$WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[" in
	x | xyes | x/usr)
		:
		;;
	*)
		if test -d $WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/lib; then
			_DIR=$WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/lib
			LDFLAGS="$LDFLAGS -Wl,-rpath-link=$_DIR"
			]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR="$_DIR"
			]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR_FLAG="-L$_DIR"
		fi
		if test "x$]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR" = "x"; then
			_DIR=$WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/lib64
			LDFLAGS="$LDFLAGS -Wl,-rpath-link=$_DIR"
			]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR="$_DIR"
			]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR_FLAG="-L$_DIR"
		fi
		if test -d $WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/lib64; then
			_DIR=$WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/lib64
			LDFLAGS="$LDFLAGS -Wl,-rpath-link=$_DIR"
			]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR="$_DIR"
			]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR_FLAG="-L$_DIR"
		fi
		if test -d $WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/include; then
			]m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIRS=$WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/include
			]m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIR_FLAG=-I$WITH_]m4_translit([$1], [-+.a-z], [___A-Z])[/include
		fi
		if test -f $]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR/$5/$4; then
			. $]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR/$5/$4
		fi
		if test -f $]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR/$5/$4; then
			. $]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR/$5/$4
		fi
		;;
	esac
else
	# builddir of prior package should exist by our configure time
	tmpflaginc=""
	tmpflag=""
	if test "$enable_]m4_translit([$1], [-+.], [___])[" = "yes"; then
		tmpsrcdir=`(cd $srcdir/$2 && pwd)`
		dirlist=""
		if test -n "$3"; then
			for dirtmp in $3 . ; do
				if test -d $2/$dirtmp; then
					tmpbuilddir=`(cd $2/$dirtmp && pwd)` && \
					tmpflag="$tmpflag -L$tmpbuilddir" && \
					dirlist="$dirlist $tmpbuilddir"
				else
					]AC_MSG_NOTICE([expected build dir $2/$dirtmp missing])[
					tmpbuilddir=""
				fi
				tmpflaginc="-I$tmpsrcdir/$dirtmp -I$tmpbuilddir $tmpflaginc"
			done
			# no -L without args allowed.
			# no -I without args allowed.
			if test -d $2 ; then
				tmpbuilddir=`(cd $2 && pwd)`
			else
				]AC_MSG_ERROR([Specify --with-$1 or build all from top])[
				tmpbuilddir=""
			fi
		else
			if test -d $2 ; then
				tmpbuilddir=`(cd $2 && pwd)`
			else
				]AC_MSG_ERROR([Specify --with-$1 or build all from top])[
				tmpbuilddir=""
			fi
			tmpflag="-L$tmpbuilddir"
			tmpflaginc="-I$tmpbuilddir -I$tmpsrcdir"
		fi
	]AC_MSG_NOTICE([tmpflag="$tmpflag"])[
	]AC_MSG_NOTICE([tmpflaginc="$tmpflag"])[
		tmpflag=`echo $tmpflag | sed -e 's%-L %%g' -e 's%-L$%%g'`
		tmpflaginc=`echo $tmpflaginc | sed -e 's%-I %%g' -e 's%-I$%%g'`
		]m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIRS="$tmpsrcdir $tmpbuilddir $dirlist"
		]m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIR_FLAG="$tmpflaginc"
		]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR="$dirlist"
		]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR_FLAG="$tmpflag"
		]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR_FLAG=""
		]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR=""
		if test -n "$4"; then
			if test -f $tmpbuilddir/$6/$4; then
				. $tmpbuilddir/$6/$4
			fi
		fi
	fi
fi
]
AC_SUBST(m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR], [$]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR])
AC_SUBST(m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR], [$]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR])
AC_SUBST(m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIR], [$]m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIRS])
AC_SUBST(m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR_FLAG], [$]m4_translit([$1], [-+.a-z], [___A-Z])[_LIBDIR_FLAG])
AC_SUBST(m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR_FLAG], [$]m4_translit([$1], [-+.a-z], [___A-Z])[_LIB64DIR_FLAG])
AC_SUBST(m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIR_FLAG], [$]m4_translit([$1], [-+.a-z], [___A-Z])[_INCDIR_FLAG])

])

dnl Similar to OPTION_WITH, but a specific case for MYSQL
AC_DEFUN([OPTION_WITH_MYSQL], [
AC_ARG_WITH(
	[mysql],
	AS_HELP_STRING(
		[--with-mysql@<:@=path@:>@],
		[Specify mysql path @<:@default=/usr/local@:>@]
	),
	[	dnl $withval is given.
		WITH_MYSQL=$withval
		mysql_config=$WITH_MYSQL/bin/mysql_config
	],
	[	dnl $withval is not given.
		mysql_config=`which mysql_config`
	]
)

if test $mysql_config
then
	MYSQL_LIBS=`$mysql_config --libs`
	MYSQL_INCLUDE=`$mysql_config --include`
else
	AC_MSG_ERROR([Cannot find mysql_config, please specify
			--with-mysql option.])
fi
AC_SUBST([MYSQL_LIBS])
AC_SUBST([MYSQL_INCLUDE])
])
dnl this could probably be generalized for handling lib64,lib python-binding issues
AC_DEFUN([OPTION_WITH_EVENT],[
  AC_ARG_WITH([libevent],
dnl  [  --with-libevent=DIR      use libevent in DIR],
  [],
  [ case "$withval" in
    yes|no)
      AC_MSG_RESULT(no)
      ;;
    *)
      if test "x$withval" != "x/usr"; then
        dnl CPPFLAGS="-I$withval/include"
	if test -f $withval/lib/libevent.so; then
	  libeventpath=$withval/lib
          EVENTLIBS="-L$withval/lib"
        fi
	if test -f $withval/lib64/libevent.so; then
          EVENTLIBS="$EVENTLIBS -L$withval/lib64"
	  libeventpath=$withval/lib64:$libeventpath
        fi
      fi
      ;;
    esac ])
  option_old_libs=$LIBS
  AC_CHECK_LIB(event, event_base_new, [EVENTLIBS="$EVENTLIBS -levent -levent_pthreads"],
      AC_MSG_ERROR([event_base_new() not found. sock requires libevent.]),[$EVENTLIBS])
  AC_SUBST(EVENTLIBS)
  AC_SUBST(libeventpath)
  [EVENTINC="FIXME EVENTINC should be replaced with LIBEVENT_INCDIR_FLAG"]
  AC_SUBST(EVENTINC)  dnl remove eventinc and subst when update complete
  LIBS=$option_old_libs
])


dnl SYNOPSIS: OPTION_WITH_MAGIC([name],[default_integer],[description])
dnl EXAMPLE: OPTION_WITH_MAGIC([XYZPORT],[411],[default xyz port])
dnl sets default value of magic number XYZ for make and headers,
dnl using second argument as default if not given by user
dnl and description.
dnl Good for getting default sizes and ports at config time
AC_DEFUN([OPTION_WITH_MAGIC], [
AC_ARG_WITH(
        $1,
        AS_HELP_STRING(
                [--with-$1@<:@=NNN@:>@],
                [Specify $1 $3 @<:@default=$2@:>@]
        ),
        [$1=$withval],
        [$1=$2; withval=$2]
)
$1=$withval
if printf "%d" "$withval" >/dev/null 2>&1; then
        :
else
        AC_MSG_ERROR([--with-$1 given non-integer input $withval])
fi
AC_DEFINE_UNQUOTED([$1],[$withval],[$3])
AC_SUBST([$1],[$$1])
])

dnl SYNOPSIS: OPTION_GITINFO
dnl dnl queries git for version hash and branch info.
AC_DEFUN([OPTION_GITINFO], [

	TOP_LEVEL="$(git rev-parse --show-toplevel 2>/dev/null)"
	GITSHORT="$(git describe --tags 2>/dev/null)"
	GITLONG="$(git rev-parse HEAD 2>/dev/null)"
	GITDIRTY="$(git status -uno -s 2>/dev/null)"
	if test -n "$GITLONG" -a -n "$GITDIRTY"; then
		GITLONG="${GITLONG}-dirty"
	fi

	if test -s "$TOP_LEVEL/m4/Ovis-top.m4" -a -n "$GITLONG"; then
		dnl Git OK from ovis repo.
		AC_MSG_RESULT([Using git SHA and TAG])
	elif test -s $srcdir/TAG.txt -a -s $srcdir/SHA.txt ; then
		dnl Git not OK, try $srcdir/SHA.txt
		AC_MSG_NOTICE([Using SHA.txt and TAG.txt from $srcdir for version info. ])
		GITSHORT="$( cat $srcdir/TAG.txt)"
		GITLONG="$( cat $srcdir/SHA.txt)"
		AC_MSG_RESULT([Using local SHA.txt and TAG.txt])
	elif test -s $srcdir/../Ovis-top.m4 -a -s $srcdir/../TAG.txt -a -s $srcdir/../SHA.txt ; then
		dnl try top-level SHA.txt
		AC_MSG_NOTICE([Using SHA.txt and TAG.txt from $srcdir for version info. ])
		GITSHORT="$( cat $srcdir/../TAG.txt)"
		GITLONG="$( cat $srcdir/../SHA.txt)"
		AC_MSG_RESULT([Using tree-top SHA.txt and TAG.txt])
	else
		GITSHORT="NO_GIT_SHA"
		GITLONG=$GITSHORT
		AC_MSG_RESULT([NO GIT SHA])
	fi

AC_DEFINE_UNQUOTED([OVIS_GIT_LONG],["$GITLONG"],[Hash of last git commit])
AC_DEFINE_UNQUOTED([OVIS_GIT_SHORT],["$GITSHORT"],[Branch and hash mangle of last commit])
AC_SUBST([OVIS_GIT_LONG], ["$GITLONG"])
AC_SUBST([OVIS_GIT_SHORT], ["$GITSHORT"])
])

dnl SYNOPSIS: OVIS_PKGLIBDIR
dnl defines automake pkglibdir value for configure output
dnl and enables gcc color
AC_DEFUN([OVIS_PKGLIBDIR], [
AC_ARG_WITH(pkglibdir,
[AS_HELP_STRING([--with-pkglibdir],
	[specify subdirectory of libdir where plugin libraries shall be.])],
	[AC_SUBST([pkglibdir],['${libdir}'/$withval])
	 AC_MSG_NOTICE([Using plugin directory $withval])
	],
	[AC_SUBST([pkglibdir],['${libdir}'/$PACKAGE])
	 AC_MSG_NOTICE([Using plugin directory $PACKAGE])
	])
AX_CHECK_COMPILE_FLAG([-fdiagnostics-color=auto], [
CFLAGS="$CFLAGS -fdiagnostics-color=auto"
])
])

dnl SYNOPSIS: OPTION_HOSTINFO
dnl build environment description
AC_DEFUN([OPTION_HOSTINFO], [
AC_CANONICAL_HOST
AC_CANONICAL_BUILD
LDMS_COMPILE_HOST_NAME=$ac_hostname
LDMS_COMPILE_HOST_CPU=$host_cpu
LDMS_COMPILE_HOST_OS=$host_os
AC_DEFINE_UNQUOTED([LDMS_COMPILE_HOST_NAME],["$LDMS_COMPILE_HOST_NAME"],[host where configured])
AC_DEFINE_UNQUOTED([LDMS_COMPILE_HOST_CPU],["$LDMS_COMPILE_HOST_CPU"],[cpu where configured])
AC_DEFINE_UNQUOTED([LDMS_COMPILE_HOST_OS],["$LDMS_COMPILE_HOST_OS"],[os where configured])
AC_DEFINE_UNQUOTED([LDMS_CONFIG_ARGS],["$ac_configure_args"],[configure input])
])

AC_DEFUN([OVIS_EXEC_SCRIPTS], [
	ovis_exec_scripts=""
	for i in "$*"; do
		x="$x $i";
	done
	for i in $x; do
		ovis_exec_scripts="$ovis_exec_scripts $i"
		x=`basename $i`
		if ! test "x$x" = "x"; then
			ovis_extra_dist="$ovis_extra_dist ${x}.in"
		else
			echo cannot parse $i
		fi
		AC_CONFIG_FILES([$i],[chmod a+x $i])
	done
	AC_SUBST([OVIS_EXTRA_DIST],[$ovis_extra_dist])
])

AC_DEFUN([SUBST_MAYBE],[
[if test "$enable_]m4_translit([$1], [-+.], [___])[" = "yes"; then
	MAYBE_]m4_translit([$1], [-+.a-z], [___A-Z])[="$1"
else
	MAYBE_]m4_translit([$1], [-+.a-z], [___A-Z])[=""
fi ]
AC_SUBST(MAYBE_[]m4_translit([$1], [-+.a-z], [___A-Z]))
])

AC_DEFUN([OPTION_VAR_FILE],[
	if test -f [$1]; then
		. [$1]
	fi
])

dnl
AC_DEFUN([OPTION_DOC_GENERATE],[
if test -z "$ENABLE_DOC_$1_TRUE"
then
	GENERATE_$1=YES
else
	GENERATE_$1=NO
fi
AC_SUBST(GENERATE_$1)
])

dnl For doxygen-based doc
AC_DEFUN([OPTION_DOC],[
OPTION_DEFAULT_DISABLE([doc], [ENABLE_DOC])
OPTION_DEFAULT_DISABLE([doc-html], [ENABLE_DOC_HTML])
OPTION_DEFAULT_DISABLE([doc-latex], [ENABLE_DOC_LATEX])
OPTION_DEFAULT_ENABLE([doc-man], [ENABLE_DOC_MAN])
OPTION_DEFAULT_DISABLE([doc-graph], [ENABLE_DOC_GRAPH])
OPTION_DOC_GENERATE(HTML)
OPTION_DOC_GENERATE(LATEX)
OPTION_DOC_GENERATE(MAN)
OPTION_DOC_GENERATE(GRAPH)
])
dnl SYNOPSIS: define common do_subst make rule sed expression
dnl for  makefiles.
AC_DEFUN([OVIS_DO_SUBST],[AC_SUBST([$1],[$2])])

