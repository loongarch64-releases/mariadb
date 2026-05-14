#!/bin/bash
set -euo pipefail

UPSTREAM_OWNER=MariaDB
UPSTREAM_REPO=server
VERSION="${1}"
echo "   🏢 Org:   ${UPSTREAM_OWNER}"
echo "   📦 Proj:  ${UPSTREAM_REPO}"
echo "   🏷️  Ver:   ${VERSION}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DISTS="${ROOT_DIR}/dists"
SRCS="${ROOT_DIR}/srcs"

mkdir -p "${DISTS}/${VERSION}" "${SRCS}"

# ==========================================
# 👇 用户自定义构建逻辑 (示例)
# ==========================================

echo "🔧 Compiling ${UPSTREAM_OWNER}/${UPSTREAM_REPO} ${VERSION}..."

# 1. 准备阶段：安装依赖、下载代码、应用补丁等
prepare()
{
    echo "📦 [Prepare] Setting up build environment..."
 
    git clone -b "${VERSION}" --depth 1 "https://github.com/${UPSTREAM_OWNER}/${UPSTREAM_REPO}.git" "${SRCS}/${VERSION}"

    pushd "${SRCS}/${VERSION}"
    mv debian/changelog debian/changelog.bak
    export DEBEMAIL="developers@lists.mariadb.org"
    export DEBFULLNAME="MariaDB Developers"   
    dch --create --package mariadb -v "1:${VERSION#mariadb-}" -D sid "Initial Release"
    popd

    echo "✅ [Prepare] Environment ready."
}

# 2. 编译阶段：核心构建命令
build()
{
    echo "🔨 [Build] Compiling source code..."
    
    pushd "${SRCS}/${VERSION}"
    ./debian/autobake-deb.sh
    popd

    echo "✅ [Build] Compilation finished."
}

# 3. 后处理阶段：整理产物、清理临时文件、验证版本
post_build()
{
    echo "📦 [Post-Build] Organizing artifacts..."
    
    pushd "${SRCS}"
    mkdir -p /tmp/mariadb_deb
    cp mariadb-server_*.deb \
       mariadb-server-core_*.deb \
       mariadb-client_*.deb \
       mariadb-client-core_*.deb \
       mariadb-common_*.deb \
       mysql-common_*.deb \
       mariadb-backup_*.deb \
       libmariadb3_*.deb   \
       libmariadbd19_*.deb /tmp/mariadb_deb
    tar -czf "${DISTS}/${VERSION}/mariadb_deb.tar.gz" -C /tmp ./mariadb_deb
    chown -R "${HOST_UID}:${HOST_GID}" "${DISTS}" "${SRCS}"
    
    echo "✅ [Post-Build] Artifacts ready in ./dists/${VERSION}."
}

# 主入口
main()
{
    prepare
    build
    post_build
}

main

# ==========================================
# 👆 自定义逻辑结束
# ==========================================

cat > "${DISTS}/${VERSION}/release.txt" <<EOF
Project: ${UPSTREAM_REPO}
Organization: ${UPSTREAM_OWNER}
Version: ${VERSION}
Build Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "✅ Compilation finished."
ls -lh "${DISTS}/${VERSION}"
