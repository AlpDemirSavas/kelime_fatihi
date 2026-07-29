# Sözlük kalite güncellemesi — 2026-07-29

Bu güncelleme sözlüğü büyütürken oyuncuya zorunlu olarak gösterilen kelimelerin kalitesini artırır.

## İçerik

- 853 yeni elle onaylanmış bağımsız kelime doğrulama sözlüğüne eklendi.
- Bunların 679 adet 5–9 harfli kısmı bölüm hedef havuzuna eklendi.
- 212 kelime global gameplay denylist'e alındı.
- 400 nadir/eski/uzmanlık kelimesi zorunlu hedef denylist'ine alındı.
- `reviewed_expansion_words.txt` runtime'da doğrudan yükleniyor.
- `blocked_words.txt` runtime'da son güvenlik katmanı olarak uygulanıyor.
- Yeni `blocked_level_words.txt` zorunlu hedefleri filtreliyor.
- 10.000 `level_seeds` sırası korunuyor; mevcut oyuncuların bölüm numarası/harf çemberi eşlemesi değişmiyor.
- Bloklanan bir seed yalnızca iç harf kaynağı olarak kalabilir; oyuncuya cevap olarak gösterilmez.
- `content_version` 6 oldu. Sadece güncelleme sırasında açık olan bölümün geçici kelime/ipucu durumu sıfırlanır.
- Builder mevcut paketlenmiş sözlüğü uyumluluk tabanı olarak korur ve seed haritasını varsayılan olarak yeniden oluşturmaz.

## Yeni normal bakım akışı

Yeni elle onaylı kelime:

1. `reviewed_expansion_words.txt` içine ekle.
2. 3–9 harfliyse runtime otomatik olarak level target havuzuna da alır.
3. Oyuncuya zorunlu hedef yapılmaması gereken gerçek ama aşırı nadir kelimeyi `blocked_level_words.txt` içine ekle.
4. Hiçbir gameplay katmanında kabul edilmemesi gereken kelimeyi `blocked_words.txt` içine ekle.
5. Testleri çalıştır.

Toplu kaynak yenilemesi yapılmadığı sürece `level_seeds.txt` dosyasını elle değiştirmek gerekmez.
