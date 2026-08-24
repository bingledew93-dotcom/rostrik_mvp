# Rostrik 1.2.1 (build 10) — Play "What's new" copy

Paste-ready release notes for the Play Console (Release → Production → *Create
new release* → **Release notes**, per language).

> Same caveat as [`play_store_listing.md`](play_store_listing.md): the
> non-English copy is **machine-assisted**, not professionally translated. It is
> good enough to publish, but a native speaker skim is worth it. Nothing here is
> a safety statement, so the risk is lower than on the main listing.

**Play limit: 500 characters per language.** Every entry below is well under it.

## What actually changed

For your own reference — not for the listing:

| Change | User-visible? |
|---|---|
| Widget rewritten to render its own countdown from a pushed forecast | **Yes** — the headline |
| Direct-boot `WorkManager` crash on reboot fixed | **Yes** — rare but fatal |
| Edge-to-edge enabled on Android 14 and below | Yes, cosmetic |
| Large-screen resizability opt-out | No — prevents a regression on tablets |
| R8 full mode pinned, uCrop bitmap cap | No |
| iOS groundwork (bundle ids, alarm channel, runbook) | No — nothing ships to Android users |

Deliberately **not** mentioned in the notes: the tablet opt-out (it prevents a
problem rather than fixing a visible one) and anything iOS.

---

## 🇬🇧 English (en-US) — MASTER

```
• Live home-screen widget. Your next shift now counts down in real time, even
  when Rostrik is closed — no more stale countdown. Works completely offline.
• Fixed a rare crash that could happen while your phone was starting up.
• Cleaner full-screen layout on older Android versions.
• Smaller, faster build under the hood.
```

## 🇪🇸 Spanish (es-ES)

```
• Widget de pantalla de inicio en vivo. Tu próximo turno ahora cuenta atrás en
  tiempo real, incluso con Rostrik cerrado. Funciona sin conexión.
• Corregido un fallo poco frecuente que podía ocurrir al encender el teléfono.
• Diseño a pantalla completa más limpio en versiones anteriores de Android.
• App más ligera y rápida por dentro.
```

## 🇧🇷 Portuguese (pt-BR)

```
• Widget da tela inicial ao vivo. Seu próximo turno agora tem contagem
  regressiva em tempo real, mesmo com o Rostrik fechado. Funciona offline.
• Corrigida uma falha rara que podia ocorrer ao ligar o celular.
• Layout em tela cheia mais limpo em versões antigas do Android.
• App menor e mais rápido internamente.
```

## 🇫🇷 French (fr-FR)

```
• Widget d'écran d'accueil en direct. Votre prochain poste est désormais
  décompté en temps réel, même quand Rostrik est fermé. Fonctionne hors ligne.
• Correction d'un plantage rare pouvant survenir au démarrage du téléphone.
• Affichage plein écran plus net sur les anciennes versions d'Android.
• Application plus légère et plus rapide en interne.
```

## 🇩🇪 German (de-DE)

```
• Live-Widget für den Startbildschirm. Deine nächste Schicht zählt jetzt in
  Echtzeit herunter, auch wenn Rostrik geschlossen ist. Funktioniert offline.
• Ein seltener Absturz beim Hochfahren des Telefons wurde behoben.
• Sauberere Vollbild-Darstellung auf älteren Android-Versionen.
• Kleinere, schnellere App im Hintergrund.
```

## 🇮🇹 Italian (it-IT)

```
• Widget della schermata Home in tempo reale. Il tuo prossimo turno ora fa il
  conto alla rovescia dal vivo, anche con Rostrik chiuso. Funziona offline.
• Corretto un raro arresto anomalo all'avvio del telefono.
• Layout a schermo intero più pulito sulle versioni precedenti di Android.
• App più leggera e veloce internamente.
```

## 🇳🇱 Dutch (nl-NL)

```
• Live widget op het startscherm. Je volgende dienst telt nu in realtime af,
  ook als Rostrik gesloten is. Werkt volledig offline.
• Een zeldzame crash tijdens het opstarten van je telefoon is verholpen.
• Strakkere schermvullende weergave op oudere Android-versies.
• Kleinere, snellere app onder de motorkap.
```

## 🇵🇱 Polish (pl-PL)

```
• Aktywny widżet na ekranie głównym. Twoja następna zmiana odlicza teraz czas
  na bieżąco, nawet gdy Rostrik jest zamknięty. Działa offline.
• Naprawiono rzadką awarię występującą podczas uruchamiania telefonu.
• Czytelniejszy układ pełnoekranowy na starszych wersjach Androida.
• Mniejsza i szybsza aplikacja od środka.
```

## 🇹🇷 Turkish (tr-TR)

```
• Canlı ana ekran widget'ı. Bir sonraki vardiyanız artık Rostrik kapalıyken
  bile gerçek zamanlı geri sayıyor. Tamamen çevrimdışı çalışır.
• Telefon açılırken oluşabilen nadir bir çökme giderildi.
• Eski Android sürümlerinde daha temiz tam ekran görünüm.
• Arka planda daha küçük ve hızlı bir uygulama.
```

## 🇮🇩 Indonesian (id-ID)

```
• Widget layar utama langsung. Shift berikutnya kini menghitung mundur secara
  real-time, bahkan saat Rostrik tertutup. Berfungsi sepenuhnya offline.
• Memperbaiki kerusakan langka yang bisa terjadi saat ponsel dinyalakan.
• Tata letak layar penuh lebih rapi di versi Android lama.
• Aplikasi lebih kecil dan cepat di balik layar.
```

## 🇯🇵 Japanese (ja-JP)

```
• ホーム画面ウィジェットがリアルタイム表示に。Rostrikを閉じていても次の
  シフトまでのカウントダウンが常に最新になります。完全オフラインで動作。
• 端末の起動中にまれに発生していたクラッシュを修正しました。
• 古いAndroidバージョンでの全画面表示を改善しました。
• 内部処理を軽量化し、動作を高速化しました。
```

## 🇰🇷 Korean (ko-KR)

```
• 실시간 홈 화면 위젯. 이제 Rostrik을 닫아도 다음 근무까지 남은 시간이
  실시간으로 표시됩니다. 완전히 오프라인으로 작동합니다.
• 휴대폰이 켜지는 동안 드물게 발생하던 오류를 수정했습니다.
• 이전 Android 버전에서 전체 화면 레이아웃을 개선했습니다.
• 앱을 더 가볍고 빠르게 개선했습니다.
```

## 🇷🇺 Russian (ru-RU)

```
• Живой виджет на главном экране. Обратный отсчёт до следующей смены теперь
  обновляется в реальном времени, даже когда Rostrik закрыт. Работает офлайн.
• Исправлен редкий сбой, который мог возникать при включении телефона.
• Более аккуратный полноэкранный режим на старых версиях Android.
• Приложение стало компактнее и быстрее.
```
