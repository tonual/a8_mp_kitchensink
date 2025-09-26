# Muzyka na samplach

## Spis treści
- [Wstęp](#wstęp)
  - [POKEY + Sample = ♥](#pokey--sample--)
  - [Ale jak to brzmi?](#ale-jak-to-brzmi)
- [Zrób to sam](#zrób-to-sam)
  - [Najpierw Software](#najpierw-software)
    - [Emulator Atari](#emulator-atari)
    - [Music Pro Tracker v24](#music-pro-tracker-v24)
    - [Audacity](#audacity)
    - [Sox](#sox)
    - [wav2digi](#wav2digi)
    - [atr](#atr)
  - [1 Przygotowanie sampli](#1-przygotowanie-sampli)
    - [Pozyskaj sample](#pozyskaj-sample)
    - [Obróbka](#obróbka)
    - [Przetwarzanie](#przetwarzanie)
  - [2 Konwersja sampli do formatów MPT](#2-konwersja-sampli-do-formatów-mpt)
- [Materiały uzupełniające](#matariały-uzupełniające)
  - [Źródła dobrej jakości sampli](#źródła-dobrej-jakości-sampli)
  - [PC DAW](#pc-daw)

---

## Wstęp
To jest przewodnik "po sznurku" - od kwestii przygotowania sampla, konwersjii formatów, programowania muzyki   
po kompilację i uruchomienie na standardowym Atari XL/XE. Znajdziesz tu konkretne instrukcje, narzędzia, działające przykłady,  
kasusy użycia i próbki. Do dzieła!

### POKEY + Sample = ♥
Połączenie syntetycznego POKEY z brzmieniem sampli wzbogaca muzykę Atari o nową jakość. Samplowane zestawy perkusyjne,   
nuty basu z filtrem dolnoprzustowym, akordy, czy krótkie
fragmenty muzyczne (loopy) gotowe do odtwarzania w "pętli" eksponują 
muzyczne ambicje Atari na nowy poziom. 

### Ale jak to brzmi?
Trudno o tym pisać.. po prostu odpal [przykładowy utwór (.xex)](https://github.com/tonual/a8_mp_kitchensink/tree/main/mpt_samples_worklfow/xex) 
na swoim Atari i posłuchaj.  
Muzyczkę _transcil.xex_ wykonasz samodzilenie na podstawie tego przewodnika!

## Zrób to sam

### Najpierw Software 

#### Emulator Atari
Szkoda zużywać klawiatury wiekowego staruszka... wykorzystaj emulator do pracy. Na deser zawsze 
można sprawdzić efekt na prawdziwym sprzęcie.
- [Altirra](https://www.virtualdub.org/altirra.html)
- [Atari800](https://github.com/atari800/atari800)

#### Music Pro Tracker v2.4
MPT jest doskonałym _trackerem_ autorstwa Adama Bieniasa. Program powstał na początku złotych lat 90tych.  
Tracker wspiera pracę z samplami na podstawowym Atari XL/XE. Format pliku z muzyką to .md1 (.md2),  
natomiast sample przechowywane są w osobnym pliku (.d8, .d15). Warto zwrócić uwagę na dostępne, kompaktowe   
odtwarzacze muzyki z formatu .md1 zarówno wersji Assemlber jak i __Mad Pascal__ ze wsparciem sampli(!)

Kilka faktów:
- 1 kanał przeznaczony na granie samplami
- max 16 różnych sampli
- częstotliwość próbkowania: 15Khz lub 8Khz, 4bit, mono
- max rozmiar sampli ~11Kb _(według mojego doświadczenia)_
- max czas sampla 3.4s _(według mojego doświadczenia)_
- możliowść załadowania wielu sampli jednocześnie z jednego pliku
- format pliku sampli: .d8 (8KHz), .d15 (15Khz)

[Więcej faktów o MPT](http://atariki.krap.pl/index.php/Music_Protracker) 

#### Audacity
Darmowy, wieloplatformowy (Win, OSX, Linux) program do pracy z samplami - posiada komplet narzędzi wymaganych na potrzeby  
pocesu obróbki i przygotowania sampli da dalszej pracy.

[Pobierz Audacity](https://www.audacityteam.org/download/)

#### Sox
Szwajcarski scyzoryk wśród narzędzi do przetwarzania dźwięku z linii poleceń. 
Może konwertować pliki audio na inne popularne formaty oraz stosować efekty i filtry dźwiękowe podczas konwersji. 
Wieloplatformowy (Win, OSX, Linux).

[Pobierz Sox](https://sourceforge.net/projects/sox/)

#### wav2digi
Program linii poleceń, konwertuje plik/pliki WAV do .d8 lub .d15 oraz wypisuje statystyki. Dostępne wersje w językach   
wysokiego poziomu: _Python, C#, Java._ Napisany przez GPT.  
Kluczowymi informacjami o wymaganiach podzielił się @tebe [w dyskusji na forum atarionline](https://atarionline.pl/forum/comments.php?DiscussionID=7975page=1#Item_39)

[Pobierz wav2digi](https://github.com/tonual/a8_mp_kitchensink/tree/main/mpt_samples_worklfow/utils)

#### atr
Program linii poleceń do manipulacji obrazami dyskietki Atari czyli plikami .atr
Pozwala min. wylistować zawartość dyskietki, dodać plik, usunąć plik.  
Podaję link to kodu źródłowego, zatem należ samodzielnie skompilować program dla swojego systemu.  
Wystraczy zainstalować kompilator języka C, i uruchomić z linii poleceń:
```
gcc atr.c
```

[Pobierz atr](https://github.com/jhallen/atari-tools/archive/refs/heads/master.zip)  
[Dokumentacja](https://github.com/jhallen/atari-tools)

### Przygotowanie sampli


#### Pozyskaj sample

Pobierz [darmowe sample](https://www.bluezone-corporation.com/images/FREE_SOUNDS/Bluezone_Corporation_Free_Chillout_Sample_Pack.zip), 
rozpakuj pliki i otwórz konkretnie plik __Bluezone-Ambr-drum-loop-005-110.wav__ w Audacity

#### Obróbka 
Odsłuchaj, to sewkencja perkusyjna z *base drum*, *snare*, *hihat* itd. Zaznacz markerami interesujące fragmenty 
- kliknij na pozycję aby umieścić kursor a następnice __CTRL + B__. 
Pomozniczno powiększaj/oddalaj - __CTRL + scroll myszy__.

<img src="screenshots/markers.png" width=400 style="padding:20px">

```
Idealnie kiedy fragment zaczyna się i kończy w miejscu, gdzie amplituda jest zerowa.  
Należy postarać się, aby fragment był jak najkrótszy a jednocześnie zachował sens swojego brzmienia.  
Dlatego warto zrobić wygaszenie lub wejście sygnału na ambplitudę ręcznie.
```
- Zaznacz myszą krótki fragment w miejscu początkowego markera i zastosuj __Effects -> Fading -> Fade in__
- Zaznacz myszą krótki fragment przed końcowym markerem i zastosuj __Effects -> Fading -> Fade out__  


#### Przetwarzanie
- zaznacza cały obszar: __CTRL + A__
- _menu: Effect -> Volume and Compression -> Compresor_ | ustaw: *Threshold -20dB, Ratio 10:1* | Apply
- _menu: Tracks -> Mix -> Mix Stereo Down to Mono_
- _menu: Tracks -> Resample_ | wpisz 15000 | OK
- _menu: Effect -> Volume and Compression -> Normalize_ | ustaw: 0dB | Apply
- _menu: File -> Export -> Export Mulitple_ | ustaw: format WAV, enconding: Unsigned 8-bit PCM | Export

Ostatnie polecenie zapisuje pociąte fragmenty do osobnych plików .wav.
Przesłuchaj te pliki, usuń niepotrzbne "pliki-odkrawki".


### Konwersja sampli do formatów MPT

Gwóźdź programu. Zachowaj ostrożność. Wybierz środowisko uruchomieniowe do wyboru __Pyhton, .NET lub Java__ [wav2digi](https://github.com/tonual/a8_mp_kitchensink/tree/main/mpt_samples_worklfow/utils)  
Wyselekcjonowane pliki .wav z samplami przygotowane w poprzednim kroku , powinny znajdować się w dedykowanym __katalogu_z_wav__  

```
wav2digi katalog_z_wav mojesample.d15
```
Rozszerzenie .d15 stosujemu kiedy sample mają 15Khz, .d8 kiedy 8Khz. 
Istnieje eksperymentalna możliwość podania adresu pamięci do załadowania sampli.

Pełny format linii poleceń to:
```
wav2digi.py [-h] [--start-addr START_ADDR] input_paths [input_paths ...] output_file
```
Przykładowe działanie; w moim przypadku python, a katalogu __sample umieszczone w sample/bluezone_drum__ (również do pobrania)  
```
python3 utils/wav2digi.py sample/bluezone_drum bluezone.d15
Found 5 WAV files to process:
  - sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-02.wav
  - sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-03.wav
  - sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-04.wav
  - sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-06.wav
  - sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-07.wav
Processed sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-02.wav: 4250 4-bit samples (packed to 2304 bytes, padded by 179 bytes)
Processed sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-03.wav: 3894 4-bit samples (packed to 2048 bytes, padded by 101 bytes)
Processed sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-04.wav: 3842 4-bit samples (packed to 2048 bytes, padded by 127 bytes)
Processed sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-06.wav: 4160 4-bit samples (packed to 2304 bytes, padded by 224 bytes)
Processed sample/bluezone_drum/Bluezone-Ambr-drum-loop-005-110-07.wav: 4116 4-bit samples (packed to 2304 bytes, padded by 246 bytes)
Created bluezone.d15 with 5 samples.
Sample addresses: ['$9000', '$9900', '$a100', '$a900', '$b200']
Sample lengths: ['2304 bytes', '2048 bytes', '2048 bytes', '2304 bytes', '2304 bytes']
Total file size: 11040 bytes
zzz

```
Rozmiar danych pojedyńczego sampla powinien być wielkrotnością liczby 256, a jeśli nie wypełnia tego obszaru,   
zastosowany będzie "pusty dopełniacz". Dlatego przełącz Audacity w jednostkę miary czasu "samples"
i sprawdź, czy długość sampla spełnia to wymaganie. Dzięki temu wywalczysz dodatkowe miejsce na dane.
```

### Obraz dyskietki

W tym kroku stworzymy obraz dyskieti Atari z samplami (plik .d15), programem MPT oraz DOSem.  
Ponieważ sample będą ładowane z poziomu programu MPT, DOSa jest niezbędny i będzie wspierał operacji odczytu/zapisu na dyskietce.

Pobież [gotowy obrazu dyskieti .atr](https://github.com/tonual/a8_mp_kitchensink/blob/main/mpt_samples_worklfow/atr/dos_mpt.atr), który ma już DOSa i MPT. Wystarczy zatem wrzucić pliki sampli.  
Wcześniej krótka rozgrzewka - wylistuj pliki w obrazie:
```
atr dos_mpt.atr ls
```
W wyniku polecenia dostajesz listę plików w obrazie: _mpt211.com mpt24.com mpt24s.com_  (3 różne wersje programu MPT)  
Dodajmy plik z samplami do obrazu:
```
atr dos_mpt.atr put
```






## Matariały uzupełniające

### Źródła dobrej jakości sampli.

- [Modular drums](https://cdn.mos.musicradar.com/musicradar-modular-percussion-samples.zip)
- [Hard Techno](https://www.bluezone-corporation.com/images/FREE_SOUNDS/Bluezone_Corporation_Free_Hard_Techno_Sample_Pack.zip)
- [Minimal Techno](https://www.bluezone-corporation.com/images/FREE_SOUNDS/Bluezone_Corporation_Free_Minimal_Techno_Sample_Pack.zip)
- [Psytrance](https://www.bluezone-corporation.com/images/FREE_SOUNDS/Bluezone_Corporation_Free_Psytrance_Sample_Pack.zip)

### PC DAW

Gorąco polecam pakiet _Digital Audio Workstation_ w postaci programu Ableton.  
Zestaw, obok bogatej biblioteki sampli wszelakiej maści a zwłaszcza perkusji, oraz "loopów"   
Posiada liczne narzędzia do tzw "masteringu" i wszelakiej maści modyfikacji brzmienia.   
Jest sprytny, prosty w obłsudze a jednocześnie zaawansowany i posiada jedynie 2 widoki: aranżacji i kompozycji.  
Istniej przystępna, podstawowa wersja - Ablteon Live Lite (klucz można nabyć za symboliczną kwotę)

[Ableteon Live Lite](https://www.ableton.com/en/products/live-lite/)
