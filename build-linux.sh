
#!/bin/sh

# This script assembles the KafeinOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Linux)
# Updated to use mtools (mcopy) to bypass unstable loopback mounting.

# Gerekli araçların kontrolü (mtools)
if ! command -v mcopy >/dev/null 2>&1; then
    echo "Error: 'mtools' is required but not installed."
    echo "Install it via: sudo apt install mtools"
    exit 1
fi

if [ ! -e disk_images/kafeinos.flp ]
then
    echo ">>> Creating new KafeinOS floppy image..."
    mkdosfs -C disk_images/kafeinos.flp 1440 || exit
fi

echo ">>> Assembling bootloader..."
nasm -O0 -w+orphan-labels -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit

echo ">>> Assembling KafeinOS kernel..."
cd source
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..

echo ">>> Assembling programs..."
cd programs
for i in *.asm
do
    [ -e "$i" ] || continue
    nasm -O0 -w+orphan-labels -f bin "$i" -o `basename "$i" .asm`.bin || exit
done
cd ..

echo ">>> Adding bootloader to floppy image..."
dd status=noxfer conv=notrunc if=source/bootload/bootload.bin of=disk_images/kafeinos.flp || exit

echo ">>> Copying KafeinOS kernel and programs using mtools..."
# mcopy ile imajı mount etmeden doğrudan içine kopyalıyoruz
mcopy -o -i disk_images/kafeinos.flp source/kernel.bin ::/

# Programları ve ek kaynakları kopyala (Hata payını önlemek için tek tek veya toplu kontrol)
for f in programs/*.bin programs/*.bas programs/sample.pcx programs/vedithlp.txt programs/gen.4th programs/hello.512
do
    if [ -e "$f" ]; then
        mcopy -o -i disk_images/kafeinos.flp "$f" ::/
    fi
done

echo ">>> Creating CD-ROM ISO image..."
rm -f disk_images/kafeinos.iso
mkisofs -quiet -V 'KafeinOS' -input-charset iso8859-1 -o disk_images/kafeinos.iso -b kafeinos.flp disk_images/ || exit

echo '>>> Done!'
