# V6 Validation

Build-time sözlük kontrolleri:

- Validation lexicon: 26.453
- Level target vocabulary: 23.376
- Unique level wheels: 10.000
- Wheel sizes: 5/6/7/8/9 = 1000/2000/2500/2700/1800
- Minimum buildable target count per wheel: 8
- Finite tense/mood generation: OFF
- Possessive/case generation: OFF
- Gerund/participle generation: OFF

Özel red regresyonları arasında `atar`, `tarar`, `boşuyor`, `tarıyor`, `atıyor`, `geldi`, `geliyor`, `gelmiş`, `gitti`, `gidiyor`, `gidecek`, `yaptı`, `yapıyor`, `yapacak` bulunur.

Özel kabul regresyonları arasında `tara`, `boşal`, `armut`, `deste`, `karınca`, `oyuncu`, `sanatçı`, `yayıncı`, `kitapçı`, `şarkıcı` bulunur.

Bu çalışma ortamında Flutter SDK yoksa nihai cihaz derlemesi kullanıcı makinesinde `flutter analyze`, `flutter test`, `flutter run` ile yapılmalıdır.
