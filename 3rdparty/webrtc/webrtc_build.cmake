# Build WebRTC from source alongside Open3D.
#
# You have two ways to enable WebRTC in Open3D.
# - Method 1: Set `-DBUILD_WEBRTC_FROM_SOURCE=OFF` and Open3D will fetch and use
#             a pre-compiled WebRTC package.
# - Method 2: Set `-DBUILD_WEBRTC_FROM_SOURCE=ON` and this webrtc_build.cmake
#             will be used. This is only recommended for advanced users.
# - Note    : The pre-compiled WebRTC package used in Method 1 is generated by
#             .github/workflows/Dockerfile.webrtc. You can build your own
#             pre-compiled WebRTC package by building this docker container.
#
# If you select Method 2, you need:
# 1) Download depot_tools, webrtc to following directories:
#    ├── Oepn3D
#    ├── depot_tools
#    └── webrtc
#        ├── .gclient
#        └── src
#
# 2) depot_tools and webrtc have compatible versions, see:
#    https://chromium.googlesource.com/chromium/src/+/master/docs/building_old_revisions.md
#
# 3) Apply the following patch to enable GLIBCXX_USE_CXX11_ABI selection:
#    - 0001-build-enable-rtc_use_cxx11_abi-option.patch        # apply to webrtc/src
#    - 0001-src-enable-rtc_use_cxx11_abi-option.patch          # apply to webrtc/src/build
#    - 0001-third_party-enable-rtc_use_cxx11_abi-option.patch  # apply to webrtc/src/third_party
#    Note that these patches may or may not be compatible with your custom
#    WebRTC commits. You may have to patch them manually.

include(ExternalProject)

# Force WEBRTC_IS_DEBUG to ON if WIN32 Debug, else allow user setting.
cmake_dependent_option(WEBRTC_IS_DEBUG "WebRTC Debug build" OFF
    "NOT CMAKE_BUILD_TYPE STREQUAL Debug OR NOT WIN32" ON)

# Set paths
set(WEBRTC_ROOT ${CMAKE_BINARY_DIR}/webrtc/src/ext_webrtc)
set(DEPOT_TOOLS_ROOT ${PROJECT_SOURCE_DIR}/../depot_tools)

# Set WebRTC build type path
if(WEBRTC_IS_DEBUG)
    set(WEBRTC_BUILD Debug)
else()
    set(WEBRTC_BUILD Release)
endif()
set(WEBRTC_NINJA_ROOT ${WEBRTC_ROOT}/src/out/${WEBRTC_BUILD})

# Common configs for WebRTC
include(${PROJECT_SOURCE_DIR}/3rdparty/webrtc/webrtc_common.cmake)

# Creates args.gn
if(NOT EXISTS ${CMAKE_BINARY_DIR}/args.gn)
    get_webrtc_args(WEBRTC_ARGS)
    file(WRITE ${CMAKE_BINARY_DIR}/args.gn ${WEBRTC_ARGS})
    message(STATUS "Configs written to ${CMAKE_BINARY_DIR}/args.gn")
endif()

ExternalProject_Add(
    ext_webrtc
    PREFIX webrtc
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -E rm -rf ext_webrtc
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/../webrtc ext_webrtc
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/args.gn
        ${WEBRTC_NINJA_ROOT}/args.gn
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    BUILD_IN_SOURCE ON
    ${BUILD_BYPRODUCTS} ${EXTRA_WEBRTC_OBJS}
)

# libwebrtc.a
ExternalProject_Add_Step(ext_webrtc build_webrtc
    COMMAND ${DEPOT_TOOLS_ROOT}/gn gen .
    COMMAND ${DEPOT_TOOLS_ROOT}/ninja ${NINJA_TARGETS}
    WORKING_DIRECTORY ${WEBRTC_NINJA_ROOT}
    DEPENDEES build
    DEPENDERS install
)

# libwebrtc_extra.a
add_library(webrtc_extra STATIC ${EXTRA_WEBRTC_OBJS})
set_source_files_properties(${EXTRA_WEBRTC_OBJS} PROPERTIES GENERATED TRUE)
add_dependencies(webrtc_extra ext_webrtc)
set_target_properties(webrtc_extra PROPERTIES LINKER_LANGUAGE CXX)
set_target_properties(webrtc_extra PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY ${WEBRTC_NINJA_ROOT}/obj
)

# Dummy target that depends on all WebRTC targets.
add_custom_target(ext_webrtc_all)
add_dependencies(ext_webrtc_all ext_webrtc webrtc_extra)

# Variables consumed by find_dependencies.cmake
set(WEBRTC_INCLUDE_DIRS
    ${WEBRTC_ROOT}/src/
    ${WEBRTC_ROOT}/src/third_party/abseil-cpp/
    ${WEBRTC_ROOT}/src/third_party/jsoncpp/source/include/
    ${WEBRTC_ROOT}/src/third_party/jsoncpp/generated/
    ${WEBRTC_ROOT}/src/third_party/libyuv/include/
)
set(WEBRTC_LIB_DIR ${WEBRTC_NINJA_ROOT}/obj)
set(WEBRTC_LIBRARIES
    webrtc
    webrtc_extra
)
