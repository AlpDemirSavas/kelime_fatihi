# Kelime haznesini büyütmek için araştırılan yöntemler

V5 için hedef yalnızca kelime sayısını artırmak değil, **çekimli yüzey biçimlerini sözlük sanmadan** gerçek ve oynanabilir kelime sayısını büyütmektir.

## 1. Zemberek-NLP — V5'te kullanılan ana kaynak

- Repo: https://github.com/ahmetaa/zemberek-nlp
- Lisans: Apache-2.0
- Avantaj: Türkçe morfoloji metadata'sı ve sözlük başlıkları var; ticari uygulamada lisans koşullarına uyarak kullanılabilir.
- V5 uygulaması: gerçek başlıklar + fiillerin yalın kök/emir biçimi. Çekim zinciri üretilmez.

## 2. Wiktionary / Kaikki — sonraki kontrollü genişletme adayı

- Türkçe makine-okunur sözlük: https://kaikki.org/dictionary/Turkish/
- Kaikki sayfası 2026-07 itibarıyla 41 binden fazla ayrı Türkçe word form ve binlerce noun/verb sense listeliyor.
- Lisans: Wiktionary ile aynı şekilde CC-BY-SA + GFDL.
- Avantaj: Zemberek'te bulunmayan güncel/alan terimleri ve ek sözlük maddeleri eklenebilir.
- Risk: proper name, form-of/çekimli biçim, argo ve seyrek girdiler ayıklanmalı. Ayrıca türetilmiş veri dağıtımında lisans/atıf yükümlülükleri korunmalı.
- Bu yüzden V5 binary'sine Kaikki verisi gömülmedi; `tool/import_kaikki_headwords.py` kontrollü aday üretmek için hazırlandı.

## 3. wordfreq — kalite/frekans filtresi için iyi aday

- Repo: https://github.com/rspeer/wordfreq
- Türkçe destekleniyor ve birden fazla gerçek metin kaynağından frekans tahmini sağlıyor.
- Kullanım fikri: yeni kaynaklardan gelen kelimeleri `Zipf` sıklığına göre sıralamak; çok seyrek/garip kelimeleri sonraki seviyelere atmak, günlük/erken seviye kelimelerini daha tanıdık tutmak.
- Lisans notu: kod Apache, veri dosyaları CC-BY-SA 4.0 dahil çeşitli atıf koşulları içeriyor. wordfreq dokümantasyonu düz CSV'ye dönüştürüp atıf bilgisinden koparmamayı özellikle belirtiyor.
- Bu nedenle V5'e wordfreq verisi gömülmedi; ileride build-time kalite skoru olarak kullanılmalı ve gerekli atıflar korunmalı.

## 4. TDK'den scrape edilmiş kelime listeleri — doğrudan paketlenmedi

İnternette TDK İmla Kılavuzu'ndan scrape edildiğini söyleyen 70 bin+ kelimelik GitHub listeleri bulunuyor. Bazılarında açık bir yeniden dağıtım lisansı görünmüyor. Kelime sayısı cazip olsa da mağazaya çıkacak ticari oyun için lisans/provenans belirsiz veriyi doğrudan bundle etmek doğru değil.

## Önerilen gelecekteki üretim hattı

1. Zemberek lexical headwords = temel güven kümesi.
2. Kaikki'den yalnızca bağımsız lexical headword'ler (form-of olmayan, proper-name olmayan, tek-token Türkçe alfabeli girdiler) = aday genişletme.
3. wordfreq / büyük corpus frekansı = aday sıralama ve gürültü filtresi.
4. İki kaynakta ortak kelimeler = erken/orta seviye hedefleri.
5. Tek kaynakta olan fakat frekansı iyi kelimeler = ileri seviye hedefleri.
6. Kullanıcı raporları için denylist/allowlist = hızlı kalite düzeltmesi.

Bu katmanlı yaklaşım, `125 bin çekimli biçim` yaklaşımından daha az sayıda ama çok daha güvenilir oyun kelimesi üretir.
