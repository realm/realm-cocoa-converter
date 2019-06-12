#!/bin/bash

# Custom build tool for Realm Converter
# This was taken from the realm-cocoa build.sh script

# Warning: pipefail is not a POSIX compatible option, but on OS X it works just fine.
#          OS X uses a POSIX complain version of bash as /bin/sh, but apparently it does
#          not strip away this feature. Also, this will fail if somebody forces the script
#          to be run with zsh.
set -o pipefail
set -e

CODESIGN_PARAMS="CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO"
XCODEBUILD_FLAGS="" #"COMPILER_INDEX_STORE_ENABLE=NO"

xcode() {
    CMD="xcodebuild clean build $CODESIGN_PARAMS $XCODEBUILD_FLAGS $@ | bundle exec xcpretty -f `xcpretty-travis-formatter`"
    echo "Building with command:" $CMD
    eval "$CMD"
}

build() {
    local scheme="$1"
    local sdk="$2"
    
    local destination=""
    local archflags=""
    if [[ "$sdk" == "iphoneos" ]]; then
        destination="-destination 'generic/platform=iOS'"
    elif [[ "$sdk" == "iphonesimulator" ]]; then
        destination="-destination 'generic/platform=iOS Simulator'"
        archflags="ONLY_ACTIVE_ARCH=NO"
    fi

    xcode "-scheme $scheme -sdk $sdk $destination -workspace $workspace $archflags -derivedDataPath build/DerivedData_$sdk"
}

workspace="RealmConverter.xcworkspace"
build "RealmConverterMacOS" "macosx"
build "RealmConverteriOS" "iphoneos"
build "RealmConverteriOS" "iphonesimulator"

pod lib lint --quick
