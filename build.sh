#/bin/bash

set -e

entry="${1:-"kernel"}"
arch="${2:-"x64"}"; arch="${arch,,}"; arch="${arch//-/_}"
protocol="${3:-"limine"}"; protocol="${protocol,,}"; protocol="${protocol//-/_}"

originalArch="${2:-"x64"}"
originalProtocol="${3:-"limine"}"

buildDir="${buildDir:="build"}"
binDir="${binDir:="bin"}"
tmpDir="${tmpDir:="tmp"}"

outputFile="${outputFile:="aureal"}"
outputFileFormat="${protocol}-${arch}_${outputFile}"
outputPath="$buildDir/$outputFileFormat"

# ===================================================================================================================
# Verifying entrypoint

if [ ! -e "$entry" ]; then
    echo "Error: Root directory '$entry' does not exist." >&2
    exit 1
elif [ ! -d "$entry" ]; then
    echo "Error: '$entry' is not a directory." >&2
    exit 1
fi

# ===================================================================================================================
# Validating architectures

ARCH_FLAGS=""
USER_FLAGS="${USER_FLAGS:=""}"
X86_FLAGS="-mno-80387 -mno-mmx -mno-sse -mno-sse2"
ARM_FLAGS="-mfpu=none -mfloat-abi=soft"

if [ "$(uname -m | grep '64')" != "" ]; then
    cpuBits="64"
else
    cpuBits="32"
fi

case "$arch" in
    x64|x86_64|ia_32e|ia32e|amd|amd64|intel64) arch="x64" ;;
    x86|i386|i686|ia_32|ia32|intel|intel32|amd32) arch="i386" ;;
    arm32|aarch32|armv7*|armv8-r) arch="aarch32" ;;
    arm64|aarch64|armv8*|armv9*) arch="aarch64" ;;
    arm)
        if [ "$cpuBits" == "64" ]; then arch="aarch64"
        else arch="aarch32"; fi
        ;;
esac

case "$arch" in
    x64)
        archTarget="elf_x86_64"
        archCanonical="x86-64"
        archClangTarget="x86_64"
        ARCH_FLAGS="$X86_FLAGS"
        ;;
    i386|aarch32|aarch64)
        echo "Unsupported architecture '$originalArch'"
        exit 1
        ;;
    *)
        echo "Unknown architecture '$originalArch'"
        exit 1
        ;;
esac

# ===================================================================================================================
# Validating boot protocol

case "$protocol" in
    limine|limine64|limine_bios|limine_uefi)
        protocol="limine"

        if [[ -z "$LIMINE" ]]; then
            if command -v "limine" >/dev/null 2>&1; then
                LIMINE="limine"
            else
                echo "Using limine protocol but found no 'limine' command. Please get one from limine's repository."
                exit 1
            fi
        fi

        isoRoot="${isoRoot:="iso_root"}"
        declare -A LIMINE_FILES_HINT=(
            ["$isoRoot/EFI/BOOT/BOOTX64.EFI"]="UEFI x86_64 bootloader, comes with Limine"
            ["$isoRoot/EFI/BOOT/BOOTIA32.EFI"]="UEFI i386 bootloader, comes with Limine"
            ["$isoRoot/boot/limine/limine-bios-cd.bin"]="BIOS boot image, shipped with Limine"
            ["$isoRoot/boot/limine/limine-uefi-cd.bin"]="UEFI boot image, shipped with Limine"
        )

        for f in "${!LIMINE_FILES_HINT[@]}"; do
            if [[ ! -f "$f" ]]; then
                echo "Error: Missing required file: $f" >&2
                echo "Hint : ${LIMINE_FILES_HINT[$f]}" >&2
                echo "       Try re-cloning the repo or copying from Limine’s release." >&2
                exit 1
            fi
        done
        ;;
    multiboot|multiboot1|multiboot2|mb|mb1|mb2|stivale|stivale1|stivale2|uefi|uefi32|uefi64|efi|efi32|efi64|bios)
        echo "Unsupported protocol '$originalProtocol'"
        exit 1
        ;;
    *)
        echo "Unknown protocol '$originalProtocol'"
        exit 1
        ;;
esac

# ===================================================================================================================
# Validating Tools

if [[ -z "$CC" ]]; then
    if command -v "clang" >/dev/null 2>&1; then
        CC="clang"
    elif command -v "gcc" >/dev/null 2>&1; then
        CC="gcc"
    else
        echo "Error: Can't find compiler, please install any. Recommended compiler are clang or gcc." >&2
        exit 1
    fi
fi

if [[ -z "$LD" ]]; then
    if command -v "lld" >/dev/null 2>&1; then
        if command -v "ld.lld" >/dev/null 2>&1; then
            LD="ld.lld"
        elif command -v "ld64.lld" >/dev/null 2>&1; then
            LD="ld64.lld"
        else
            echo "Error: Invalid LLD install. Can't find ld.lld or ld64.lld" >&2
            exit 1
        fi
    elif command -v "ld" >/dev/null 2>&1; then
        LD="ld"
    else
        echo "Error: Can't find linker, please install any. Recommended linker are LLVM lld or GNU ld." >&2
        exit 1
    fi
fi

if [[ -z "$XORRISO" ]]; then
    if ! command -v "xorriso" >/dev/null 2>&1; then
        echo "Error: Can't find xorriso. Please install xorriso." >&2
        exit 1
    else
        XORRISO="xorriso"
    fi
fi

# ===================================================================================================================
# Finding files, setup compilation, and the compilation itself.

FIND_RULES=(-not \( -path "$entry/arch/*" -and -not -path "$entry/arch/$arch/*" \))

linkerScript="kernel/boot_protocol/$protocol/${arch}_linker.ld"
EXTRA_FLAGS="-fno-stack-check -fno-stack-protector  -fno-lto -fno-PIC \
             -ffunction-sections -fdata-sections -mno-red-zone -mcmodel=kernel"
KERNEL_LDFLAGS="max-page-size=0x1000"

if [ "$entry" == "kernel" ]; then
    FIND_RULES+=(-and -not \( -path "$entry/boot_protocol/*" -and -not -path "$entry/boot_protocol/$protocol/*" \))
else
    linkerScript="$entry/${arch}_linker.ld"
    EXTRA_FLAGS="-fstack-protector"
    KERNEL_LDFLAGS=""
fi

mkdir -p "$binDir"
mkdir -p "$tmpDir"

maxJobs=${JOBS:-$(nproc)}
compiledFilesCount=0
cachedFilesCount=0
archUppercase="${arch^^}"

CFLAGS="" 
CFLAGS="$CFLAGS -Wall -Wextra -Werror -std=c17 -O2"
CFLAGS="$CFLAGS -nostdlib -nodefaultlibs"
CFLAGS="$CFLAGS -ffreestanding -fno-builtin"
CFLAGS="$CFLAGS -fno-exceptions -fno-rtti"
CFLAGS="$CFLAGS -m$cpuBits -march=$archCanonical"
CFLAGS="$CFLAGS -DBUILD_$archUppercase -DBUILD_${cpuBits}BITS"
CFLAGS="$CFLAGS $ARCH_FLAGS $EXTRA_FLAGS $USER_FLAGS"
CFLAGS="$CFLAGS -I$entry"

if [ -d "$entry/lib" ]; then
    CFLAGS="$CFLAGS -I$entry/lib"
fi

if [[ "$CC" == "clang" ]]; then
    CFLAGS="$CFLAGS -target $archClangTarget-unknown-none-elf"
fi

LDFLAGS="-m $archTarget -nostdlib -static -z $KERNEL_LDFLAGS --gc-sections -T $linkerScript"

# ===================================================================================================================
# Actually no, the compilation starts just now.

export binDir
export tmpDir
export CC
export CFLAGS

declare -a objFiles
declare -a tmpFiles
declare -a taskPids
declare -a cFiles

compileC () {
    local file="$1"
    local fileOut="$binDir/$file.o"
    local fileJson="$tmpDir/$file.json"
    
    mkdir -p "$(dirname "$fileOut")"
    mkdir -p "$(dirname "$tmpDir/$file")"

    echo "[COMPILE] Compiling $file"
    $CC $CFLAGS -c "$file" -o "$fileOut" -MJ "$fileJson"
}

processFiles () {
    local findRules=("$@")   # everything else is the exclusion group

    while IFS= read -r -d '' file; do
        fileOut="$binDir/$file.o"
        objFiles+=("$binDir/$file.o")

        # Skip if object is newer than source
        if [[ -f "$fileOut" && "$fileOut" -nt "$file" ]]; then
            cachedFilesCount=$((cachedFilesCount + 1))
            continue
        fi

        compileC "$file" &
        tmpFiles+=("$tmpDir/$file.json")
        taskPids+=($!)
        compiledFilesCount=$((compiledFilesCount + 1))

        # If we hit the job cap, wait for *any* to finish
        if [ "$(jobs -rp | wc -l)" -ge "$maxJobs" ]; then
            wait -n
        fi
    done < <(
        find "$entry" \
        -type f -name "*.c" \
        "${findRules[@]}" \
        -print0
    )
}

processFiles "${FIND_RULES[@]}"

for pid in "${taskPids[@]}"; do
    wait "$pid" || {
        echo "Error: Background process with PID $pid failed. Exiting."
        exit 1
    }
done

echo "$compiledFilesCount files are compiled. Used $cachedFilesCount cached files."

# ===================================================================================================================
# Merge JSON fragments
createCompileCommands () {
    local outJson="compile_commands.json"
    local first=1
    echo -n "[" > "$outJson"
    for f in "${tmpFiles[@]}"; do
        local entry=$(sed 's/,$//' "$f")
        if [ $first -eq 0 ]; then
            echo "," >> "$outJson"
        else
            echo "" >> "$outJson"
        fi
        echo -n "   $entry" >> "$outJson"
        first=0
    done
    echo "" >> "$outJson"
    echo -n "]" >> "$outJson"
}

createCompileCommands

link () {
    if [ "$compiledFilesCount" == "0" ] && [ -f "$outputPath.raw" ]; then
        echo "[LINKING] Skipping linking, files are up to date."
        return
    fi

    mkdir -p "$buildDir"
    echo "[LINKING] Linking files"
    $LD $LDFLAGS "${objFiles[@]}" -o "$outputPath.raw"
}

link

buildLimine () {
    mkdir -p "$isoRoot/boot"
    mkdir -p "$isoRoot/boot/limine"
    mkdir -p "$isoRoot/EFI/BOOT"

    cp "$outputPath.raw" "$isoRoot/boot/${arch}_aureal"
    cp "$outputPath.raw" "$isoRoot/boot/aureal"

    if [ "$compiledFilesCount" == "0" ] && [ -f "$outputPath.iso" ]; then
        echo "[ISO BUILDING] Skipping ISO building, files are up to date."
        return
    fi

    echo "[XORRISO] Building Limine ISO"
    $XORRISO -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
        -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin \
        -efi-boot-part --efi-boot-image --protective-msdos-label \
        "$isoRoot" -o "$outputPath.iso"
    
    echo "[BIOS INSTALL] Building Limine ISO"
    $LIMINE bios-install "$outputPath.iso"

    echo "TO TEST:"
    echo "qemu-system-$archClangTarget -cdrom $outputPath.iso"
}

if [ "$protocol" == "limine" ]; then buildLimine; fi