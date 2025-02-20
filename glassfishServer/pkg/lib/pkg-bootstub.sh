#!/bin/sh
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright 2008 Sun Microsystems, Inc. All rights reserved.
#
# The contents of this file are subject to the terms of either the GNU
# General Public License Version 2 only ("GPL") or the Common Development
# and Distribution License("CDDL") (collectively, the "License").  You
# may not use this file except in compliance with the License. You can obtain
# a copy of the License at https://glassfish.dev.java.net/public/CDDL+GPL.html
# or updatetool/LICENSE.txt.  See the License for the specific
# language governing permissions and limitations under the License.
#
# When distributing the software, include this License Header Notice in each
# file and include the License file at glassfish/bootstrap/legal/LICENSE.txt.
# Sun designates this particular file as subject to the "Classpath" exception
# as provided by Sun in the GPL Version 2 section of the License file that
# accompanied this code.  If applicable, add the following below the License
# Header, with the fields enclosed by brackets [] replaced by your own
# identifying information: "Portions Copyrighted [year]
# [name of copyright owner]"
#
# Contributor(s):
#
# If you wish your version of this file to be governed by only the CDDL or
# only the GPL Version 2, indicate your decision by adding "[Contributor]
# elects to include this software in this distribution under the [CDDL or GPL
# Version 2] license."  If you don't indicate a single choice of license, a
# recipient has the option to distribute your version of this file under
# either the CDDL, the GPL Version 2 or to extend the choice of license to
# its licensees as provided above.  However, if you add GPL Version 2 code
# and therefore, elected the GPL Version 2 license, then the option applies
# only if the new code is made subject to such option by the copyright
# holder.
#

#
# Startup stub
#

# Resolve a symbolic link to the true file location
resolve_symlink () {
    file="$1"
    while [ -h "$file" ]; do
        ls=`ls -ld "$file"`
        link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
        if expr "$link" : '^/' 2> /dev/null >/dev/null; then
            file="$link"
        else
            file=`dirname "$1"`"/$link"
        fi
    done
    echo "$file"
}

# Take a relative path and make it absolute. Pwd -P will
# resolve any symlinks in the path
make_absolute () {
    save_pwd=`pwd`
    cd "$1";
    full_path=`pwd -P`
    cd "$save_pwd"
    echo "$full_path"
}


# Locate a Java runtime. Ideally we'd use the "java -version:<version>"
# syntax to locate a JRE of the correct version. But unfortunately that
# is not consistently implemented across the various platforms. So we
# do it the old fashion way: parse "java -version"
locate_java() {

    # Search path for locating java
    java_locs="$JAVA_HOME/bin:/bin:/usr/bin:/usr/java/bin:$PATH"
    # Convert colons to spaces
    java_locs=`echo $java_locs | tr ":" " "`

    for j in $java_locs; do
        # Check if version is sufficient
        major="0"
        minor="0"
        if [ -x "$j/java" ]; then
            version=`"$j/java" -version 2>&1 | grep version | cut -d'"' -f2`
            major=`echo $version | cut -d'.' -f1`
            minor=`echo $version | cut -d'.' -f2`
        fi

        if [ -z "$major" ]; then
            major="0"
        fi

        if [ -z "$minor" ]; then
            minor="0"
        fi

        # We want 1.5 or newer
        if [ "$major" -eq "1" -a "$minor" -ge "5" ];  then
            echo "$j/java"
            return
        fi
        if [ "$major" -gt "1" ];  then
            echo "$j/java"
            return
        fi
    done

    echo ""
}

# Prompt for a response. Sets "ans" to response. Converts "Y" and "yes" to "y"
myprompt() {
    while true; do
        printf "$1"
        read ans
        if [ -z "$ans" ]; then
            continue
        fi
        if [ "$ans" = "y" -o "$ans" = "Y" -o "$ans" = "yes" ]; then
            # Normalize 
            ans="y"
            return
        fi
        if [ "$ans" = "n" -o "$ans" = "N" -o "$ans" = "no" ]; then
            # Normalize 
            ans="n"
            return
        fi
        return
    done
}

# Save properties to Java props file for bootstrap
create_bootstrap_props() {

    echo "install.pkg=true" > "$BOOTSTRAPPROPS"

    if [ "$cmd" = "updatetool" ]; then
        echo "install.updatetool=true" >> "$BOOTSTRAPPROPS"
    fi

    if [ ! -z "$http_proxy" ]; then
        echo "proxy.URL=$http_proxy" >> "$BOOTSTRAPPROPS"
    fi

    if [ ! -z "$https_proxy" ]; then
        echo "proxy.secure.URL=$https_proxy" >> "$BOOTSTRAPPROPS"
    fi

    if [ -z "$http_proxy" ]; then
        echo "proxy.use.system=true" >> "$BOOTSTRAPPROPS"
    fi

    echo "optin.usage.reporting=true" >> "$BOOTSTRAPPROPS"

    # Image path is passed on the command line. See bug 376
    image_path="$my_home/.."
}

cleanup_bootstrap_props() {
    rm -f "$BOOTSTRAPPROPS"
}

# Location of BOOTSTRAP jar file, relative to INSTALL_HOME
BOOTSTRAPJAR="pkg/lib/pkg-bootstrap.jar"
BOOTSTRAPPROPS="/tmp/pkg-bootstrap$$.props"


# Find out where we are installed
cmd=`resolve_symlink "$0"`
my_home_relative=`/usr/bin/dirname "$cmd"`
my_home=`make_absolute "$my_home_relative"`

cmd=`basename "$cmd"`

my_java=`locate_java`

if [ -z "$my_java" ]; then
    echo 
    echo "Could not locate a suitable Java runtime."
    echo "Please ensure that you have Java 5 or newer installed on your system"
    echo "and accessible via your PATH or by setting JAVA_HOME"
    exit 1
fi


echo
echo "The software needed for this command ($cmd) is not installed."
if [ "$cmd" = "updatetool" ]; then
    echo
    echo "If you choose to install Update Tool, your system will be automatically"
    echo "configured to periodically check for software updates. If you would like"
    echo "to configure the tool to not check for updates, you can override the"
    echo "default behavior via the tool's Preferences facility."

    prompt_msg="Would you like to install Update Tool now (y/n): "
else
    prompt_msg="Would you like to install this software now (y/n): "
fi
echo
echo "When this tool interacts with package repositories, some system information"
echo "such as your system's IP address and operating system type and version"
echo "is sent to the repository server. For more information please see:"
echo
echo "http://wiki.updatecenter.java.net/Wiki.jsp?page=UsageMetricsUC2"
echo
echo "Once installation is complete you may re-run this command."
echo

myprompt "$prompt_msg"

if [ "$ans" != "y" ]; then
    exit 1
fi

BOOTSTRAPJAR="$my_home/../$BOOTSTRAPJAR"

if [ ! -f "$BOOTSTRAPJAR" ]; then
    echo "Software installation failed."
    echo "Could not locate: $BOOTSTRAPJAR"
    exit 1
fi

# We are on Unix. Remove windows BAT files
rm -f "$my_home/pkg.bat"
rm -f "$my_home/updatetool.bat"

# Create property file with bootstrap settings
create_bootstrap_props

echo
"$my_java" -Dimage.path="$image_path" -jar "$BOOTSTRAPJAR"  "$BOOTSTRAPPROPS"
rcode=$?
if [ $rcode -eq "0" ]; then
    echo
    echo "Software successfully installed. You may now re-run this command ($cmd)."
fi

if [ $rcode -eq "3" -o $rcode -eq "4" ]; then
    echo
    echo "Could not download application packages. This could be because:"
    echo "  - a proxy server is needed to access the internet. Please ensure that"
    echo "    the system proxy server settings are correct, or set the 'http_proxy'"
    echo "    environment variable to the full URL of the proxy server."
    echo "  - the package server is down or otherwise inaccessible or it is"
    echo "    generating invalid data. Please contact the provider of the package"
    echo "    server."
    echo
fi

cleanup_bootstrap_props

exit $rcode
