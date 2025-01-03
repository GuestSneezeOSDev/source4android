#!/bin/bash
# ===============SOURCE4ANDROID===============
# Source4Android is licensed under MIT License,
# so if you do plan on using it you must credit GuestSneezePlayZ in your HL2 Mod or Source Engine-based game.
# Thank you for using this project! And Super Thanks to every contributor in the project!
# Contributors:
# GuestSneezeOSDev: Android support and most of the stuff
# nillerusr: The touch support comes from his repository
# ===============LICENSE======================
# MIT License
#
#Copyright (c) 2025 Mohamed
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

(
SRCDIR = ../..
echo "Please install vs-android before continuing."
echo "It can be located here -> http://www.gavpugh.com/downloads/vs-android-0.964.zip"
sleep 5
echo "Editing client to support Android."
${SRCDIR}/game/client/client.vcxproj << EOF
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Android'">
  <OutputPath>$(SolutionDir)bin\$(Configuration)\android\</OutputPath>
</PropertyGroup>
<HasSharedItems>true</HasSharedItems>
EOF
echo "Editing client to support Android. Complete"
echo "Editing server to support Android."
${SRCDIR}/game/server/server.vcxproj << EOF
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Android'">
  <OutputPath>$(SolutionDir)bin\$(Configuration)\android\</OutputPath>
</PropertyGroup>
<HasSharedItems>true</HasSharedItems>
EOF
echo "Editing server to support Android. Complete"
) 2>&1 | tee -a src4android.log
# ===============SOURCE4ANDROID LOGS===============
echo "SOURCE4ANDROID LOGS:"
cat src4android.log
