#!/bin/sh

# A Simple script to install FSL and set up the environment

VERSION="1.1"
POSIXLY_CORRECT=1
TEMPDIR='/tmp'

cecho () {
    string=$@
    my_os=`os`
    if [ "X${my_os}" = "XLinux" ]; then
	echo -e "$string "
    elif [ "X${my_os}" = "XSunOS"  ]; then
	echo "$string"
    elif [ `darwin_release` -lt 9 ]; then
	echo -e "$string"
    else
	echo "$string"
    fi
}

skipped () {
    message=$@

    cecho "\033[34;1m[Skipped]\033[0m $message"
}

ok () {
    message=$@

    cecho "\033[32;1m[OK]\033[0m $message"
}

failed () {
    message=$@

    cecho "\033[31;1m[Failed]\033[0m $message"
}

warning () {
    message=$@

    cecho "\033[31m[Warning]\033[0m $message"
}

Usage () {
    cat <<USAGE

fsl_installer.sh [-f <fsl tar ball> [-d <install folder>] [-x] [-e] [-p] [-h] [-C]]

 Options:
 =======
    -f <fsl tar ball>   - the FSL distribution tar file
    -d <install folder> - where to install to
    -x                  - (Mac OS 10.4 only) do NOT set up the Apple Terminal.app
                          application to be able to launch X11 applications.
    -e                  - only setup/update the environment
    -E                  - setup/update the environment for all users
    -p                  - don't setup the enviroment
    -h                  - display these instructions
    -v                  - print version number and exit without doing anything
    -C                  - don't check the FSL distribution tar file for corruption
                          (use if your computer can't access the internet)

 Example usage:
 =============
 fsl_installer.sh
    Fully automatic mode. Tests the downloaded FSL tar file located in the current 
directory for compatability with the running operating system. Then it downloads a 
checksum for the FSL distribution file (requires an internet connection) and checks
the download prior to installation of the FSL suite.
Finally, it sets up the operating system environment in a manner appropriate for 
running FSL on your platform.
Will request your password if you need Administrator priviledges to install.

 fsl_installer.sh -f fsl-4.0-linux_64.tar.gz
    Will install the FSL package fsl-4.0-linux_64.tar.gz in the current folder. 
Script will ask for install location, hit return to accept the default location
 of /usr/local. On a Mac OS X machine it will add code to configure the Mac OS X
 Terminal.app program to enable launching of X11 applications.

 fsl_installer.sh -f ~/fsl-4.0-linux_64.tar.gz -d /opt
    Will install the FSL package fsl-4.0-linux_64.tar.gz from your home folder into
 the folder /opt.

 fsl_installer.sh -f ~/fsl-4.0-darwin.tar.gz -d /Applications -x
    Will install the FSL package fsl-4.0-darwin.tar.gz from your home folder into
 the folder /Applications. In addition the -x option will prevent configuration of
 the Mac OS X Terminal application.

 fsl_installer.sh -f fsl-4.0-linux_64.tar.gz -d /opt -p
    Will install the FSL package fsl-4.0-linux_64.tar.gz from the current folder into
 the folder /opt. Will not setup the environment. Use this if you need to run as root
 to install to /opt.

 fsl_installer.sh -e
    Will setup your environment only, updating any existing configuration files
to the currently recommended settings.

fsl_installer.sh -E
    [Linux only] Will setup the computer to automatically configure FSL for all users 
on the system. You should not do this if you are installing FSL on a network share as 
it may prevent you from logging in as a local user if there are network issues.

 In all cases the script will attempt to modify your environment to setup the FSLDIR
variable and configure FSL for use.
USAGE
    exit 1
}

is_csh () {
    the_profile=$1
    if [ `echo ${the_profile} | grep 'csh'` ] ; then
	echo 1
    fi
}

is_sh () {
    the_profile=$1
    if [ `echo ${the_profile} | grep 'profile'` ] ; then
	echo 1
    fi
}

fix_fsldir () {
    fsldir=$1
    user_profile=$2
    if [ `is_sh ${user_profile}` ]; then
	search_string='FSLDIR='
    elif [ `is_csh ${user_profile}` ]; then
	search_string='setenv FSLDIR '
    else
	echo "No fix applied."
	return 1
    fi
    cp ${user_profile} ${user_profile}.bk
    cat ${user_profile} | sed -e "s#${search_string}.*#${search_string}${fsldir}#g" > ${user_profile}.bk
 
   if [ $? -eq 0 ]; then
	rm -f ${user_profile}
	mv ${user_profile}.bk ${user_profile}
	echo "'${user_profile}' updated with new FSLDIR definition."
	return 0
    else
	return 1
    fi
}

fsl_csh () {
    # The user's profile file
    profile=$1
    # Where FSL is installed
    fsldir=$2
    # Whether to avoid setting up FSL for the root user (used when installing system-wide
    no_root=$3

    echo "# FSL Configuration" >> ${profile}

    if [ ${no_root} -eq 1 ]; then
	echo "if [ \${UID} -ne 0 ]; then" >> ${profile}
    fi
    cat <<CSH >>${profile}
setenv FSLDIR ${fsldir}
setenv PATH \${FSLDIR}/bin:\${PATH}
source \${FSLDIR}/etc/fslconf/fsl.csh
CSH
    if [ ${no_root} -eq 1 ]; then
	echo "fi" >> ${profile}
    fi
}

fsl_sh () {
    # The user's profile file
    profile=$1
    # Where FSL is installed
    fsldir=$2
    # Whether to avoid setting up FSL for the root user (used when installing system-wide
    no_root=$3

    echo "# FSL Configuration" >> ${profile}

    if [ ${no_root} -eq 1 ]; then
	echo "if [ \${UID} -ne 0 ]; then" >> ${profile}
    fi
    cat <<SH >>${profile}
FSLDIR=${fsldir}
PATH=\${FSLDIR}/bin:\${PATH}
. \${FSLDIR}/etc/fslconf/fsl.sh
export FSLDIR PATH
SH
    if [ ${no_root} -eq 1 ]; then
	echo "fi" >> ${profile}
    fi
}

add_fsldir () {
    fsldir=$1
    user_profile=$2
    if [ `is_csh ${user_profile}` ]; then
	fsl_csh ${user_profile} ${fsldir} 0
    elif [ `is_sh ${user_profile}` ]; then
	fsl_sh ${user_profile} ${fsldir} 0
    else
	echo "This is an unsupported shell."
	return 1
    fi
    return 0
}


remove_display () {
    # This function will remove the DISPLAY setup configured by our installer in the past
    # Mac OS X 10.5 no longer requires this.
    display_profile=$1
    if [ `is_sh ${display_profile}` ]; then
	remove='if \[ -z \"\$DISPLAY\" -a \"X\$TERM_PROGRAM\" = \"XApple_Terminal\" \]; then'
    elif [ `is_csh ${display_profile}` ]; then
	remove='if ( \$?TERM_PROGRAM ) then'
    else
	echo "This is an unsupported shell."
	return 1
    fi
    if [ -n "`grep \"${remove}\" ${display_profile}`" ]; then
	# Remove the section
	echo "Attempting to remove the DISPLAY settings for Leopard compatability..."
	cat ${display_profile} | sed "/${remove}/{N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;d;}" > ${display_profile}.bak
	# Checking the removal succeeded without removing extra lines
	test_file="${display_profile}.$$"
	patch_for_terminal ${test_file} '-YES-'

	diff ${display_profile}.bak ${display_profile}  | sed -e '1d' -e 's/^> //' | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' >  ${test_file}.bak
	if [ -n "`diff \"${test_file}\" \"${test_file}.bak\"`" ]; then
	    echo "Remove failed (maybe you added DISPLAY settings yourself) - please update your ${display_profile} by hand"
       	else
	    mv ${display_profile} ${display_profile}.old
	    mv ${display_profile}.bak ${display_profile}
	    echo "Removed"
	fi
	rm ${test_file} ${test_file}.bak
    else
	echo failed to remove display
    fi
}

patch_for_terminal () {
    apple_profile=$1
    skip_test=$2
    # This is only necessary on Mac OS X 10.4 and lower
    if [ -n "`os | grep Darwin`" -a -n "`os_release | grep '^9.'`" -a "X$skip_test" != "X-YES-" ]; then
	if [ -f ${apple_profile} ]; then
	    if [ -n "`grep 'DISPLAY' ${apple_profile}`" ]; then
		echo "You are running Mac OS X 10.5 and have DISPLAY configured in your ${apple_profile} file."
		remove_display ${apple_profile}
	    fi
	fi
    else
	if [ "X$skip_test" != "X-YES-" ]; then
	    echo "Setting up Apple terminal..."
	fi
	if [ -f ${apple_profile} ]; then
	    if [ `grep DISPLAY ${apple_profile} | wc -l` -gt 0 ]; then
		echo "DISPLAY is already being configured in your '${apple_profile}' - not changing"
		return 1
	    fi
	fi

	if [ `is_csh ${apple_profile}` ]; then
	    cat <<CSH_TERM >>${apple_profile}
if ( \$?TERM_PROGRAM ) then
 if ( "X\$TERM_PROGRAM" == "XApple_Terminal" ) then; if ( ! \$?DISPLAY ) then
      set X11_FOLDER=/tmp/.X11-unix; set currentUser=\`id -u\`; set userX11folder=\`find \$X11_FOLDER -name 'X*' -user \$currentUser -print 2>&1 | tail -n 1\`
      if ( "X\$userX11folder" != "X" ) then
        set displaynumber=\`basename \${userX11folder} | grep -o '[[:digit:]]\+'\`
        if ( "X\$displaynumber" != "X" ) then
          setenv DISPLAY localhost:\${displaynumber}
        else; echo "Warning: DISPLAY not configured as X11 is not running"
        endif
      else
        echo "Warning: DISPLAY not configured as X11 is not running"
      endif
    endif 
  endif
endif
CSH_TERM
	elif [ `is_sh ${apple_profile}` ]; then
	    cat <<SH_TERM >>${apple_profile}
  if [ -z "\$DISPLAY" -a "X\$TERM_PROGRAM" = "XApple_Terminal" ]; then
    X11_FOLDER=/tmp/.X11-unix
    currentUser=\`id -u\`
    userX11folder=\`find \$X11_FOLDER -name 'X*' -user \$currentUser -print 2>&1 | tail -n 1\`
    if [ -n "\$userX11folder" ]; then
      displaynumber=\`basename \${userX11folder} | grep -o '[[:digit:]]\+'\`
      if [ -n "\$displaynumber" ]; then
        DISPLAY=localhost:\${displaynumber}
        export DISPLAY
      else
        echo "Warning: DISPLAY not configured as X11 is not running"
      fi
    else
      echo "Warning: DISPLAY not configured as X11 is not running"
    fi
  fi
SH_TERM
	else
	    echo "This is an unsupported shell."
	    return 1
	fi
    fi
    return 0
}

configure_matlab () {
    install_location=$1
    m_startup="${HOME}/matlab/startup.m"

    if [ -e ${m_startup} ]; then
	if [ -z "`grep FSLDIR ${m_startup}`" ]; then
	    echo "Configuring Matlab..."
	    cat <<FIXMATLAB >> ${m_startup}
setenv( 'FSLDIR', '${install_location}/fsl' );
fsldir = getenv('FSLDIR');
fsldirmpath = sprintf('%s/etc/matlab',fsldir);
path(path, fsldirmpath);
clear fsldir fsldirmpath;
FIXMATLAB
	fi
    fi
}

patch_environment () {
    install_location=$1
    setup_terminal=$2
    my_home=${HOME}
    my_shell=`basename ${SHELL}`
    env_modified="0"
    modified_shell='-NONE-'
    source_cmd='-NONE-'

    case ${my_shell} in
	sh | ksh )
	    my_profile=".profile"
	    source_cmd="."
	    ;;
	bash )
	    my_profile=".bash_profile"
	    source_cmd="."
	    ;;
	csh )
	    my_profile=".cshrc"
	    source_cmd="source"
	    ;;	    
	tcsh )
	    my_profile=".tcshrc .cshrc"
	    source_cmd="source"
	    if [ -f "${my_home}/.cshrc" -a -f "${my_home}/.tcshrc" ]; then
		echo "Warning you have both a .cshrc and .tcshrc - the .cshrc will never be processed!"
	    fi
	    ;;
	* )
	    my_profile="-UNKNOWN-"
	    ;;
    esac
    
    for profile in ${my_profile}; do
	if [ "Z${profile}" = "Z-UNKNOWN-" ]; then
	    echo "I don't know how to setup this shell, you will need to
set FSLDIR and modify the PATH environment variable yourself."
	    return 1
	fi
	process_shell="-NO-"
	process_terminal='-YES-'
	if [ -f ${my_home}/${profile} ]; then
	    if [ `is_csh ${my_home}/${profile}` ]; then
		search_string="setenv FSLDIR ${install_location}/fsl\$"
	    else 
		search_string="FSLDIR=${install_location}/fsl\$"
	    fi
	    fsldir_defs=`cat ${my_home}/${profile} | grep "FSLDIR" | wc -l`
	    if [ $fsldir_defs -gt 0 ]; then
                output="${profile} already contains a FSLDIR definition"
		if [ -n "`cat ${my_home}/${profile} | grep \"${search_string}\"`" ]; then
		    echo "${output} which is correctly configured, not changing."
		else
		    echo "${output} which is wrong.\nFixing FSLDIR configuration..."
		    fix_fsldir ${install_location}/fsl ${my_home}/${profile}
		    if [ $? -eq 0 ]; then
			modified_shell=${profile}
		    fi
		fi
	    else
		process_shell='-YES-'
	    fi
	else
	    if [ "Z${my_shell}" = 'Ztcsh' -a "Z${profile}" = 'Z.tcshrc' ]; then
		# Special case, skip the .tcshrc and create a .cshrc
		process_terminal='-NO-'
	    else
		process_shell="-YES-"
	    fi
	fi
	if [ "Z${process_shell}" = 'Z-YES-' ]; then
	    echo "Modifying '${profile}' for FSL..."
	    add_fsldir ${install_location}/fsl ${my_home}/${profile}
	    if [ $? -eq 0 ]; then
		modified_shell=${profile}
	    fi
	fi
	if [ "Z${setup_terminal}" = 'Z-YES-' -a "Z${process_terminal}" = 'Z-YES-' ]; then
	    # Setup the Apple Terminal.app
	    patch_for_terminal ${my_home}/${profile}
	fi
    done
    if [ -n "`os | grep Darwin`" ]; then
	configure_matlab ${install_location}
    fi
    if [ "Z${modified_shell}" != 'Z-NONE-' ]; then
	exec ${my_shell} -l
    fi
}

get_digest () {
    server=$1
    directory=$2
    release=$3
    local_dir=$4
    hosttype=`os`
    status=0
    here=`pwd`
    echo $release | grep 'gz' 2>&1 > /dev/null
    isnot_gz=$?

    if [ "X$hosttype" = "XLinux" -o "X$hosttype" = "XDarwin" ]; then
	if [ $isnot_gz -eq 1 ]; then
	    echo "I can only check gzip files, you have provided an uncompressed tar file."
	    status=2
	else
	    # Check we can write to this location
	    touch ${local_dir}/.test_$$ 2>&1 > /dev/null
	    if [ -f ${local_dir}/.test_$$ ]; then
		rm -f ${local_dir}/.test_$$
		if [ $hosttype = "Linux" ]; then
		    WGET="wget --timeout=15 --tries=1 --timestamping --quiet"
	            # FAILURE has exit code 1
		else
		    WGET="curl --connect-timeout 15 --max-time 30 --fail --remote-name --silent"
	            # FAILURE has exit code 22
		fi
		cd ${local_dir}
		${WGET} ${server}/${directory}/${release}.md5
		if [ $? -ne 0 ]; then
		    echo "I couldn't download the MD5 sum for $release, possibly you aren't connected to the internet.
This does not mean the install has failed!"
		    status=1
		fi
		cd ${here}
	    else
		echo "I can't write to ${local_dir}"
	    fi
	fi
    fi
    return $status
}

check_digest () {
    # Check the MD5 digest of the file passed as argument 1
    file=$1
    dir=$2
    md5dir=$3
    hosttype=`os`
    fileok=0
    here=`pwd`

    cd ${dir}
    if [ -f ${md5dir}/${file}.md5 ]; then
	if [ ${hosttype} = "Linux" ]; then
            md5sum --check --status ${md5dir}/${file}.md5 2>&1 >/dev/null
	    if [ $? -ne 0 ]; then
		fileok=1
	    fi
	elif [ ${hosttype} = "Darwin" ]; then
	    md5 ${file} | diff -q - ${md5dir}/${file}.md5 2>&1 >/dev/null
	    if [ $? -ne 0 ]; then
		fileok=1
	    fi
	fi
	rm -f ${md5dir}/${file}.md5 2>&1 > /dev/null
    else
	echo "Can't find the downloaded MD5 hash"
	fileok=2
    fi
    cd ${here}
    return $fileok
}

# Function that takes the bit depth of the tar file we downloaded and confirms we have the correct version for this platform. Pass in 32 or 64 as the first argument
check_platform () {
    expect_bits=$1
    status=0
    hosttype=`os`
    
    # Darwin (Mac OS X) is bit-depth agnostic
    if [ "X${hosttype}" != 'XDarwin' ]; then
	if [ "X${expect_bits}" != "X32" -a "X${expect_bits}" != "X64" ]; then
	    echo "Syntax error: check_platform <bit depth>"
	    return
	fi

	cpu=`cpu_type`
	echo ${cpu} | grep 'i.86' > /dev/null
	if [ $? = 1 ]; then
	    echo ${cpu} | grep 'x86_64' > /dev/null
	    if [ $? = 1 ]; then
		echo "Unknown CPU type! This probably won't work."
		status=2
	    else
		# This is a 64 bit platform
		if [ "X${expect_bits}" = "X32" ]; then
		    echo "You are installing the 32 bit distribution on a 64 bit host!"
		    status=2
		fi
	    fi
	else
	    # This is a 32 bit platform
	    if [ "X${expect_bits}" = 'X64' ]; then 
		echo "You are attempting to install the 64 bit ditribution on a 32 bit host!"
		status=1
	    fi
	fi
    else
	echo "This is a Mac OS X machine and the tar file is for Linux!"
	status=1
    fi
    return $status
}

# Function that takes a centos release number and checks if this is the correct glibc for release
# Returns:
#   0 - everything is fine
#   1 - major problem, please exit
#   2 - minor problem, prefer that you try a different version
#   3 - untested platform, just warn the user
check_glibc () {
    centos_v=$1
    bitdepth=$2
    status=0
    # Change the next value to be the same as the major.minor release of ld in the highest Centos
    # release we support and the version number of this Centos release
    highest_glibc_v=25
    highest_centos=5
 
    # This is a Linux installer so check the version of glibc
    my_LD='/lib'
    if [ "X$my_bitdepth}" = "X64" ]; then
	my_LD="${my_LD}${bitdepth}"
    fi
    my_LD_v=`(cd ${my_LD}; ls ld-*.so| sed -n 's/ld-\([0-9]*\)\.\([0-9]*\)\(.[0-9]*\)*.so/\1\2/p')`

    case "${centos_v}" in
	4)
	    glibc_v=23
	    next_glibc_v=25
	    ;;
	5)
	    glibc_v=25
	    # Modify the next value to reflext the ld version in the next Cent OS release as and when
            # Centos 6 is released
	    next_glibc_v=${highest_glibc_v}
	    ;;
	*)
	    echo "Unknown Centos version (${centos_v})"
	    return 2
    esac
    prev_centos=`expr $centos_v - 1`
    next_centos=`expr $centos_v + 1`

    if [ ${glibc_v} -eq ${next_glibc_v} ]; then
	# This is the newest version of CentOS we build on

	if [ ${my_LD_v} -lt ${glibc_v} ]; then
	    echo "This FSL release (Centos ${centos_v}) is not intended for this OS version, we would recommmend you try installing the release for the previous version of Centos (Centos ${prev_centos}) if available."
	    status=2
	elif [ ${my_LD_v} -gt ${glibc_v} ]; then
	    echo "This FSL release (Centos ${centos_v}) has not been fully tested for this OS version. You may need to install some compatibility libraries eg compat-expat1."
	    status=3
	fi
    else
	# There is a newer version of CentOS available
	if [ ${my_LD_v} -ge ${next_glibc_v} ]; then
	    if [ ${my_LD_v} -ge ${highest_glibc_v} ]; then
		echo "This FSL release (Centos ${centos_v}) is not intended for this OS version, you should try the version for Centos ${highest_centos}."
	    else
		echo "This FSL release (Centos ${centos_v}) is not intended for this OS version, you should try the version for Centos ${next_centos}."
	    fi
	    status=1
	elif [ ${my_LD_v} -gt ${glibc_v} ]; then
	    echo "This FSL release (Centos ${centos_v}) has not been fully tested for this OS version."
	    status=3
	elif [ ${my_LD_v} -lt {$glibc_v} ]; then
	    echo "This FSL release (Centos ${centos_v}) is unlikely to run on this OS version. You will need to compile FSL from the source code."
	    status=1
	fi
    fi
    return $status
}

os () {
    uname -s
}

os_release () {
    uname -r
}

darwin_release () {
    release=`os_release`
    echo $release | awk -F. '{ print $1 }'
}

cpu_type () {
    uname -m
}

fsl_install () {
    tarball=$1
    install_from=$2
    install_location=$3
    need_sudo=$4
    no_check=$5
    my_sudo=''
    fsl_server='http://www.fmrib.ox.ac.uk'
    fsl_dir='fsldownloads/md5sums'
    here=`pwd`

    if [ "X${need_sudo}" = "X-YES-" ]; then
	my_sudo="sudo "
    fi

    tgz_platform=`echo $tarball | grep -o 'centos\|macosx'`

    echo "Checking OS release ..."
    # Now check that this is the correct compilation for this host
    if [ "X`os`" = "XLinux" ]; then
	if [ "X$tgz_platform" = "Xcentos" ]; then
	    my_centosrelease=` echo $tarball | sed -n 's/fsl-.*centos\([0-9]*\)_[0-9]*.tar\(.gz\)*/\1/p'`
	    if [ "X$my_centosrelease" != "X" ]; then
		message=`check_glibc ${my_centosrelease}`
		if [ $? = 1 ]; then
		    failed $message
		    exit 1
		elif [ $? = 2 ]; then
		    warning $message
		    read -p "Continue? [no]" >&2 choice
		    if [ -z "${choice}" ]; then
			choice='no'
		    fi
		    choice=`to_lower ${choice}`
		    if [ "X${choice}" = "Xno" ]; then
			exit 1
		    fi
		elif [ $? = 3 ]; then
		    warning $message
		    read -p "Continue? [yes]" >&2 choice
		    if [ -z "${choice}" ]; then
			choice='yes'
		    fi
		    choice=`to_lower ${choice}`
		    if [ "X${choice}" != "Xyes" ]; then
			exit 1
		    fi
		else
		    ok
		fi
	    else
		failed "This is Linux and you have provided a non-Linux build of FSL!"
		exit 1
	    fi
	else
	    failed "This is Linux and you have provided a non-Linux build of FSL!"
	    exit 1
	fi
    elif [ "X`os`" = "XDarwin" ]; then
	if [ "X$tgz_platform" = "Xmacosx" ]; then
	    darwin_release=`darwin_release`
	    if [ $darwin_release -lt 8 ]; then
		failed "Sorry, we do not support Mac OS X 10.3. You could try building from the sources."
		exit 1
	    elif [ $darwin_release -gt 9 ]; then
		warning "You are running an un-recognised version of Mac OS X. This may not work."
	    else
		ok
	    fi
	else
	    failed "This is Mac OS X and you have provided a non-Mac OS X build of FSL!"
	    exit 1
	fi
    elif [ "X`os`" = "XSunOS" ]; then
	failed "We don't provide Solaris binaries. You could try building from the sources."
	exit 1
    else
	skipped
    fi
    
    echo "Checking CPU type..."
    # First check the tarball is the right version
    my_bitdepth=` echo $tarball | sed -n 's/fsl-.*_\([0-9]*\).tar\(.gz\)*/\1/p'`
    if [ "X$my_bitdepth" != "X" ]; then
	# This is not a bit agnostic install, check the tarball is the correct version
	message=`check_platform $my_bitdepth`
	status=$?
	if [ $status = 1 ]; then
	    failed $message
	    exit 1
	elif [ $status = 2 ]; then
	    warning $message
	    read -p "Continue? [yes]" choice
	    if [ -z "${choice}" ]; then
		choice='yes'
	    fi
	    choice=`to_lower ${choice}`
	    if [ "X${choice}" != "Xyes" ]; then
		exit 1
	    fi
	else
	    ok
	fi
    else
	skipped
    fi
    echo "Checking install file...(this may take several minutes)"
    if [ "X${no_check}" = 'X-NO-' ]; then		
        # Now verify the download
	digest_dir='/tmp'
	get_digest ${fsl_server} ${fsl_dir} ${tarball} ${digest_dir}
	if [ $? = 0 ]; then
	    check_digest ${tarball} ${install_from} ${digest_dir}
	    if [ $? = 1 ]; then
		failed "${tarball} appears to be corrupt. Aborting install"
		exit 1
	    elif [ $? = 2 ]; then 
	        skipped
	    else
		ok
	    fi
	else
	    skipped
	fi
    else
	skipped
    fi

    echo "Installing FSL from ${install_from}/${tarball} into ${install_location}..."
    cd ${install_location}
    # Untar the distribution into the install location
    ${my_sudo} echo '' > /dev/null
    tar_opts='xf'
    echo ${tarball} | grep '\.gz' 2>&1 >/dev/null
    if [ $? = 0 ]; then
	tar_opts="z${tar_opts}"
    fi
    $my_sudo tar ${tar_opts} ${install_from}/${tarball}
    if [ $? -ne 0 ]; then
	failed "Unable to install"
	exit 1
    else
	ok
    fi
    cd ${here}
    if [ "X`os`" = "XDarwin" ]; then
	read -p "Would you like to install FSLView.app into /Applications (requires Administrator priviledges)? [yes] " choice

	if [ -z "${choice}" ]; then
	    choice='yes'
	fi
	choice=`to_lower $choice`;
	if [ "X$choice" = "Xyes" ]; then
	    if [ -e /Applications/fslview.app -o -L /Applications/fslview.app ]; then
		echo "Moving old FSLView into the Trash"
		my_trash="${HOME}/.Trash"
		my_id=`id -u`
		sudo rm -rf ${my_trash}/fslview.app
		sudo mv /Applications/fslview.app ${my_trash}/
		sudo chown -R ${my_id} ${my_trash}/fslview.app
	    fi
	    echo "Installing FSLView into /Applications..."
	    sudo ln -s ${install_location}/fsl/bin/fslview.app /Applications
	    if [ $? = 0 ]; then
		ok
	    else
		failed
	    fi
	    if [ ! -e /Applications/assistant.app ]; then
		echo "Installing help application into /Applications..."
		sudo ln -s ${install_location}/fsl/bin/assistant.app /Applications
		if [ $? = 0 ]; then
		    ok
		else
		    failed
		fi
	    fi

	else
	    skipped
	fi
    fi

}

to_lower () {
    echo `echo $1 | tr 'A-Z' 'a-z'`
}

x11_not_installed () {
    if [ -d '/Applications/Utilities/X11.app' ]; then
	return 0
    else
	return 1
    fi
}

get_fsldir () {
    default_location=$1
    # exists is:
    # 0 - when you don't want to check that FSL is installed in install_location
    # 1 - when you wish to test for the presence of FSL (used with the -e and -E options)
    exists=$2
    message=$3
    install_location='-NONE-'
    while [ "X${install_location}" = 'X-NONE-' ];  do
	read -p "${message}" >&2 choice	
	if [ -z "${choice}" ]; then
	    choice=${default_location}
	fi
	if [ -d ${choice} ]; then
	    if [ $exists -eq 1 ]; then
		if [ -f "${choice}/fsl/etc/fslversion" ]; then
		    install_location=${choice}
		else
		    echo "'${choice}' doesn't appear to contain a FSL install." >&2
		fi
	    else
		install_location=${choice}
	    fi
	else
	    echo "'${choice}' doesn't appear to be a directory." >&2
	    unset choice
	fi
    done
    echo $install_location
}

# Main section of installer
# Find out what platform we are on
here=`pwd`
platform=`os`
release=`os_release`

install_from='-NONE-'
setup_terminal='-NO-'
no_install='-NO-'
no_md5_check='-NO-'
n_sudo='-NO-'
no_profile='-NO-'
system_profile='-NO-'
install_location='-NONE-'
default_location='/usr/local'
is_patch='-NO-'

if [ "X${platform}" = "XDarwin" ]; then
    setup_terminal='-YES-'
    if [ `x11_not_installed` ]; then
	warning "X11 is not installed, no GUIs will function."
    fi
elif [ "X${platform}" = "XSunOS" ]; then
    failed "Solaris is not supported by any of the binary releases of FSL. Please build from the source code."
    exit 1
elif [ "X${platform}" != "XLinux" ]; then
    warning "This platform is not supported by this installer."
fi

  # Parse the command line options
while [ _$1 != _ ]; do
    if [ $1 = '-d' ]; then
	install_location=$2
	shift 2
    elif [ $1 = '-x' ]; then
	setup_terminal="-NO-"
	shift
    elif [ $1 = '-e' ]; then
	no_install="-YES-"
	shift
    elif [ $1 = '-p' ]; then
	no_profile='-YES-'
	system_profile='-NO-'
	shift
    elif [ $1 = '-h' ]; then
	Usage
    elif [ $1 = '-f' ]; then
	fsl_tarball=$2
	shift 2
    elif [ $1 = '-v' ]; then
	echo "$VERSION"
	exit 0;
    elif [ $1 = '-C' ]; then
	no_md5_check='-YES-'
	shift
    elif [ $1 = '-E' ]; then
	system_profile='-YES-'
	no_install='-YES-'
	no_profile='-YES-'
	shift
    else
	Usage
    fi
done


echo "FSL install script
==================
"  
# Split up the tarball location and set install_from to current directory
# if no path is specified
if [ "X${no_install}" = 'X-NO-' ]; then
    if [ -z "${fsl_tarball}" ]; then
	echo "Looking for FSL tarball in the current directory..."
	tarballs=`ls ${here} | grep '^fsl-.*.tar\(.gz\)*$' | wc -l`
	
	if [ ${tarballs} -gt 1 ]; then
	    failed "Too many FSL tarballs found in the current directory!"
	    exit 1
	elif [ ${tarballs} -eq 0 ]; then
	    failed "No FSL tarball found in the current directory."
	    Usage
	else
	    fsl_tarball="${here}/`ls ${here} | grep '^fsl-.*.tar\(.gz\)*$'`"
	    cat <<EOF 
***************************************************************
No FSL tarball specified, assuming you want me to install 
${fsl_tarball} 
from the current directory.
***************************************************************

EOF
	fi
    fi

    install_from=`dirname ${fsl_tarball}`
    if [ -z "${install_from}" -o "X$install_from" = "X." ]; then
	install_from=${here}
    else
	fsl_tarball=`basename ${fsl_tarball}`
    fi

  # Validate the tar file
    test_tarball=`file -b ${fsl_tarball} | grep '\(gzip\)\|\(tar\)'`
    if [ -z "${test_tarball}" ]; then
	failed "${fsl_tarball} doesn't appear to be a GZIP or tar file."
	exit 1
    fi 
    
  # Check if it is a patch file
    test_patchfile=`echo ${fsl_tarball} | grep patch`
    if [ -n "${test_patchfile}" ]; then
	echo "${fsl_tarball} appears to be a FSL patch..."
	is_patch="-YES-"
    fi
    
  # Ask the user where to install (if necessary)
    if [ "X${install_location}" = "X-NONE-" ]; then
	install_location=`get_fsldir ${default_location} 0 "Where would you like to install FSL to? [${default_location}] "`
    fi

  # Validate the install location
    if [ ! -d ${install_location} ]; then
	failed "'${install_location}' doesn't appear to be a directory."
	Usage
    fi
    
  # Check it is writeable, and if not request Sudo
    writeable=`touch ${install_location}/.fsl-test 2>&1 | grep "Permission denied"`
    if [ -z "${writeable}" ]; then
	rm ${install_location}/.fsl-test
    else
	echo "Will require Administrator priviledges to write to '${install_location}'"
	echo "Enter a password to elevate to Administrator rights when prompted"
	n_sudo='-YES-'
	sudo touch ${install_location}/.fsl-test 2>&1
	if [ $? -ne 0 ]; then
	    echo "Sorry, you cannot install FSL as this user, either install as the root user"
	    echo "or as a user with sudo rights."
	    echo "You can then re-run fsl_installer.sh with the -e option to setup your user"
	    echo "account for running FSL."
	    exit 1
	fi
    fi

    if [ -d ${install_location}/fsl ]; then
	if [ "X$is_patch" = "X-NO-" ]; then
	    read -p "'${install_location}/fsl' exists - would you like to remove it? [yes] " choice
	    choice=`to_lower $choice`
	    if [  -z "${choice}" -o "X${choice}" = "Xyes" ]; then
		echo "Deleting '${install_location}/fsl'..."
		delete_cmd="rm -rf ${install_location}/fsl"
		if [ "X${n_sudo}" = "X-YES-" ]; then
		    delete_cmd="sudo ${delete_cmd}"
		fi
		$delete_cmd
		if [ $? -ne 0 ]; then
		    failed "Unable to delete. Aborting"
		    exit 1
		else
		    ok
		fi
	    fi
	else
	    echo "Patching ${install_location}/fsl with contents of ${install_from}/${fsl_tarball}"
	fi
    fi
    
    # Install FSL
    fsl_install ${fsl_tarball} ${install_from} ${install_location} ${n_sudo} ${no_md5_check} ${darwin_release}
fi

if [ "X${no_profile}" = 'X-NO-' ]; then
    # Set up the user's environment
    echo "Patching environment"
    if [ "X${install_location}" = 'X-NONE-' ]; then
	install_location=`get_fsldir ${default_location} 1 "Where is FSL installed? [${default_location}]"`
    fi
    patch_environment ${install_location} ${setup_terminal}
fi

if [ "X`os`" = "XLinux" ]; then
    if [ "X${system_profile}" != "X-YES-" ]; then
	read -p "Are you sure you would like to configure FSL system wide? (Not recommended if ${install_location} is on an NFS share) [no] " >&2 choice
	choice=`to_lower $choice`
	if [ "X${choice}" = "Xyes" ]; then
	    system_profile='X-YES-';
	fi
    fi
    if [ "X${system_profile}" = "X-YES-" ]; then
	if [ "X${install_location}" = "X-NONE-" ]; then
	    install_location=`get_fsldir ${default_location} 1 "Where is FSL installed? [${default_location}]"`
	fi
	echo "Setting up FSL system-wide (will require administrator priviledges)..."
	sysprofile_dir='/etc/profile.d'
	if [ -d ${sysprofile_dir} ]; then
	    sudo touch "${sysprofile_dir}/.testfile" 2>&1 >/dev/null
	    if [ $? -eq 0 ]; then
		sudo rm -f "${sysprofile_dir}/.testfile"
		fsl_sh "${TEMPDIR}/fsl.sh.$$" "${install_location}/fsl" 1
		fsl_csh "${TEMPDIR}/fsl.csh.$$" "${install_location}/fsl" 1

		sudo mv "${TEMPDIR}/fsl.sh.$$" "${sysprofile_dir}/fsl.sh"
		if [ $? -ne 0 ]; then
		    failed "Can't setup for /bin/sh users"
		else
		    ok "/bin/sh configured"
		fi
		sudo mv "${TEMPDIR}/fsl.csh.$$" "${sysprofile_dir}/fsl.csh"
		if [ $? -ne 0 ]; then
		    failed "Can't setup for /bin/(t)csh users"
		else
		    ok "/bin/(t)csh configured"
		fi
	    else
		failed "I can't write to ${sysprofile_dir}"
	    fi
	else
	    failed "I don't know how to do this on this platform"
	fi
    fi
elif [ "X${system_profile}" = "X-YES-" ]; then
    echo "Setting up FSL system-wide..."
    skipped "We don't support system-wide FSL configuration on this platform."
    echo "Run this script with -e for each user who will be running FSL"
    echo "(or setup a shared profile somewhere)."
fi

exit 0