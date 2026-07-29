# Third-Party Notices

## Zemberek-NLP Turkish lexical data

Kelime Fatihi V6'nın ana çevrimdışı sözlüğü Zemberek-NLP `master-dictionary.dict` girdilerinden türetilmiştir.

- Project: Zemberek-NLP
- Repository: https://github.com/ahmetaa/zemberek-nlp
- Copyright: 2018 Ahmet A. Akın, Mehmet D. Akın
- License: Apache License 2.0

Özel ad/kısaltma/noktalama girdileri oyun havuzundan çıkarılır. Fiil infinitifleri hedef olarak kullanılmaz; yalnızca yalın emir/kök biçimi kullanılabilir. Otomatik zaman/kip, iyelik, hâl veya fiilimsi üretimi yapılmaz.

Lisans metinleri: `licenses/APACHE-2.0.txt` ve `licenses/ZEMBEREK_LICENSE.txt`.

## Turkish Hunspell reviewed additions

İlk V6 genişletmesinde 242 ek kelime, Türkçe Hunspell yazım sözlüğünden aday olarak alınmış ve oyun için elle gözden geçirilmiştir. Hunspell'in toplu çekim çıktısı oyuna aktarılmamıştır. Daha sonraki proje-içi manuel kürasyon kelimeleri aynı `reviewed_expansion_words.txt` dosyasında tutulur; bu yeni manuel girdiler Hunspell kaynağına atfedilmez.

- Package/source mirror: `dictionary-tr` in `wooorm/dictionaries`
- Source described by upstream as Turkish spelling dictionary
- Dictionary/affix license: MIT
- Upstream dictionary copyright notice: Copyright (c) 2014 Harun Reşit Zafer

Lisans metni: `licenses/HUNSPELL_TR_MIT.txt`.

## Kaikki / Wiktionary

Kaikki/Wiktionary verisi V6 binary'sine gömülmemiştir. Bu kaynak araştırmada daha geniş aday havuzu olarak incelenmiştir; CC-BY-SA/GFDL yükümlülükleri nedeniyle doğrudan V6 sözlüğüne alınmamıştır.

## FrequencyWords Turkish frequency data — V7 campaign ranking

V7'nin 10.000 seviyelik zorunlu hedef planı oluşturulurken Türkçe kelimelerin kullanım yaygınlığını ölçmek için HermitDave/FrequencyWords projesinin `content/2016/tr/tr_50k.txt` verisi **yalnızca build-time sıralama sinyali** olarak kullanılmıştır. Ham frekans listesi uygulama asset'lerine gömülmez.

- Project: `hermitdave/FrequencyWords`
- Repository: https://github.com/hermitdave/FrequencyWords
- Turkish source: `content/2016/tr/tr_50k.txt`
- Corpus basis: OpenSubtitles frequency data
- Repository code license: MIT
- Generated frequency-list content license stated by upstream: CC BY-SA 4.0

Bu kaynak yalnızca hangi güvenli sözlük başlıklarının zorunlu seviyelerde daha uygun olduğunu sıralamak için kullanılır; Kelime Fatihi'nin lexical doğrulama kaynağının yerine geçmez.
