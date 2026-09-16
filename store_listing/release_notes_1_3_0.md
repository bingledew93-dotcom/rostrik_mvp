# Rostrik 1.3.0 (build 11) — Play "What's new" copy

Paste-ready release notes for the Play Console (Release → Production → *Create
new release* → **Release notes**, per language).

> Same caveat as [`play_store_listing.md`](play_store_listing.md): the
> non-English copy is **machine-assisted**, not professionally translated. The
> in-app translations for this release are going out to native-speaker
> reviewers (`tool/l10n_review_sheets.py`); these notes should be re-checked at
> the same time. Nothing here is a safety statement.

**Play limit: 500 characters per language.** Every entry below is under it.

## A mismatch worth fixing before you publish

The **listing** languages and the **app** languages are not the same set:

| | Listing | App UI |
|---|---|---|
| Russian | ✅ has a listing | ❌ no Russian UI — falls back to English |
| Vietnamese, Hindi, Arabic | ❌ no listing | ✅ full UI |

So the Russian notes below deliberately **do not** say "now available in
Russian" — that would be a promise the app doesn't keep. And the three
languages with a UI but no listing are the best-value custom listings to add
next, now that the app itself is translated. Tracked in TODO §2.6.

## What actually changed

For your own reference — not for the listing:

| Change | User-visible? |
|---|---|
| 15-language UI, follows device language, per-app picker | **Yes** — the headline |
| Snooze/Dismiss buttons on the ringing alarm's notification | **Yes** — was a dead end when the phone was in use |
| Dismissed alarms re-ringing after an update or reboot | **Yes** — and it repeated |
| Overlapping alarms tearing each other down | **Yes** — could also bypass a critical shift's shake |
| Background re-sync never ran on Android or iOS | **Yes** — alarms drifted out of step |
| Hold-to-dismiss fallback restored on the critical alarm screen | Yes, small |
| Warns when Android 14's full-screen-alarm permission is switched off | Only if they switched it off |
| Live language change now repaints the whole app | Yes, cosmetic |
| Arabic-Indic vs Western digits, Hindi letter spacing, calendar locale | Yes, cosmetic |

Deliberately **not** mentioned in the notes: the hold-to-dismiss fallback (it
only appears on critical alarms and needs explaining more than it needs
announcing), the i18n rendering fixes (invisible to anyone who wasn't already
seeing them broken), and the full-screen-permission warning (a diagnostic only
the handful of users who turned that off will ever see).

---

## 🇬🇧 English (en-US) — MASTER

```
• Rostrik now speaks 15 languages. It follows your phone's language, or you can
  choose one just for Rostrik in your phone's settings.
• Snooze or dismiss a ringing alarm straight from the notification — no need to
  open the app.
• Fixed alarms that could ring again after you'd dismissed them.
• Fixed two alarms set close together interfering with each other.
• Alarms now keep themselves up to date in the background.
```

## 🇪🇸 Spanish (es-ES)

```
• Rostrik ya está en español, y en 15 idiomas en total. Sigue el idioma de tu
  teléfono, o elige uno solo para Rostrik en los ajustes.
• Pospón o descarta una alarma que suena desde la propia notificación, sin
  abrir la app.
• Corregido: algunas alarmas volvían a sonar después de descartarlas.
• Corregido: dos alarmas seguidas se interferían entre sí.
• Las alarmas ahora se mantienen actualizadas en segundo plano.
```

## 🇧🇷 Portuguese (pt-BR)

```
• O Rostrik agora fala português, e 15 idiomas no total. Ele segue o idioma do
  seu celular, ou você escolhe um só para o Rostrik nas configurações.
• Adie ou dispense um alarme tocando direto pela notificação, sem abrir o app.
• Corrigido: alguns alarmes voltavam a tocar depois de dispensados.
• Corrigido: dois alarmes próximos interferiam um no outro.
• Os alarmes agora se mantêm atualizados em segundo plano.
```

## 🇫🇷 French (fr-FR)

```
• Rostrik parle désormais français, et 15 langues en tout. L'app suit la langue
  de votre téléphone, ou vous en choisissez une rien que pour Rostrik dans les
  réglages.
• Répétez ou arrêtez une alarme qui sonne directement depuis la notification,
  sans ouvrir l'app.
• Corrigé : certaines alarmes pouvaient resonner après avoir été arrêtées.
• Corrigé : deux alarmes rapprochées se gênaient mutuellement.
• Les alarmes se mettent à jour en arrière-plan.
```

## 🇩🇪 German (de-DE)

```
• Rostrik gibt es jetzt auf Deutsch – und in 15 Sprachen insgesamt. Die App
  folgt der Sprache deines Handys, oder du wählst in den Einstellungen eine
  eigene nur für Rostrik.
• Schlummern oder Beenden direkt über die Benachrichtigung des klingelnden
  Alarms, ohne die App zu öffnen.
• Behoben: Alarme konnten nach dem Beenden erneut klingeln.
• Behoben: Zwei kurz aufeinanderfolgende Alarme störten sich gegenseitig.
• Alarme halten sich jetzt im Hintergrund aktuell.
```

## 🇮🇹 Italian (it-IT)

```
• Rostrik ora parla italiano, e 15 lingue in tutto. Segue la lingua del tuo
  telefono, oppure ne scegli una solo per Rostrik nelle impostazioni.
• Rimanda o interrompi una sveglia che suona direttamente dalla notifica, senza
  aprire l'app.
• Corretto: alcune sveglie tornavano a suonare dopo essere state interrotte.
• Corretto: due sveglie ravvicinate interferivano tra loro.
• Le sveglie ora si mantengono aggiornate in background.
```

## 🇳🇱 Dutch (nl-NL)

```
• Rostrik spreekt nu Nederlands, en 15 talen in totaal. De app volgt de taal van
  je telefoon, of je kiest er in de instellingen één speciaal voor Rostrik.
• Snooze of stop een afgaand alarm rechtstreeks vanuit de melding, zonder de
  app te openen.
• Opgelost: sommige alarmen gingen opnieuw af nadat je ze had gestopt.
• Opgelost: twee alarmen kort na elkaar zaten elkaar in de weg.
• Alarmen blijven nu op de achtergrond bijgewerkt.
```

## 🇵🇱 Polish (pl-PL)

```
• Rostrik mówi teraz po polsku – łącznie w 15 językach. Aplikacja używa języka
  telefonu albo możesz wybrać osobny język tylko dla Rostrika w ustawieniach.
• Odłóż lub wyłącz dzwoniący alarm prosto z powiadomienia, bez otwierania
  aplikacji.
• Poprawka: niektóre alarmy dzwoniły ponownie po wyłączeniu.
• Poprawka: dwa alarmy ustawione blisko siebie przeszkadzały sobie nawzajem.
• Alarmy są teraz aktualizowane w tle.
```

## 🇹🇷 Turkish (tr-TR)

```
• Rostrik artık Türkçe konuşuyor; toplamda 15 dil. Telefonunuzun dilini takip
  eder ya da ayarlardan yalnızca Rostrik için bir dil seçebilirsiniz.
• Çalan bir alarmı doğrudan bildirimden erteleyin veya kapatın; uygulamayı
  açmanıza gerek yok.
• Düzeltildi: kapatılan bazı alarmlar yeniden çalabiliyordu.
• Düzeltildi: birbirine yakın iki alarm birbirini etkiliyordu.
• Alarmlar artık arka planda güncel kalıyor.
```

## 🇮🇩 Indonesian (id-ID)

```
• Rostrik kini berbahasa Indonesia, dan 15 bahasa secara total. Aplikasi
  mengikuti bahasa ponsel Anda, atau pilih satu khusus untuk Rostrik di
  pengaturan.
• Tunda atau matikan alarm yang berbunyi langsung dari notifikasi, tanpa
  membuka aplikasi.
• Diperbaiki: sebagian alarm berbunyi lagi setelah dimatikan.
• Diperbaiki: dua alarm berdekatan saling mengganggu.
• Alarm kini tetap diperbarui di latar belakang.
```

## 🇯🇵 Japanese (ja-JP)

```
• Rostrikが日本語に対応しました。全15言語です。端末の言語に自動で合わせるほか、
  設定でRostrikだけの言語を選ぶこともできます。
• 鳴っているアラームを、アプリを開かずに通知から直接スヌーズ・停止できます。
• 修正：停止したはずのアラームが再び鳴ることがある問題。
• 修正：近い時刻の2つのアラームが互いに干渉する問題。
• アラームがバックグラウンドで最新の状態を保つようになりました。
```

## 🇰🇷 Korean (ko-KR)

```
• Rostrik이 한국어를 지원합니다. 총 15개 언어입니다. 휴대폰 언어를 따르거나,
  설정에서 Rostrik만의 언어를 선택할 수 있습니다.
• 울리는 알람을 앱을 열지 않고 알림에서 바로 다시 알림 또는 해제할 수 있습니다.
• 수정: 해제한 알람이 다시 울리는 문제.
• 수정: 가까운 시각의 두 알람이 서로 간섭하는 문제.
• 이제 알람이 백그라운드에서 최신 상태를 유지합니다.
```

## 🇷🇺 Russian (ru-RU)

> **Note:** the app has no Russian UI — Russian speakers see English. These
> notes therefore mention the alarm fixes and the language support in general,
> and do **not** claim Rostrik is now in Russian.

```
• Rostrik теперь доступен на 15 языках и следует языку вашего телефона.
  Русского пока нет — интерфейс остаётся английским.
• Откладывайте или выключайте звонящий будильник прямо из уведомления, не
  открывая приложение.
• Исправлено: некоторые будильники звонили снова после выключения.
• Исправлено: два будильника подряд мешали друг другу.
• Будильники теперь обновляются в фоновом режиме.
```
