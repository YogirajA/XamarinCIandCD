# !/bin/sh
 function fail {
    echo "$*" >&2
    exit 1
}

function section_print {
    echo "\n=== $* ==="
}

if [ -z $CONFIGURATION ]; then
    fail "No configuration specified";
    exit 1;
fi

if [ -z $DEVICE ]; then
    fail "No device specified";
    exit 1;
fi

# Put your project folder here
PROJECT_FOLDER={folderPath}

#Put your solution file here
SOLUTION_FILE={.sln file} 

BUILD_PATH=$PROJECT_FOLDER/bin/"$DEVICE"/"$CONFIGURATION"

section_print "Updating Build Number"
cd "$WORKSPACE"
VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $PROJECT_FOLDER/Info.plist)
VERSION=$VERSION_NUMBER.$BUILD_NUMBER
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" $PROJECT_FOLDER/Info.plist

section_print "Updating App Name"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Mobile CRM $BUILD_NUMBER" $PROJECT_FOLDER/Info.plist

section_print "Restoring nuget packages"
/usr/Local/bin/nuget restore $SOLUTION_FILE

section_print "Restoring packages from other source"
/usr/Local/bin/nuget restore $SOLUTION_FILE -source $OtherSourceFeed

section_print "Building $CONFIGURATION"
/Applications/Xamarin\ Studio.app/Contents/MacOS/mdtool -v build "--configuration:$CONFIGURATION|$DEVICE" $SOLUTION_FILE || fail "Build failed"

# Get the .app and .ipa file names
cd "$BUILD_PATH"
for file in "*.app"
do
    APP_NAME=`echo $file`
done
APP_NAME=${APP_NAME%.*}

IPA_FILE=`find . -name "*.ipa"  -type f -print0 | xargs -0 stat -f "%m %N" | sort -rn | head -1 | cut -f2- -d" "`


section_print "Compressing dSYM"
DSYM_FILE="$APP_NAME-$VERSION.dSYM.zip"
zip -r $DSYM_FILE "$APP_NAME.app.dSYM"

section_print "Removing old artefacts from Workspace folder"
cd "$WORKSPACE"
rm -f *.ipa
rm -f *.dSYM.zip
rm -rf *.dSYM

section_print "Copying artefacts"
cd "$BUILD_PATH"
cp -v "$IPA_FILE" "$WORKSPACE/." || fail "Failed to copy ipa"
cp -v "$DSYM_FILE" "$WORKSPACE/." || fail "Failed to copy dSYM zip"
cp -r "$APP_NAME.app.dSYM" "$WORKSPACE/$APP_NAME.app.dSYM/" || fail "Failed to copy dSYM"

section_print "Build succeeded"
