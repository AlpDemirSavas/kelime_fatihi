# Türkçe sözlük stratejisi — V6/V7

Kelime Fatihi'nin sözlük ilkesi: **çekimli yüzey biçimlerini yapay biçimde üretmeden, gerçek ve oynanabilir Türkçe kelime havuzunu geniş tutmak.**

## Paket içindeki havuzlar

- `core_words.txt`: çevrimdışı doğrulama için **26.453** kelime.
- `level_words.txt`: Sonsuz Fetih hedeflerinde kullanılabilen **23.376** temiz kelime.
- `level_seeds.txt`: Bölüm 1–10.000 için **10.000 benzersiz, ön-doğrulanmış harf çemberi**.
- `daily_words.txt`: Günün Kelimesi için kürasyonlu 5 harfli cevaplar.
- `play_words.txt`: elle kürasyonlu güvenilir oyun kelimeleri.
- `reviewed_expansion_words.txt`: ek kaynaklardan tek tek gözden geçirilerek alınmış güvenli genişletmeler.
- `blocked_words.txt`: regresyonlarda görülen ve kesinlikle kabul edilmeyecek çekim/uydurma biçimler.

## Zaman/kip ve ek kuralı

Oyun **otomatik zaman/kip çekimi üretmez**. Bu nedenle sırf fiilin çekimi olan biçimler bonus veya bölüm hedefi değildir:

- `boşuyor` ❌
- `geliyor` ❌
- `geldi` ❌
- `gelecek` ❌ (yalnızca fiil çekimi anlamında; bağımsız sözlük maddesi ayrımı kaynak metadata'sına göre yapılmalıdır)
- `atar` ❌
- `tarar` ❌
- `atmış` ❌
- `atarak` ❌
- `anam`, `evim`, `kitabı` gibi otomatik iyelik/hal yüzeyleri ❌

Fiilin yalın kök/emir biçimi gerçek oyun girdisi olabilir:

- `taramak -> tara` ✅
- `boşalmak -> boşal` ✅

Yüzeyi bir çekimle aynı görünse bile ayrıca bağımsız sözlük anlamı bulunan gerçek maddeler tutulabilir:

- `gelir` = isim ✅
- `yazar` = isim ✅
- `dolar` = para birimi ✅

Sistem bu kelimeleri fiile geniş zaman eki ekleyerek üretmez; bağımsız sözlük maddesi olarak alır.

## 10.000 bölüm

Seviye tohumları 5–9 harfli gerçek hedef kelimeler üzerinden hazırlanır. İlk 10.000 bölüm için aynı harf multiset'inin tekrar etmemesi hedeflenir ve her seed yeterli alt kelime üretimi açısından build-time kontrolden geçirilir.

Sözlük ve seviye üretimi uygulamanın bundle'ındaki dosyalardan yapılır; çalışma sırasında ağ/TDK API çağrısı yoktur. Bu yüzden metro/uçak modu oynanışı tamamen çevrimdışıdır.

## Kaynak/provenans

Ana temel Zemberek-NLP'nin Apache-2.0 lisanslı Türkçe sözlük verisidir. Ek genişletmeler lisansı uygun kaynaklardan gözden geçirilerek alınır. Ayrıntılar `THIRD_PARTY_NOTICES.md`, `licenses/` ve `docs/LEXICON_RESEARCH.md` içinde tutulur.
