# Kelime Fatihi V6 — Sözlük Son Kalite Turu

## Dil politikası
- Şimdiki/geçmiş/gelecek/geniş zaman ve diğer üretken kip çekimleri otomatik oyun kelimesi değildir.
- `atar`, `tarar`, `geliyor`, `geldi`, `gelmiş`, `gidiyor`, `gitti`, `gidecek`, `yapıyor`, `yaptı`, `yapacak` gibi yüzey biçimleri denylist/regresyon testindedir.
- `tara`, `boşal` gibi yalın emir/kök biçimleri kullanılabilir.
- `gelir` (income), `yazar` (author), `dolar` (currency), `gelecek` (future) gibi ayrıca bağımsız sözlük maddesi olan eşsesli biçimler korunur; bunlar sırf çekim üretildiği için eklenmiş değildir.

## Sözlük genişletmesi
- Zemberek gerçek sözlük maddeleri temel kaynak olmaya devam eder.
- MIT lisanslı Türkçe Hunspell havuzundan 242 doğal kelime elle gözden geçirilerek eklenmiştir.
- 8 ve 9 harfli gerçek sözlük maddeleri artık Sonsuz Fetih hedeflerinde kullanılabilir.
- Doğrulama sözlüğü: 26.453 kelime.
- Bölüm hedef havuzu: 23.376 kelime.

## 10.000 bölüm
Harf çemberleri benzersiz kalır ve kampanya ilerledikçe büyür:
- Bölüm 1–1.000: 5 harf
- Bölüm 1.001–3.000: 6 harf
- Bölüm 3.001–5.500: 7 harf
- Bölüm 5.501–8.200: 8 harf
- Bölüm 8.201–10.000: 9 harf

Tam dağılım: 1.000 / 2.000 / 2.500 / 2.700 / 1.800 benzersiz çember.
