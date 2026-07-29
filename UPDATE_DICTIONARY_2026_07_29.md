# Sözlük kalite güncellemesi — 2026-07-29 (V7 ile güncellendi)

Bu dosyanın ilk V6 sürümü 10.000 `level_seeds` eşlemesini koruyordu. Son V7 campaign-quality çalışması bu yaklaşımın üzerine **bilinçli bir global seviye optimizasyonu** ekledi. Güncel davranış için `UPDATE_CAMPAIGN_V7.md` ve `docs/DICTIONARY.md` esas alınmalıdır.

## Güncel içerik

- 853 yeni elle onaylanmış bağımsız kelime doğrulama sözlüğüne eklendi.
- Bunların 679 adet 5–9 harfli kısmı seviye kelime havuzuna katıldı.
- 212 kelime global gameplay denylist'e alındı.
- 400 nadir/eski/uzmanlık kelimesi zorunlu hedef denylist'ine alındı.
- `reviewed_expansion_words.txt`, `blocked_words.txt` ve `blocked_level_words.txt` runtime'da uygulanır.
- V7'de `level_targets.txt` ile 10.000 bölümün zorunlu hedefleri global olarak optimize edilmiştir.
- `level_seeds.txt` V7'de yeniden sıralanmıştır; eski level→wheel mapping artık korunmaz.
- `content_version` 7'dir. Yalnızca açık bölümün geçici cevap/ipucu state'i sıfırlanır; ulaşılan bölüm ve ekonomi korunur.

## Güncel bakım akışı

Yeni elle onaylı kelime:

1. `reviewed_expansion_words.txt` içine ekle.
2. Gerekirse `tool/build_quality_dictionary.py` ile lexical havuzları yenile.
3. Zorunlu hedefe çıkmaması gereken gerçek ama aşırı nadir kelimeyi `blocked_level_words.txt` içine ekle.
4. Hiçbir gameplay katmanında kabul edilmemesi gereken kelimeyi `blocked_words.txt` içine ekle.
5. Campaign hedeflerini yeniden dengelemek gerekiyorsa `tool/optimize_campaign.py <tr_50k.txt>` çalıştır.
6. `flutter analyze` ve `flutter test` çalıştır.
