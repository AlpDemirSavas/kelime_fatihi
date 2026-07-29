# Türkçe sözlük stratejisi — sözlük kalite yaması

Kelime Fatihi'nin sözlük ilkesi: **çekimli yüzey biçimlerini yapay biçimde üretmeden, gerçek ve oynanabilir Türkçe kelime havuzunu geniş tutmak; nadir/eski kelimeleri oyuncuya zorunlu hedef olarak dayatmamak.**

## Paket içindeki havuzlar

- `core_words.txt`: çevrimdışı doğrulama/bonus için **27.854** kelime.
- `level_words.txt`: Sonsuz Fetih zorunlu hedeflerinde kullanılabilen **23.538** temiz kelime.
- `level_seeds.txt`: Bölüm 1–10.000 için **10.000 benzersiz harf çemberi tohumu**. Bu dosyadaki satır artık mutlaka zorunlu cevap olmak zorunda değildir; öncelikle harf multiset'ini sabit tutar.
- `daily_words.txt`: Günün Kelimesi için kürasyonlu 5 harfli cevaplar.
- `play_words.txt`: elle kürasyonlu güvenilir oyun kelimeleri.
- `reviewed_expansion_words.txt`: elle gözden geçirilmiş **1.095** genişletme kelimesi. Runtime'da doğrudan doğrulama sözlüğüne, 3–9 harf aralığındakiler hedef havuzuna katılır.
- `manual_surface_words.txt`: yalnızca açıkça onaylanmış istisnai yüzey biçimleri.
- `blocked_words.txt`: **212** kelimelik kesin gameplay denylist'i. Bu kelimeler bonus, günlük cevap veya zorunlu hedef olamaz.
- `blocked_level_words.txt`: **400** nadir/eski/uzmanlık kelimesi. Bunlar gerçek sözlük maddesi olarak bonus doğrulamasında kalabilse de zorunlu bölüm hedefi olamaz.

## Runtime yükleme kuralı

`DictionaryService` artık yalnızca üretilmiş `core_words.txt` / `level_words.txt` dosyalarına güvenmez. `reviewed_expansion_words.txt`, `manual_surface_words.txt`, `blocked_words.txt` ve `blocked_level_words.txt` da uygulama açılışında yüklenir.

Bunun iki yararı vardır:

1. Yeni elle onaylanan kelimeler build scripti yeniden çalıştırılmasa bile oyuna doğru katmanda girer.
2. Denylist'teki bir kelime yanlışlıkla eski bir üretilmiş dosyada kalsa bile runtime'da tekrar elenir.

## Zaman/kip, iyelik ve fiilimsi kuralı

Oyun **otomatik zaman/kip çekimi, iyelik/hal çekimi veya fiilimsi üretmez**. Bu nedenle sırf çekim olan biçimler oyun kelimesi değildir:

- `boşuyor`, `geliyor`, `geldi`, `atar`, `tarar` ❌
- `atmış`, `atarak`, `atınca` ❌
- `anam`, `annem`, `evim`, `kitabı` ❌

Fiilin yalın kök/emir biçimi gerçek oyun girdisi olabilir:

- `taramak -> tara` ✅
- `boşalmak -> boşal` ✅

Yüzeyi fiil çekimiyle aynı görünse bile ayrıca bağımsız sözlük anlamı bulunan gerçek maddeler tutulabilir:

- `gelir` = isim ✅
- `yazar` = isim ✅
- `dolar` = para birimi ✅

## 10.000 bölüm ve save uyumluluğu

Sözlük kalite güncellemesi 10.000 mevcut harf çemberinin sırasını korur. Bunun nedeni oyuncunun ulaştığı bölüm numarasının güncellemeden sonra farklı bir harf çemberine dönüşmesini önlemektir.

Bir `level_seeds.txt` girdisi `blocked_level_words.txt` veya `blocked_words.txt` nedeniyle artık hedef olamıyorsa:

1. aynı harf imzasına sahip güvenli bir anagram varsa ana hedef olarak o kullanılır;
2. yoksa aynı çemberden üretilebilen en güçlü güvenli alt kelime ana hedef olur;
3. bloklanan kelimenin kendisi oyuncuya zorunlu hedef olarak gösterilmez.

Yeni `level_words` içeriği deterministik hedef seçimlerini değiştirebildiği için `content_version` artırılmıştır. Güncelleme alan mevcut oyuncuda yalnızca açık bölümün `found_words`, `bonus_words` ve ipucu durumu temizlenir; ulaşılan bölüm, ekonomi ve istatistikler korunur.

## Sözlük build scripti

`tool/build_quality_dictionary.py` artık `blocked_level_words.txt` dosyasını da uygular ve mevcut 10.000 seed haritasını varsayılan olarak korur.

Normal sözlük yenileme:

```text
python tool/build_quality_dictionary.py <zemberek-master-dictionary-path>
```

Ancak kampanya haritasını bilinçli olarak tamamen yeniden oluşturmak istenirse:

```text
python tool/build_quality_dictionary.py <zemberek-master-dictionary-path> --rebuild-seeds
```

`--rebuild-seeds` mevcut oyuncuların bölüm eşlemesini değiştirebileceği için normal içerik güncellemesinde kullanılmamalıdır.

## Kaynak/provenans

Ana temel Zemberek-NLP'nin Apache-2.0 lisanslı Türkçe sözlük verisidir. Ek genişletmeler lisansı uygun kaynaklardan ve elle onaylanan listelerden alınır. Ayrıntılar `THIRD_PARTY_NOTICES.md`, `licenses/` ve `docs/LEXICON_RESEARCH.md` içinde tutulur.
