# OPPO Reno 5 Lite Unlock

[English guide](README.en.md)

OPPO Reno 5 Lite **CPH2205 / Android 13 / CPH2205_11_F.72** üzerinde preloader patchi ile fastboot erişimi açıp bootloader kilidini kaldırma deneyiminin Türkçe rehberi.

## Sonuç ve kapsam

Tek CPH2205/F.72 cihazında denendi. BOOT1 yazımı geri okunup byte düzeyinde karşılaştırıldı. Kullanıcı normal açılış ve fastboot unlock sonrasında Android'den `ro.boot.flash.locked=0`, `ro.boot.vbmeta.device_state=unlocked`, `ro.boot.verifiedbootstate=orange` çıktılarını paylaştı. LineageOS 20 DSU açılışı ADB ile doğrulandı; SIM/RIL sorunu görüldü. Bu sonuçlar başka cihaz veya sürüm için garanti değildir.
Bu rehber tüm Reno5 modellerine veya başka firmware sürümlerine uyumluluk garantisi vermez. Yöntem bize ait bir exploit değildir: patch aracı [Shocked-Cat/oppo-mtk-fastboot-unlock](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock), flash/okuma aracı [bkerler/mtkclient](https://github.com/bkerler/mtkclient) projesidir. İncelenen patch commit: `ecf8e2c6f967706e6ab55c4774141abb5d78d12f`; kullanılan MTKClient: 2.1.4, commit `cd25cf9c1ff6d36e82697ac2c798e69e9cfb78c3`.

## Risk

**Preloader yazımı cihazı açılmaz hâle getirebilir; BROM erişimi kaybolursa test point veya servis gerekebilir. Bootloader unlock kişisel verileri siler.** Yedek kurtarma garantisi değildir. GSI veya patchli vbmeta'yı kilit açıldığını doğrulamadan yazmayın. Başka telefona ait preloader kullanmayın; cihazınızın kendi yedeğini patchleyin.

**Cihazın brick olması, veri kaybı veya başka bir zarar oluşması durumunda sorumluluk kabul etmiyorum. İşlemleri kendi sorumluluğunuzda uygulayın.**

Bu depoda cihazımızdan alınmış firmware, preloader, BOOT1/BOOT2 veya kişisel yedek bulunmaz. Her kullanıcı kendi cihazının yedeğini alıp kendisi patchlemelidir. `tools/` yalnız upstream patch kodunu ve lisansını içerir. `SHA256SUMS` araç dosyalarının bütünlüğünü kontrol eder.

## Gerekenler

- Kendi CPH2205 cihazınız; bu deneyim F.72 / Android 13 içindir.
- Linux'ta çalışan MTKClient, Python 3, adb ve fastboot. MTKClient kurulumu ve udev izinleri için [resmî yönerge](https://github.com/bkerler/mtkclient/blob/main/README-INSTALL.md).
- Geliştirici seçeneklerinde **OEM kilit açma açık**, USB hata ayıklama açık.
- Kişisel dosya yedeği, ROM bölüm yedekleri ve ayrıca UFS BOOT1/BOOT2 yedekleri. Normal bölüm dökümü ayrı UFS boot alanlarını içermeyebilir.

Komutlardaki `python mtk.py` için MTKClient'in kurulu olduğu klasörde, gerekli bağımlılıkları içeren Python ortamını kullanın (örneğin `./.venv/bin/python mtk.py`). Bu rehberde `backup/` klasörü MTKClient klasörünün içindedir. ADB ve fastboot komutları bilgisayar terminalinde çalıştırılır.

## MTKClient GUI kurulumu ve açılması (Ubuntu/Linux)

```bash
sudo apt install git build-essential python3-venv python3-dev libssl-dev libusb-1.0-0 libxcb-cursor0 adb fastboot
git clone https://github.com/bkerler/mtkclient.git
cd mtkclient
git checkout cd25cf9c1ff6d36e82697ac2c798e69e9cfb78c3
python3 -m venv .venv
./.venv/bin/python -m pip install -r requirements.txt
./.venv/bin/python -m pip install . keystone-engine capstone unicorn
sudo cp Setup/Linux/52-mtk.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb
./.venv/bin/python mtk_gui.py
```

MTKClient kaynak kodu ve GUI, yukarıdaki resmî depodan birlikte indirilir. Rehberdeki başlatıcıyı da kullanabilirsiniz: `sh tools/open-mtk-gui.sh /tam/yol/mtkclient`. Başlatıcı yalnız GUI açar, telefona otomatik yazma yapmaz.

Bu GUI açma komutudur. Flash komutlarını kullanırken GUI'yi kapatın; iki uygulama aynı USB bağlantısını kullanmasın. Komut satırı adımlarında `python mtk.py` yerine `./.venv/bin/python mtk.py` kullanabilirsiniz.

## Dahil edilen patch aracını kullanma

Bu rehber deposunun klasöründe, **kendi 4 MiB UFS BOOT1 yedeğinizi** göstererek:

```bash
python3 tools/path_preloader.py "/tam/yol/kendi-ufs-boot1-original.bin" boot1-patched.bin
```

Çıktı çalıştırdığınız klasördeki `preloader_path/boot1-patched.bin` olur. Upstream script çıktı adı aynıysa mevcut patch dosyasının üstüne yazabilir; özgün dosyanızı bu çıktı klasöründe tutmayın. `preloader-original.bin` RAW dosyasını bu araca girdi vermeyin.

Araç bütünlüğünü kontrol etmek için `sha256sum -c SHA256SUMS` kullanın. Kendi yedeklerinizi veya patchli dosyalarınızı GitHub'a yüklemeyin.

## 1. Özgün boot alanlarını yedekle

MTKClient GUI'yi kapatın. Telefonu kapatıp USB'yi çıkarın. Okuma komutunu başlatın; ses tuşlarını basılı tutarak USB'yi bağlayıp BROM bağlantısını bekleyin. Bu cihazda ilk bağlantı Preloader modunda olsa da MTKClient BROM'a geçiş sağlayabildi.

```bash
mkdir -p backup
python mtk.py ro 0 0x400000 backup/ufs-boot1-original.bin --parttype boot1
python mtk.py ro 0 0x400000 backup/ufs-boot2-original.bin --parttype boot2
```

**4 MiB uzunluğu yalnız bu cihazın logundaki BOOT1/BOOT2 boyutuna dayanır.** Log farklı boyut bildiriyorsa bu komutları aynen kullanmayın. İki dosya da 4.194.304 bayt olmalıdır. Başarılı okuma mesajını ve dosya boyutunu kontrol edin:

```bash
wc -c backup/ufs-boot1-original.bin backup/ufs-boot2-original.bin
sha256sum backup/ufs-boot1-original.bin backup/ufs-boot2-original.bin
```

Yedekleri ayrıca başka bir diske kopyalayın. Bu deneyimde BOOT1/BOOT2 içerikleri aynıydı; diğer cihazlarda aynı olmasını varsaymayın.

## 2. Patchi bilgisayarda oluştur

Patch projesini ayrı klasöre indirin. Aşağıdaki örneği MTKClient klasöründen çalıştırın:

```bash
git clone https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock.git patch-tool
git -C patch-tool checkout ecf8e2c6f967706e6ab55c4774141abb5d78d12f
cd patch-tool
python3 path_preloader.py ../backup/ufs-boot1-original.bin ufs-boot1-patched.bin
cd ..
```

Çıktı: `patch-tool/preloader_path/ufs-boot1-patched.bin`. **Araç tam 4 MiB `UFS_BOOT` imajını kullanır; çıkarılmış küçük RAW preloader bu araç için uygun değildir.** Boyut/başlık/flag bulunamadı uyarılarını atlamayın; script devam etmeyi sorarsa incelemeden onaylamayın.

Bu deneyimde kaynakta `UFS_BOOT`, `BRLYT` ve tek bir `AND_ROMINFO_v` bloğu bulundu. Araç kod başlangıcını `0x1000` → `0x2000` taşıdı, BRLYT başlığını güncelledi ve `0x1000` konumuna kopyalanan ROMINFO bloğunun `0x104c` kilit bayrağını `0x22` → `0x00` değiştirdi. Taşınan preloader kodunun byte eşliği ve 4 MiB çıktı boyutu kontrol edildi. Bu kontroller telefonun patchi kabul edeceğini garanti etmez.

## 3. Yalnız BOOT1'e yaz ve geri okuyarak doğrula

**Bu adım telefona kalıcı yazma yapar.** Önce mevcut BOOT1'i tekrar okuyup özgün yedekle karşılaştırın:

```bash
python mtk.py ro 0 0x400000 backup/ufs-boot1-before-write.bin --parttype boot1
cmp backup/ufs-boot1-original.bin backup/ufs-boot1-before-write.bin
```

`cmp` çıktı vermeden kod 0 ile bitmelidir. Fark varsa durun. Doğru cihaz ve kendi yedeğiniz olduğundan emin olun.

Bu CPH2205 bölüm tablosunda A/B bölüm adları yoktu; upstream yönergesindeki A/B olmayan cihaz yolu izlenerek yalnız BOOT1 yazıldı. BOOT2'yi otomatik olarak patchlemeyin; A/B cihazlarda bu rehberi doğrudan uygulamayın.

```bash
python mtk.py wf patch-tool/preloader_path/ufs-boot1-patched.bin --parttype boot1
python mtk.py ro 0 0x400000 backup/ufs-boot1-after-write.bin --parttype boot1
cmp patch-tool/preloader_path/ufs-boot1-patched.bin backup/ufs-boot1-after-write.bin
```

Yazma başarı logunu ve `cmp` sonucunu kontrol edin. Hata veya farklılık varsa **reboot yapmayın**. BOOT2 bu işlemde değiştirilmez.

## 4. Fastboot'a gir ve bootloader'ı aç

Geri okuma eşleştiğinde:

```bash
python mtk.py reset
```

USB'yi çıkarın. Bu deneyimde telefon normal açıldı. Android açılınca USB'yi bağlayın ve bilgisayarın USB hata ayıklama yetkisini onaylayın:

```bash
adb reboot bootloader
fastboot devices
```

Bu deneyimde fastboot ekranı `fastboot unlock verify ok` gösterdi. Bu mesaj tek başına kalıcı bootloader unlock kanıtı değildir.

**Bir sonraki komut kişisel verileri siler:**

```bash
fastboot flashing unlock
```

Telefonun onay ekranını okuyun ve belirtilen ses tuşuyla onaylayın. Başarı çıktısından sonra:

```bash
fastboot reboot
```

Kurulum ekranını tamamlayın; USB hata ayıklamayı tekrar açın. Kilit durumunu doğrulayın:

```bash
adb shell getprop ro.boot.flash.locked
adb shell getprop ro.boot.vbmeta.device_state
adb shell getprop ro.boot.verifiedbootstate
```

Açık kilitle beklenen sonuçlar `0`, `unlocked`, `orange` değerleridir. Boş veya çelişkili çıktıyı başarı olarak değerlendirmeyin.

## Sorunlar ve geri dönüş sınırı

- MTKClient'te `seccfg unlock` yazma başarısı bu cihazda yeniden açılıştan sonra Android'in `locked/green` bildirmesini değiştirmedi. Bu yüzden tek başına yeterli sayılmadı.
- Kullanılan MTKClient sürümünün non-XML UFS `lu1/lu2` yolunda yazılım hatası vardı. `ro ... --parttype boot1/boot2` okuması çalıştı; kod değiştirilmedi.
- Kilit açılmadan patchli vbmeta yazıldığında kullanıcı boot/recovery doğrulama hatası bildirdi ve özgün vbmeta'yı geri yükledi. Bu rehber vbmeta patchlemeyi veya GSI flashlamayı içermez.
- Cihaz hâlâ DA/BROM'da erişilebilirken, BOOT1'i özgün hâline döndürmek için **doğru cihazın özgün tam BOOT1 yedeğiyle** aşağıdaki yazma değerlendirilebilir. Geri okuma yine zorunludur. Cihaz erişilemiyorsa bu komut kurtarma sağlamaz; servis/test point gerekebilir.

```bash
python mtk.py wf backup/ufs-boot1-original.bin --parttype boot1
python mtk.py ro 0 0x400000 backup/ufs-boot1-restored.bin --parttype boot1
cmp backup/ufs-boot1-original.bin backup/ufs-boot1-restored.bin
```

Preloader geri yüklemek Android/veri/seccfg değişikliklerinin tümünü geri almaz. Modifiye sistem varken `fastboot flashing lock` çalıştırmayın. Rastgele downgrade, `Format All` veya başka cihaz firmware'i kullanmayın.

## Kaynaklar

- [Shocked-Cat: patch aracı ve upstream yöntemi](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock)
- [Upstream CPH2205 destek listesi](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock/blob/main/support_list.md)
- [MTKClient kullanım yönergesi](https://github.com/bkerler/mtkclient/blob/main/README-USAGE.md)
- [Android bootloader kilit durumu](https://source.android.com/docs/core/architecture/bootloader/locking_unlocking)

## Lisans

Bu depodaki özgün rehber metni CC BY 4.0 altında paylaşılır; bkz. [LICENSE](LICENSE). Bağlantı verilen araçlar kendi lisanslarına tabidir. `tools/path_preloader.py` değişiklik yapılmadan upstream kaynaktan alınmıştır; AGPL-3.0 lisansı ve commit bilgisi `tools/` altında korunur. Cihaza ait imajlar dağıtılmaz.
