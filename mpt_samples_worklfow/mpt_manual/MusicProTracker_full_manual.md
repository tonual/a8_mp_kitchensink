# Music Pro Tracker Manual

---

# Voice (Instrumenty)

Voicy (instrumenty) są najbardziej rozbudowaną częścią MPt.

### Struktura instrumentu

```
[PS] [PA]

00 -00
00 1-00
00 2-00
00 3-00
00 4-00
NA → numery akcentów
NP → numery parametrów akcentów (0-7)
WZ → wartości zniekształceń
```

- **PS** – parametry sterujące instrumentem  
- **PA** – parametry akcentów  
- **NA** – numery akcentów  
- **NP** – numery parametrów akcentów  
- **WZ** – wartości zniekształceń  

### Akcenty

1. parametr → AUDF  
2. parametr+AUDF → AUDF  
3. parametr+(numer nuty) → AUDF  
4. jak 1 + wyłączenie dzielnika  
5. jak 1 + rejestr 9-bitowy  
6. jak 1 + 15 kHz  
7. parametr AND (losowa) → AUDF  

### Efekty (0–7)

0. łagodne falowanie częstotliwości  
1. dodanie parametru do AUDF  
2. opadanie częstotliwości  
3. szybkie opadanie o kilka nut  
4. podwyższanie częstotliwości  
5. szybkie podwyższanie  
6. głębokie falowanie (efekty dźwiękowe)  
7. jak 6, ale w większej skali  

Instrument może też korzystać z różnych tablic częstotliwości, ustawiać AUDCTL, wyciszanie, transpozycje (np. tremolo).  

---

# Pattern (Patern)

EP – edytor patternów. Klawiatura działa jak klawiatura muzyczna, `SPACE` = pusta nuta.  

### Funkcje

- **Transposition (CTRL+T)** – przesunięcie instrumentu o x półtonów  
- **Change (CTRL+X)** – zamiana instrumentu  
- **SHIFT+TAB** – zamiana instrumentu na pozycji  

### Przykład patternu

```
|00|G-2 00S7|
|01|G-3 00VF|
|02|G-2 00VF|
|03|G-3 00VF|
|04|A#2 00VF|
|05|A#3 00VF|
|06|A#2 00VF|
|07|A#3 00VF|
|08|D-3 00VF|
|09|D-4 00VF|
|0A|D-3 00VF|
|0B|D-4 00VF|
|0C|D-3 00VF|
|0D|D-4 00VF|
|0E|D-3 00VF|
|0F|D-4 00F0|
```

### Dodatki

- SHIFT+Ins – wstaw pustą nutę  
- SHIFT+Del – usuń nutę  
- CONTROL+P – odtwarzanie od bieżącej pozycji  
- SHIFT+P – odtwarzanie od 00  

---

# Track (ET – Edytor Tracków)

ET – edytor tracków, najprostsza część MPt.  

- Pierwsza kolumna → numer kroku muzyki  
- Na każdy kanał przypadają dwie kolumny (pattern + transpozycja)  

### Kody specjalne

- `$FE` – przerwanie muzyki  
- `$FF` – skok do pozycji podanej w transpozycji (tylko kanał 0)  

### Funkcje

- `CTRL+Ins` – rozsuwanie pozycji muzyki  
- `CTRL+Del` – kasowanie pozycji  
- `CTRL+1..4` – włącz/wyłącz kanał 0–3  
- `CTRL+X` – zamiana kanałów  

### Przykład tracka

```
|00|01-00|00-00|00-00|00-00|
|01|01-00|00-00|00-00|00-00|
|02|01-F9|00-00|00-00|00-00|
|03|01-F9|00-00|00-00|00-00|
|04|FF-00|00-00|00-00|00-00|
|05|FF-FF|FF-FF|FF-FF|FF-FF|
```

Odtwarzanie: ustaw kursor na 00 i `CTRL+P`.  

---

# Playery

Co dla programistów?  
Nie na wiele się przydaje program muzyczny, jeżeli muzyka na nim napisana nie może zostać wykorzystana w grach, demach, programach. Na szczęście na dysku z MPt znajduje się program `CMP.COM`, który umożliwia skompilowanie playera muzycznego w dowolne miejsce pamięci (jak już wiemy dane muzyczne mogą być wczytywane z DOS'a).  

W kompilatorze znajdują się aż trzy playery:  

- **Pierwszy** – odgrywa wszystkie muzyczki, które nie wykorzystują dwóch kanałów digi (możliwy jest natomiast jeden kanał digi).  
- **Drugi** – odgrywa muzykę czterokanałową bez użycia filtrów, rejestrów 16-bitowych i kanałów digi.  
- **Trzeci** – gra tylko muzykę z użyciem dwóch kanałów digi.  

### Wywoływanie playera

Player wywołujemy na przerwaniu VBL rozkazem procesora:

```asm
JSR $2003
```

lub w asemblerze:

```asm
JSR PLAYER+3
```

Przed wywołaniem należy wprowadzić do rejestrów **A, X oraz Y** odpowiednie parametry sterujące.  

### Rozkazy pierwszego playera

0. Wskazanie adresu danych muzycznych  

```asm
LDA #$00
LDY <MUZYKA
LDX >MUZYKA
JSR PLAYER
```

1. Odegranie instrumentu  

```asm
LDA #$01
LDY #NR.NUTY
LDX #NR.INSTR+(NR.KANAŁU*$40)
JSR PLAYER
```

2. Wyłączenie muzyki  

```asm
LDA #$02
JSR PLAYER
```

3. Zagraj pattern  

```asm
LDA #$03
LDY #TRANSPOZYCJA
LDX #NR.PAT+(NR.KANAŁU*$40)
JSR PLAYER
```

4. Zagraj muzykę od pozycji w ET  

```asm
LDA #$04
LDY #%0000
LDX #NR.POZYCJI
JSR PLAYER
```

5. Tablica sampli dla jednego kanału digi  

```asm
LDA #$05
LDY <TABLICA.SAMPLI
LDX >TABLICA.SAMPLI
JSR PLAYER
```

6. Odtwarzanie digitalizowanej muzyki  

```asm
LDA #$06
LDX #CZY.15kHz
JSR PLAYER
```

Zakończenie:  

```asm
LDA #$0
STA PLAYER+$62D
```

7. Odtworzenie pojedynczego sampla  

```asm
LDA #$07
LDY #NR.SAMPLA
LDX #CZY.15kHz+(NR.KAN*$40)
JSR PLAYER
```

### Odczyt parametrów z playera

- Głośność:  
  - `player+$5AF` – kanał 0  
  - `player+$5B0` – kanał 1  
  - `player+$5B1` – kanał 2  
  - `player+$5B2` – kanał 3  

```asm
LDA PLAYER+$5AF
AND #$0F
```

- Częstotliwość:  
  - `player+$5B3` – kanał 0  
  - `player+$5B4` – kanał 1  
  - `player+$5B5` – kanał 2  
  - `player+$5B6` – kanał 3  

---

### Drugi player

Przykłady użycia:

```asm
LDA #$00
JSR PLAYER   ; inicjalizacja

LDA #$01
JSR PLAYER   ; zatrzymanie odtwarzania
```

---

### Trzeci player

Obsługa dwóch kanałów digi:

```asm
LDA #$00
JSR PLAYER   ; inicjalizacja

LDA #$01
JSR PLAYER   ; odtwarzanie digi, przerwanie SHIFT

LDA #$02
JSR PLAYER   ; wyłączenie generatorów
```

---
