include(ExternalProject)

ExternalProject_Add(
    ext_jsoncpp
    PREFIX jsoncpp
    GIT_REPOSITORY https://github.com/open-source-parsers/jsoncpp.git
    GIT_TAG 1.9.4
    GIT_SHALLOW ON  # Do not download the history.
    UPDATE_COMMAND ""
    PATCH_COMMAND git apply ${Open3D_3RDPARTY_DIR}/jsoncpp/0001-optional-CXX11-ABI-and-MSVC-runtime.patch
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_STATIC_LIBS=ON
        -DBUILD_OBJECT_LIBS=OFF
        -DJSONCPP_WITH_TESTS=OFF
        -DJSONCPP_USE_CXX11_ABI=${GLIBCXX_USE_CXX11_ABI}
        -DJSONCPP_STATIC_WINDOWS_RUNTIME=${STATIC_WINDOWS_RUNTIME}
        ${ExternalProject_CMAKE_ARGS_hidden}
    BUILD_BYPRODUCTS
        <INSTALL_DIR>/${Open3D_INSTALL_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}jsoncpp${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(ext_jsoncpp INSTALL_DIR)
set(JSONCPP_INCLUDE_DIRS ${INSTALL_DIR}/include/) # "/" is critical.
set(JSONCPP_LIB_DIR ${INSTALL_DIR}/${Open3D_INSTALL_LIB_DIR})
set(JSONCPP_LIBRARIES jsoncpp)
