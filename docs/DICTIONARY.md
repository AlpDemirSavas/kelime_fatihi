# Türkçe sözlük ve 10.000 bölüm stratejisi — V7

Kelime Fatihi'nin sözlük ilkesi: **çekimli yüzey biçimlerini yapay biçimde üretmeden gerçek Türkçe kelime havuzunu geniş tutmak; günlük/oynanabilir kelimeleri zorunlu hedeflerde öne çıkarmak; nadir veya uzmanlık kelimelerini oyuncuya zorla sordurmamak.**

## Paket içindeki havuzlar

- `core_words.txt`: çevrimdışı doğrulama ve bonus kelimeler için **27.854** kelime.
- `level_words.txt`: seviye üretiminde değerlendirilebilen **23.538** temiz 3–9 harfli kelime.
- `level_seeds.txt`: Bölüm 1–10.000 için **10.000 benzersiz harf çemberi**.
- `level_targets.txt`: Her bölüm için önceden optimize edilmiş zorunlu cevap listesi. Satır biçimi `harf_imzası|kelime1,kelime2,...` şeklindedir.
- `daily_words.txt`: Günün Kelimesi için kürasyonlu 5 harfli cevaplar.
- `play_words.txt`: elle kürasyonlu güvenilir oyun kelimeleri.
- `reviewed_expansion_words.txt`: elle gözden geçirilmiş **1.095** genişletme kelimesi. Runtime'da doğrulama sözlüğüne; 3–9 harf aralığındakiler seviye kelime havuzuna katılır.
- `manual_surface_words.txt`: yalnızca açıkça onaylanmış istisnai yüzey biçimleri.
- `blocked_words.txt`: **212** kelimelik kesin gameplay denylist'i. Bunlar bonus dahil hiçbir yerde kabul edilmez.
- `blocked_level_words.txt`: **400** nadir/eski/uzmanlık kelimesi. Gerçek sözlük maddesi olarak bonus doğrulamasında kalabilirler ancak zorunlu bölüm hedefi olamazlar.

## Runtime yükleme kuralı

`DictionaryService` bütün havuzları uygulama açılışında yükler. `blocked_words.txt` ve `blocked_level_words.txt` runtime'da tekrar uygulanır. Böylece üretilmiş bir dosyada eski bir kelime kalsa dahi denylist kuralı korunur.

V7'de zorunlu hedefler runtime'da rastgele seçilmez. `level_targets.txt` global kampanya optimizasyonunun çıktısıdır. Service her satır için:

1. hedef imzasının ilgili seed harfleriyle eşleştiğini,
2. hedef sayısının bölüm zorluğu ile uyumlu olduğunu,
3. bütün hedeflerin `level_words` içinde bulunduğunu,
4. bütün hedeflerin o bölümün harfleriyle gerçekten kurulabildiğini

kontrol eder. Hatalı paketleme uygulama başında `StateError` üretir; sessizce bozuk seviye üretmez.

## Zaman/kip, iyelik ve fiilimsi kuralı

Oyun **otomatik zaman/kip çekimi, iyelik/hâl çekimi veya fiilimsi üretmez**.

- `boşuyor`, `geliyor`, `geldi`, `atar`, `tarar` ❌
- `atmış`, `atarak`, `atınca` ❌
- `anam`, `annem`, `evim`, `kitabı` ❌

Fiilin yalın sözlük/kök biçimi uygunsa kullanılabilir:

- `taramak -> tara` ✅
- `boşalmak -> boşal` ✅

Bağımsız sözlük anlamı bulunan eşsesli biçimler korunabilir:

- `gelir` = isim ✅
- `yazar` = isim ✅
- `dolar` = para birimi ✅

## V7 kampanya optimizasyonu

Önceki kampanyanın 10.000 wheel imzası benzersizdi; fakat her seviyenin cevapları kendi içinde rastgele seçildiği için kısa kelimeler zorunlu hedeflerde gereğinden fazla tekrar edebiliyordu. V7 hedef seçimini **10.000 bölümün tamamını aynı anda gören offline optimizer** ile yapar.

Zorunlu cevap önceliği:

1. `play_words`, `reviewed_expansion_words` ve `daily_words` içindeki insan-kürasyonlu kelimeler,
2. Türkçe frekans korpusunda yeterli kullanım gösteren ve `level_words` içinde bulunan sözlük başlıkları,
3. nadir sözlük maddeleri yalnızca bonus/doğrulama havuzunda kalır.

Frekans verisi uygulamaya asset olarak eklenmez ve runtime'da ağ bağlantısı kullanılmaz. Frekans listesi yalnızca `tool/optimize_campaign.py` çalıştırılırken build-time kalite sinyali olarak kullanılır.

### Zorluk eğrisi

Wheel uzunluğu artık hedef sayısı sınırlarıyla aynı noktalarda büyür:

| Bölüm | Harf | Zorunlu hedef |
|---|---:|---:|
| 1–99 | 5 | 5 |
| 100–999 | 5 | 6 |
| 1000–2999 | 6 | 7 |
| 3000–5499 | 7 | 8 |
| 5500–7999 | 8 | 9 |
| 8000–10000 | 9 | 10 |

Toplam wheel dağılımı: **999 / 2.000 / 2.500 / 2.500 / 2.001**.

### Ölçülen kalite sonucu

V6 random hedef seçimi → V7 optimize plan:

- Benzersiz harf çemberi: **10.000 → 10.000**
- En çok tekrar eden zorunlu cevap: **231 → 97**
- 3 harfli zorunlu cevap: **28.972 → 12.935**
- Ardışık wheel harf benzerliği ortalaması: **%35,0 → %15,2**
- %75+ benzer ardışık wheel çifti: **112 → 31**
- Curated bir zorunlu cevap içeren seviye: **5.447 → 9.446**
- Eksik nominal hedef sayılı seviye: **1 → 0**
- Zorunlu cevapların frekans/kürasyon filtresi kapsamı: **%100**

Bu metrikler `CAMPAIGN_QUALITY_REPORT.txt/json` ve regresyon testleriyle korunur.

## Save uyumluluğu

V7 bilinçli bir **kampanya yeniden sıralamasıdır**; eski `level -> wheel` eşlemesi korunmaz. Bu nedenle `content_version = 7` yapılmıştır.

Güncelleme alan oyuncuda yalnızca açık bölümün geçici durumu sıfırlanır:

- `found_words`
- `bonus_words`
- kullanılan ipuçları

Şunlar korunur:

- ulaşılan bölüm numarası,
- altın/can/ekonomi,
- tamamlanmış ilerleme sayaçları,
- istatistikler ve görev verileri.

## Sözlük build scripti

Normal sözlük yenileme:

```text
python tool/build_quality_dictionary.py <zemberek-master-dictionary-path>
```

Bu script optimize seed/target kampanyasını **değiştirmez**. Eski `--rebuild-seeds` yolu V7'de devre dışıdır; yanlışlıkla 10.000 bölümü eski algoritmayla üretmesini istemiyoruz.

Kampanyayı bilinçli yeniden optimize etmek için:

```text
python tool/optimize_campaign.py <tr_50k.txt>
```

`tr_50k.txt`, HermitDave/FrequencyWords Türkçe frekans listesidir. Kaynak/provenans ayrıntıları `THIRD_PARTY_NOTICES.md` içindedir.

## Kaynak/provenans

Ana sözlük Zemberek-NLP'nin Apache-2.0 lisanslı Türkçe lexical verisinden türetilmiştir. Elle gözden geçirilen ek kelimeler proje içi kürasyon ve lisansı uygun kaynaklardan gelir. Kampanya frekans sıralaması için FrequencyWords Türkçe OpenSubtitles tabanlı listesi build-time sinyal olarak kullanılır. Ayrıntılar `THIRD_PARTY_NOTICES.md` ve `licenses/` altında tutulur.
