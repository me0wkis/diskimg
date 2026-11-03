#!/usr/bin/env bash
# Демонстрация всех операций комплекса (для защиты лабораторной).
set -euo pipefail
cd "$(dirname "$0")"
D="python3 -m diskimg"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
mkdir -p "$W/src/Документы" && echo "Привет" > "$W/src/Документы/отчёт.txt" && head -c 100000 /dev/urandom > "$W/src/data.bin"
echo "x" > "$W/new.txt"

step() { echo; echo "===== $* ====="; }

step "1. Дискета 1.44M (FAT12)"
$D create "$W/floppy.img" --type floppy --floppy 1.44M --label DISK1
$D add "$W/floppy.img" "$W/src/Документы" "$W/src/data.bin"
$D tree "$W/floppy.img"

step "2. CD/DVD (ISO 9660 + Joliet): создание, добавление, удаление"
$D create "$W/cd.iso" --label LAB_CD --from "$W/src"
$D add "$W/cd.iso" "$W/new.txt" -d /добавлено
$D rm "$W/cd.iso" /data.bin
$D ls -l -R "$W/cd.iso"

step "3. VHD dynamic + MBR + FAT32"
$D create "$W/disk.vhd" --size 300M --fs fat32 --label DATA --from "$W/src"
$D info "$W/disk.vhd"

step "4. VHD fixed + MBR + NTFS"
$D create "$W/ntfs.vhd" --size 100M --fs ntfs --vhd-type fixed --label WIN --from "$W/src"
$D add "$W/ntfs.vhd" "$W/new.txt" -n заменённый.txt
$D mkdir "$W/ntfs.vhd" --parents /a/b/c
$D rm "$W/ntfs.vhd" -r /Документы
$D tree "$W/ntfs.vhd"

step "5. Извлечение и сверка"
$D extract "$W/disk.vhd" -o "$W/out" -q
diff -r "$W/src" "$W/out" && echo "Содержимое совпадает"
$D cat "$W/ntfs.vhd" /заменённый.txt

step "6. Конвертация контейнера VHD dynamic → raw"
$D convert "$W/disk.vhd" "$W/disk.raw" --to raw
$D ls "$W/disk.raw"
