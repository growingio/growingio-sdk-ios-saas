#!/bin/bash

USER_COMMAND=$0

# version for publicHeader coreKit autotrackKit reactnativeKit
OPT_PUBLIC_VERSION="HEAD"
OPT_CORE_VERSION="HEAD"
OPT_AUTO_VERSION="HEAD"
OPT_RN_VERSION="HEAD"

OPT_BUILD_PUBLIC=0
OPT_BUILD_COREKIT=0
OPT_BUILD_AUTOKIT=0
OPT_BUILD_RNKIT=0
OPT_BUILD_IDFA_MODE=1            #默认是有idfa的

OPT_BUILD_CONFIGURATION="Release"

OPT_HELP=0
OPT_UNKNOWN=""

while [ ! -z "$1" ]; do
	case $1 in
	-pv | --version-publicHeaderNumber)
		shift
		OPT_BUILD_PUBLIC=1
		OPT_PUBLIC_VERSION="$1"
		;;

	-cv | --version-coreKitNumber)
		shift
		OPT_BUILD_COREKIT=1
		OPT_CORE_VERSION="$1"
		;;

	-av | --version-AutoKitNumber)
		shift
		OPT_BUILD_AUTOKIT=1
		OPT_AUTO_VERSION="$1"
		;;

	-rv | --version-ReactNativeKitNumber)
		shift
		OPT_BUILD_RNKIT=1
		OPT_RN_VERSION="$1"
		;;

	-ad | --no-idfa)
		shift
		OPT_BUILD_IDFA_MODE="$1"
		;;

	-h | --help)
		OPT_HELP=1
		;;

	*)
		OPT_UNKNOWN="${OPT_UNKNOWN} $1"
		;;

	esac
	shift
done

if [ ! -z "${OPT_UNKNOWN}" ]; then
	echo ""
	echo -e "Unknown options: \033[31m\033[1m${OPT_UNKNOWN}\033[0m"
	OPT_HELP=1
fi

if [ $OPT_BUILD_PUBLIC == 0 ] && [ $OPT_BUILD_COREKIT == 0 ] && [ $OPT_BUILD_AUTOKIT == 0 ] && [$OPT_BUILD_RNKIT == 0]; then
	echo ""
	echo "Hi, you must confirm a version, see help please."
	OPT_HELP=1
fi

if [ $OPT_BUILD_PUBLIC == 1 ]; then
	if [ -z "${OPT_PUBLIC_VERSION}" ]; then
		echo ""
		echo "Invalid publicHeader version number"
		OPT_HELP=1
	fi
fi

if [ $OPT_BUILD_COREKIT == 1 ]; then
	if [ -z "${OPT_CORE_VERSION}" ]; then
		echo ""
		echo "Invalid corekit version number"
		OPT_HELP=1
	fi
fi

if [ $OPT_BUILD_AUTOKIT == 1 ]; then
	if [ -z "${OPT_AUTO_VERSION}" ]; then
		echo ""
		echo "Invalid autotrackKit version number"
		OPT_HELP=1
	fi
fi

if [ $OPT_BUILD_RNKIT == 1 ]; then
	if [ -z "${OPT_RN_VERSION}" ]; then
		echo ""
		echo "Invalid reactnativeKit version number"
		OPT_HELP=1
	fi
fi

if [ $OPT_HELP == 1 ]; then
	echo ""
	echo "usage: "$(basename ${USER_COMMAND})" [[-pv | --version-publicHeaderNumber] version-number]"
	echo -e "       \033[8m"$(basename ${USER_COMMAND})"\033[0m [[-cv|--version-coreKitNumber] version-number]"
	echo -e "       \033[8m"$(basename ${USER_COMMAND})"\033[0m [[-av|--version-AutoKitNumber] version-number]"
	echo -e "       \033[8m"$(basename ${USER_COMMAND})"\033[0m [[-av|--version-ReactNativeKitNumber] version-number]"
	echo -e "       \033[8m"$(basename ${USER_COMMAND})"\033[0m [-h] [--help]"
	echo "       -pv, --version-publicHeaderNumber: set publicHeader version number (like 0.9.8.5), default is HEAD"
	echo "       -cv, --version-coreKitNumber: set corekit version number (like 0.9.8.5), default is HEAD"
	echo "       -av, --version-AutoKitNumber: set autotrackKit version number (like 0.9.8.5), default is HEAD"
	echo "       -rv, --version-reactNativeKitNumber: set reactnativeKit version number (like 0.9.8.5), default is HEAD"
	echo "       -h, --help: this help"
	echo ""
	exit 1
fi

TEMP=mktemp
git branch | grep "^* " >"${TEMP}"
if [ $? == 0 ]; then
	:
else
	echo ""
	echo "Not a git repository ???"
	echo ""
	exit 1
fi
GIT_CURRENT_BRANCH=$(sed "s/\* //g" ${TEMP})
rm "${TEMP}"
TEMP=

GIT_LAST_REVISION=$(git rev-parse --short HEAD)
if [ $? == 0 ]; then
	:
else
	echo ""
	echo "Not a git repository ???"
	echo ""
	exit 1
fi

COLORED_YES="\033[32m\033[1mYES\033[0m"
COLORED_NO="\033[31m\033[1m NO\033[0m"

if [ $OPT_BUILD_PUBLIC == 1 ]; then
	echo -e "Building Public Header version:      \033[32m\033[1m${OPT_PUBLIC_VERSION}\033[0m"
fi

if [ $OPT_BUILD_COREKIT == 1 ]; then
	echo -e "Building GrowingCoreKit version:      \033[32m\033[1m${OPT_CORE_VERSION}\033[0m"
fi

if [ $OPT_BUILD_AUTOKIT == 1 ]; then
	echo -e "Building GrowingAutoTrackKit version:      \033[32m\033[1m${OPT_AUTO_VERSION}\033[0m"
fi

if [ $OPT_BUILD_RNKIT == 1 ]; then
	echo -e "Building GrowingReactNativeKit version:      \033[32m\033[1m${OPT_RN_VERSION}\033[0m"
fi

echo ""
echo -n "Press Ctrl+C to cancel "
sleep 1
echo -n "."
sleep 1
echo -n "."
sleep 1
echo -n "."
sleep 1
echo ""
echo ""

set -e

COMPILE_DATE_TIME=$(date -j +"%Y%m%d%H%M%S")

SHORT_VERSION[0]="${OPT_CORE_VERSION}"
SHORT_VERSION[1]="${OPT_AUTO_VERSION}"
SHORT_VERSION[2]="${OPT_PUBLIC_VERSION}"
SHORT_VERSION[3]="${OPT_RN_VERSION}"

VERSION[0]="${SHORT_VERSION[0]}"
VERSION[1]="${SHORT_VERSION[1]}"
VERSION[2]="${SHORT_VERSION[2]}"
VERSION[3]="${SHORT_VERSION[3]}"

TARGET[0]="GrowingCoreKit"
TARGET[1]="GrowingAutoTrackKit"
TARGET[2]="GrowingHeader"
TARGET[3]="GrowingReactNativeKit"

DIR_NAME[0]="${COMPILE_DATE_TIME}-${GIT_CURRENT_BRANCH}-${GIT_LAST_REVISION}-${TARGET[0]}"
DIR_NAME[1]="${COMPILE_DATE_TIME}-${GIT_CURRENT_BRANCH}-${GIT_LAST_REVISION}-${TARGET[1]}"
DIR_NAME[2]="${COMPILE_DATE_TIME}-${GIT_CURRENT_BRANCH}-${GIT_LAST_REVISION}-${TARGET[2]}"
DIR_NAME[3]="${COMPILE_DATE_TIME}-${GIT_CURRENT_BRANCH}-${GIT_LAST_REVISION}-${TARGET[3]}"

OUTPUT_DIR[0]="$(pwd)/release/${DIR_NAME[0]}"
OUTPUT_DIR[1]="$(pwd)/release/${TARGET[1]}"
OUTPUT_DIR[2]="$(pwd)/release/${TARGET[2]}"
OUTPUT_DIR[3]="$(pwd)/release/${TARGET[3]}"

DEPLOY_DIR_NAME="deploy"

DEPLOY_DIR[0]="$(pwd)/release/${DIR_NAME[0]}/${DEPLOY_DIR_NAME}"
DEPLOY_DIR[1]="$(pwd)/release/${TARGET[1]}/${DEPLOY_DIR_NAME}"
DEPLOY_DIR[2]="$(pwd)/release/${TARGET[2]}/${DEPLOY_DIR_NAME}"
DEPLOY_DIR[3]="$(pwd)/release/${TARGET[3]}/${DEPLOY_DIR_NAME}"

if [ $OPT_BUILD_CONFIGURATION == "Release" ]; then
	if [ $OPT_BUILD_IDFA_MODE == "0" ]; then
		GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[0]="COMPILE_DATE_TIME=\"${COMPILE_DATE_TIME}\" GROWINGIO_SDK_VERSION=\"${SHORT_VERSION[0]}\" GROWING_SDK_DISTRIBUTED_MODE=0 GROWINGIO_NO_IFA=1"
	else
		GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[0]="COMPILE_DATE_TIME=\"${COMPILE_DATE_TIME}\" GROWINGIO_SDK_VERSION=\"${SHORT_VERSION[0]}\" GROWING_SDK_DISTRIBUTED_MODE=0"
	fi

	GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[1]="AUTOKit_COMPILE_DATE_TIME=\"${COMPILE_DATE_TIME}\" GROWINGIO_AUTO_SDK_VERSION=\"${SHORT_VERSION[1]}\""
	GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[3]="RNKit_COMPILE_DATE_TIME=\"${COMPILE_DATE_TIME}\" GROWINGIO_RN_SDK_VERSION=\"${SHORT_VERSION[3]}\""
fi

deployDir() {
	rm -rf "${OUTPUT_DIR[$1]}"
	mkdir -p "${OUTPUT_DIR[$1]}"
	mkdir -p "${DEPLOY_DIR[$1]}"
}

if [ $OPT_BUILD_COREKIT == 1 ]; then
	deployDir 0
fi

if [ $OPT_BUILD_AUTOKIT == 1 ]; then
	deployDir 1
fi

if [ $OPT_BUILD_PUBLIC == 1 ]; then
	deployDir 2
fi

if [ $OPT_BUILD_RNKIT == 1 ]; then
	deployDir 3
fi


PROJECT[0]="GrowingCoreKit.xcodeproj"
PROJECT[1]="GrowingAutoTrackKit.xcodeproj"
PROJECT[3]="GrowingReactNativeKit.xcodeproj"

STATIC_LIB[0]="GrowingCoreKit.xcframework"
STATIC_LIB[1]="GrowingAutoTrackKit.xcframework"
STATIC_LIB[3]="GrowingReactNativeKit.xcframework"

STATIC_LIBRARY_DIR_NAME[0]="GrowingIO-iOS-CoreKit"
STATIC_LIBRARY_DIR_NAME[1]="GrowingIO-iOS-AutoTrackKit"
STATIC_LIBRARY_DIR_NAME[2]="GrowingIO-iOS-publicHeader"
STATIC_LIBRARY_DIR_NAME[3]="GrowingIO-iOS-ReactNativeKit"

ZIP_NAME[0]="GrowingIO-iOS-CoreKit"
ZIP_NAME[1]="GrowingIO-iOS-AutoTrackKit"
ZIP_NAME[2]="GrowingIO-iOS-PublicHeader"
ZIP_NAME[3]="GrowingIO-iOS-ReactNativeKit"

buildSDK() {
	cd "${TARGET[$1]}"

	STATIC_LIBRARY_OUTPUT_DIR="${OUTPUT_DIR[$1]}/${STATIC_LIBRARY_DIR_NAME[$1]}"
	mkdir -p "${STATIC_LIBRARY_OUTPUT_DIR}"

	BUILD_PATH="$(pwd)/archive"
	rm -rf "${BUILD_PATH}"
	mkdir "${BUILD_PATH}"
	iphone_os_archive_path="${BUILD_PATH}/iphoneos"
	iphone_simulator_archive_path="${BUILD_PATH}/iphonesimulator"
	common_args="archive -project ${PROJECT[$1]} -scheme ${TARGET[$1]} -configuration ${OPT_BUILD_CONFIGURATION}"

	# generate ios-arm64 framework
	build_command="xcodebuild ${common_args} -destination \"generic/platform=iOS\" -archivePath ${iphone_os_archive_path} GCC_PREPROCESSOR_DEFINITIONS=\"${GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[$1]}\""
	echo "Executing: $build_command"
	xcodebuild ${common_args} -destination "generic/platform=iOS" -archivePath ${iphone_os_archive_path} GCC_PREPROCESSOR_DEFINITIONS="${GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[$1]}" || exit 1

	# generate ios-arm64_x86_64-simulator framework
	build_command="xcodebuild ${common_args} -destination \"generic/platform=iOS Simulator\" -archivePath ${iphone_simulator_archive_path} GCC_PREPROCESSOR_DEFINITIONS=\"${GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[$1]}\""
	echo "Executing: $build_command"
	xcodebuild ${common_args} -destination "generic/platform=iOS Simulator" -archivePath ${iphone_simulator_archive_path} GCC_PREPROCESSOR_DEFINITIONS="${GROWINGIO_GCC_PREPROCESSOR_DEFINITIONS[$1]}" || exit 1

	# create the xcframework bundle
	xcodebuild -create-xcframework \
    -archive ${iphone_os_archive_path}.xcarchive -framework ${TARGET[$1]}.framework \
    -archive ${iphone_simulator_archive_path}.xcarchive -framework ${TARGET[$1]}.framework \
    -output ${STATIC_LIBRARY_OUTPUT_DIR}/${TARGET[$1]}.xcframework

	# remove archive folder
    rm -rf "${BUILD_PATH}"

	# delete _CodeSignature folder in iphonesimulator framework which is unnecessary
	rm -rf ${STATIC_LIBRARY_OUTPUT_DIR}/${TARGET[$1]}.xcframework/ios-arm64_x86_64-simulator/${TARGET[$1]}.framework/_CodeSignature

	codesign --force --timestamp --sign "Apple Distribution: Beijing Yishu Technology Co., Ltd. (SXBU677CPT)" ${STATIC_LIBRARY_OUTPUT_DIR}/${TARGET[$1]}.xcframework

	# make zip
	cd ..
	cd "${OUTPUT_DIR[$1]}"
	zip -qry "${DEPLOY_DIR[$1]}/${ZIP_NAME[$1]}-${VERSION[$1]}.zip" "${STATIC_LIBRARY_DIR_NAME[$1]}"
	open "${OUTPUT_DIR[$1]}"

	cd - >/dev/null
}

pushd . >/dev/null
cd $(dirname ${USER_COMMAND})

if [ $OPT_BUILD_COREKIT == 1 ]; then
	buildSDK 0
fi

if [ $OPT_BUILD_AUTOKIT == 1 ]; then
	buildSDK 1
fi

if [ $OPT_BUILD_RNKIT == 1 ]; then
	buildSDK 3
fi

if [ $OPT_BUILD_PUBLIC == 1 ]; then
	STATIC_LIBRARY_OUTPUT_DIR="${OUTPUT_DIR[2]}/${STATIC_LIBRARY_DIR_NAME[2]}"
	mkdir -p "${STATIC_LIBRARY_OUTPUT_DIR}"

	cp "Growing/Growing.h" "${STATIC_LIBRARY_OUTPUT_DIR}"
	cp "Growing/module.modulemap" "${STATIC_LIBRARY_OUTPUT_DIR}"

	open "${OUTPUT_DIR[2]}"
fi
popd >/dev/null

COLORED_DONE="\033[32m\033[1mDONE\033[0m"
echo ""
echo -e "\033[32m\033[1mSummarize:\033[0m"

if [ $OPT_BUILD_PUBLIC == 1 ]; then
	echo -e "Build Public Header version:      \033[32m\033[1m${OPT_PUBLIC_VERSION}\033[0m"
fi

if [ $OPT_BUILD_COREKIT == 1 ]; then
	echo -e "Build GrowingCoreKit version:         \033[32m\033[1m${OPT_CORE_VERSION}\033[0m"
fi

if [ $OPT_BUILD_AUTOKIT == 1 ]; then
	echo -e "Build GrowingAutoTrackKit version:      \033[32m\033[1m${OPT_AUTO_VERSION}\033[0m"
fi

if [ $OPT_BUILD_RNKIT == 1 ]; then
	echo -e "Build GrowingReactNativeKit version:      \033[32m\033[1m${OPT_RN_VERSION}\033[0m"
fi

echo "Winner Winner, Chicken Dinner!"
