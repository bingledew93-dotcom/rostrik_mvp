# Rostrik — Google Play store listing copy

Paste-ready **store-listing** text for the Play Console (Store presence →
Main store listing → *Manage translations* → add language → paste the fields).

> **What this is (and isn't).** These are the *marketing* strings the Play
> Console shows to users **before** they install (app name, short description,
> full description). They are **not** `.arb` files and are **not** the app's
> in-app translations — the app UI itself is still English-only. Localising the
> UI is a separate, larger job (set up Flutter `l10n`, extract every hardcoded
> string, then translate). See the "In-app localisation" note at the bottom.

## Play Console field limits
| Field | Max length | Notes |
|---|---|---|
| App name | 30 chars | Keep it **"Rostrik"** in every language — it's a brand, don't translate it. |
| Short description | 80 chars | The one-liner under the icon. |
| Full description | 4000 chars | The long listing. All copy below is well within limit. |

## ⚠️ Translation quality note
The non-English copy below is **machine-assisted** (produced here, not by a
professional translator). For a shipping listing it's good enough to publish,
but ideally have a **native speaker skim each one**, especially:
- The **"BACKUP alarm"** safety paragraph — it must stay accurate and clear in
  every language (it's a genuine safety/liability statement, not marketing).
- Idioms like *"a half-asleep tap can't"* and *"swing to nights"*.

Languages included below cover the large majority of global Play installs.
**I can generate any of the remaining ~65 Play languages on request** (Arabic,
Hindi, Chinese, Thai, Vietnamese, the Nordics, etc.) — I left the
harder-to-self-check scripts out of this first pass on purpose.

Locales that reuse a translation with only spelling tweaks:
- **en-GB / en-AU / en-CA** → use the English master as-is (no "z/s" issues in this copy).
- **es-419 (Latin America)** → the Spanish below works; "cuadrante" is Spain-specific, swap to "turnos" if targeting Latam only.
- **pt-PT** → the Portuguese below is pt-BR; minor wording differences only.

---

## 🇬🇧 English (en-US) — MASTER

**App name**
```
Rostrik
```

**Short description**
```
Automatic backup alarms for shift workers. Build your roster, wake on time.
```

**Full description**
```
Rostrik is the alarm app built for shift workers — nurses, drivers, first responders, factory and FIFO crews, hospitality, and anyone whose start time changes every day.

Set up your rotating roster once and Rostrik automatically schedules a wake-up alarm for every shift. No more re-setting your alarm each night, and no more oversleeping after a swing to nights.

BUILD YOUR ROSTER, YOUR WAY
• Paint your own rotation (Day / Afternoon / Night / Off)
• Start from a preset pattern, or edit any roster later
• Import a roster by pasting it into an AI assistant, or scan a printed roster with your camera
• Add one-off shifts, mark leave, and pause days

ALARMS THAT ACTUALLY WAKE YOU
• A wake-up alarm before every shift — set by lead time or exact time
• "Critical Shift" mode needs a firm, steady shake to switch off, so a half-asleep tap can't
• Choose your own alarm sounds
• Built to survive reboots and battery-saver, so your alarms are still there in the morning

SEE YOUR WEEK AT A GLANCE
• Timeline and month calendar of your whole roster
• Home-screen widget showing your next alarm
• Work history and timesheet you can export to CSV
• Optional sync to your device / Google Calendar

SLEEP TOOLS FOR SHIFT WORKERS
• A wind-down and bedtime reminder built around your next wake-up
• White and brown noise sounds with an auto-stop timer

Prefer a lighter look? Switch between the classic dark theme and a warm cream light theme any time.

IMPORTANT: Rostrik is a BACKUP alarm. Alarms depend on your phone and its settings, so please don't rely on Rostrik as your only alarm for anything critical. Keep a second alarm for shifts you can't miss.

Try everything free for 14 days. Unlock full access with a single one-time purchase — no subscription.
```

---

## 🇪🇸 Spanish (es-ES)

**App name**
```
Rostrik
```

**Short description**
```
Alarmas automáticas para trabajadores por turnos. Despierta siempre a tiempo.
```

**Full description**
```
Rostrik es la app de alarmas creada para quienes trabajan por turnos: enfermería, conducción, emergencias, fábricas, hostelería y cualquiera cuya hora de entrada cambia cada día.

Configura tu rotación una vez y Rostrik programará automáticamente una alarma para cada turno. Se acabó volver a poner la alarma cada noche y quedarte dormido al pasar al turno de noche.

CREA TU CUADRANTE A TU MANERA
• Diseña tu propia rotación (Mañana / Tarde / Noche / Libre)
• Empieza desde un patrón predefinido o edita cualquier turno después
• Importa tu cuadrante pegándolo en un asistente de IA, o escanéalo con la cámara
• Añade turnos puntuales, marca vacaciones y pausa días

ALARMAS QUE DE VERDAD TE DESPIERTAN
• Una alarma antes de cada turno, por tiempo de antelación u hora exacta
• El modo "Turno Crítico" solo se apaga con una sacudida firme y constante; un toque medio dormido no basta
• Elige tus propios sonidos de alarma
• Preparada para sobrevivir a reinicios y al ahorro de batería

TU SEMANA DE UN VISTAZO
• Línea de tiempo y calendario mensual de todo tu cuadrante
• Widget en la pantalla de inicio con tu próxima alarma
• Historial de trabajo exportable a CSV
• Sincronización opcional con el calendario del dispositivo / Google Calendar

HERRAMIENTAS DE SUEÑO
• Recordatorio de relajación y de hora de dormir según tu próximo despertar
• Sonidos de ruido blanco y marrón con temporizador de apagado

¿Prefieres un aspecto más claro? Cambia entre el tema oscuro clásico y un cálido tema claro cuando quieras.

IMPORTANTE: Rostrik es una alarma de RESPALDO. Las alarmas dependen de tu teléfono y su configuración, así que no dependas de Rostrik como tu única alarma para algo importante. Mantén una segunda alarma para los turnos que no puedes perder.

Prueba todo gratis durante 14 días. Desbloquea el acceso completo con un único pago; sin suscripción.
```

---

## 🇧🇷 Portuguese (pt-BR)

**App name**
```
Rostrik
```

**Short description**
```
Alarmes automáticos para quem trabalha por turnos. Acorde sempre na hora.
```

**Full description**
```
O Rostrik é o app de alarmes feito para quem trabalha por turnos: enfermagem, motoristas, socorristas, fábricas, hotelaria e qualquer pessoa cujo horário de entrada muda todos os dias.

Configure sua escala de turnos uma vez e o Rostrik agenda automaticamente um alarme para cada turno. Chega de reprogramar o alarme toda noite ou dormir demais depois de virar para o turno da noite.

MONTE SUA ESCALA DO SEU JEITO
• Desenhe sua própria rotação (Manhã / Tarde / Noite / Folga)
• Comece por um padrão pronto ou edite qualquer escala depois
• Importe sua escala colando em um assistente de IA, ou digitalize uma escala impressa com a câmera
• Adicione turnos avulsos, marque férias e pause dias

ALARMES QUE REALMENTE ACORDAM VOCÊ
• Um alarme antes de cada turno, por antecedência ou horário exato
• O modo "Turno Crítico" só desliga com um chacoalhão firme e constante; um toque meio dormindo não resolve
• Escolha seus próprios sons de alarme
• Feito para sobreviver a reinicializações e ao modo de economia de bateria

SUA SEMANA EM UM OLHAR
• Linha do tempo e calendário mensal de toda a sua escala
• Widget na tela inicial com o próximo alarme
• Histórico de trabalho exportável em CSV
• Sincronização opcional com o calendário do aparelho / Google Agenda

FERRAMENTAS DE SONO
• Lembrete de relaxamento e de hora de dormir com base no seu próximo despertar
• Sons de ruído branco e marrom com timer de desligamento automático

Prefere um visual mais claro? Alterne entre o tema escuro clássico e um tema claro creme quando quiser.

IMPORTANTE: o Rostrik é um alarme de BACKUP. Os alarmes dependem do seu celular e das suas configurações, então não dependa do Rostrik como seu único alarme para nada crítico. Mantenha um segundo alarme para os turnos que você não pode perder.

Experimente tudo grátis por 14 dias. Libere o acesso completo com um único pagamento; sem assinatura.
```

---

## 🇫🇷 French (fr-FR)

**App name**
```
Rostrik
```

**Short description**
```
Alarmes de secours automatiques pour les travailleurs postés. Réveil garanti.
```

**Full description**
```
Rostrik est l'application de réveil conçue pour les travailleurs postés : personnel soignant, chauffeurs, secours, usines, hôtellerie et toute personne dont l'heure de prise de poste change chaque jour.

Configurez votre rotation une seule fois et Rostrik programme automatiquement une alarme pour chaque poste. Fini de régler votre réveil chaque soir et de vous rendormir après un passage aux nuits.

CRÉEZ VOTRE PLANNING À VOTRE FAÇON
• Dessinez votre propre rotation (Matin / Après-midi / Nuit / Repos)
• Partez d'un modèle prédéfini ou modifiez un planning à tout moment
• Importez un planning en le collant dans un assistant IA, ou scannez un planning imprimé avec l'appareil photo
• Ajoutez des postes ponctuels, marquez les congés et mettez des jours en pause

DES ALARMES QUI VOUS RÉVEILLENT VRAIMENT
• Une alarme avant chaque poste, selon un délai ou une heure exacte
• Le mode « Poste critique » ne s'éteint qu'avec une secousse ferme et continue ; un simple appui à moitié endormi ne suffit pas
• Choisissez vos propres sons d'alarme
• Conçu pour résister aux redémarrages et à l'économie de batterie

VOTRE SEMAINE EN UN COUP D'ŒIL
• Frise chronologique et calendrier mensuel de tout votre planning
• Widget sur l'écran d'accueil avec votre prochaine alarme
• Historique de travail exportable en CSV
• Synchronisation facultative avec l'agenda de l'appareil / Google Agenda

OUTILS DE SOMMEIL
• Un rappel de détente et de coucher basé sur votre prochain réveil
• Sons de bruit blanc et marron avec minuteur d'arrêt automatique

Vous préférez un rendu plus clair ? Basculez entre le thème sombre classique et un thème clair crème chaleureux quand vous le souhaitez.

IMPORTANT : Rostrik est une alarme de SECOURS. Les alarmes dépendent de votre téléphone et de ses réglages ; ne comptez donc pas sur Rostrik comme unique réveil pour quelque chose d'important. Gardez une seconde alarme pour les postes à ne pas manquer.

Essayez tout gratuitement pendant 14 jours. Débloquez l'accès complet avec un seul achat unique — sans abonnement.
```

---

## 🇩🇪 German (de-DE)

**App name**
```
Rostrik
```

**Short description**
```
Automatische Backup-Wecker für Schichtarbeiter. Bau deinen Dienstplan, wach auf.
```

**Full description**
```
Rostrik ist die Wecker-App für Schichtarbeiter – Pflegekräfte, Fahrer, Rettungsdienste, Fabrik- und Montageteams, Gastgewerbe und alle, deren Arbeitsbeginn sich jeden Tag ändert.

Richte deinen Schichtplan einmal ein, und Rostrik stellt automatisch für jede Schicht einen Wecker. Kein nächtliches Neustellen mehr und kein Verschlafen nach dem Wechsel in die Nachtschicht.

ERSTELLE DEINEN DIENSTPLAN, WIE DU WILLST
• Male deine eigene Rotation (Früh / Spät / Nacht / Frei)
• Starte mit einer Vorlage oder bearbeite jeden Plan später
• Importiere einen Plan, indem du ihn in einen KI-Assistenten einfügst, oder scanne einen gedruckten Plan mit der Kamera
• Füge einzelne Schichten hinzu, markiere Urlaub und pausiere Tage

WECKER, DIE DICH WIRKLICH WECKEN
• Ein Wecker vor jeder Schicht – nach Vorlaufzeit oder exakter Uhrzeit
• Der Modus „Kritische Schicht" lässt sich nur durch festes, gleichmäßiges Schütteln abstellen; ein halb verschlafenes Tippen reicht nicht
• Wähle deine eigenen Weckertöne
• Übersteht Neustarts und den Energiesparmodus

DEINE WOCHE AUF EINEN BLICK
• Zeitleiste und Monatskalender deines gesamten Plans
• Startbildschirm-Widget mit deinem nächsten Wecker
• Arbeitsverlauf als CSV exportierbar
• Optionale Synchronisierung mit dem Gerätekalender / Google Kalender

SCHLAF-TOOLS
• Eine Erinnerung zum Herunterkommen und zur Schlafenszeit, abgestimmt auf dein nächstes Aufwachen
• Weißes und braunes Rauschen mit Abschalt-Timer

Lieber ein helleres Design? Wechsle jederzeit zwischen dem klassischen dunklen Design und einem warmen, cremefarbenen hellen Design.

WICHTIG: Rostrik ist ein BACKUP-Wecker. Wecker hängen von deinem Telefon und dessen Einstellungen ab – verlass dich bei Wichtigem also nicht allein auf Rostrik. Behalte einen zweiten Wecker für Schichten, die du nicht verpassen darfst.

Teste alles 14 Tage kostenlos. Schalte den vollen Zugriff mit einem einzigen einmaligen Kauf frei – kein Abo.
```

---

## 🇮🇹 Italian (it-IT)

**App name**
```
Rostrik
```

**Short description**
```
Sveglie di riserva automatiche per i turnisti. Crea il turno, svegliati in orario.
```

**Full description**
```
Rostrik è l'app di sveglie pensata per chi lavora su turni: infermieri, autisti, soccorritori, fabbriche, ristorazione e chiunque abbia un orario d'ingresso che cambia ogni giorno.

Imposta la tua rotazione una volta e Rostrik programma automaticamente una sveglia per ogni turno. Basta rimettere la sveglia ogni sera e niente più risvegli tardivi dopo il passaggio ai turni di notte.

CREA IL TUO TURNO COME VUOI
• Disegna la tua rotazione (Mattino / Pomeriggio / Notte / Riposo)
• Parti da uno schema predefinito o modifica qualsiasi turno in seguito
• Importa un turno incollandolo in un assistente IA, oppure scansiona un turno stampato con la fotocamera
• Aggiungi turni singoli, segna le ferie e metti in pausa i giorni

SVEGLIE CHE TI SVEGLIANO DAVVERO
• Una sveglia prima di ogni turno, in base al preavviso o all'ora esatta
• La modalità "Turno Critico" si spegne solo con uno scuotimento deciso e costante; un tocco mezzo addormentato non basta
• Scegli i tuoi suoni della sveglia
• Progettata per resistere ai riavvii e al risparmio energetico

LA TUA SETTIMANA A COLPO D'OCCHIO
• Linea del tempo e calendario mensile di tutto il tuo turno
• Widget nella schermata Home con la prossima sveglia
• Cronologia di lavoro esportabile in CSV
• Sincronizzazione facoltativa con il calendario del dispositivo / Google Calendar

STRUMENTI PER IL SONNO
• Un promemoria per il relax e per l'ora di dormire, basato sul tuo prossimo risveglio
• Suoni di rumore bianco e marrone con timer di spegnimento

Preferisci un aspetto più chiaro? Passa dal classico tema scuro a un caldo tema chiaro color crema quando vuoi.

IMPORTANTE: Rostrik è una sveglia di RISERVA. Le sveglie dipendono dal telefono e dalle sue impostazioni, quindi non affidarti a Rostrik come unica sveglia per qualcosa di importante. Tieni una seconda sveglia per i turni da non perdere.

Prova tutto gratis per 14 giorni. Sblocca l'accesso completo con un unico acquisto — nessun abbonamento.
```

---

## 🇳🇱 Dutch (nl-NL)

**App name**
```
Rostrik
```

**Short description**
```
Automatische reservewekkers voor ploegendiensten. Maak je rooster, word op tijd wakker.
```

**Full description**
```
Rostrik is de wekker-app voor ploegendienstwerkers: verpleegkundigen, chauffeurs, hulpdiensten, fabrieks- en montageploegen, horeca en iedereen van wie de begintijd elke dag verandert.

Stel je roterende rooster één keer in en Rostrik plant automatisch een wekker voor elke dienst. Nooit meer elke avond je wekker opnieuw zetten en niet meer verslapen na een overstap naar nachtdiensten.

MAAK JE ROOSTER, OP JOUW MANIER
• Teken je eigen rotatie (Dag / Middag / Nacht / Vrij)
• Begin met een vast patroon of pas elk rooster later aan
• Importeer een rooster door het in een AI-assistent te plakken, of scan een geprint rooster met je camera
• Voeg losse diensten toe, markeer verlof en pauzeer dagen

WEKKERS DIE JE ÉCHT WAKKER MAKEN
• Een wekker vóór elke dienst, op voorlooptijd of exact tijdstip
• De modus "Kritieke dienst" gaat alleen uit met stevig, aanhoudend schudden; een half slapende tik werkt niet
• Kies je eigen wekkergeluiden
• Gemaakt om herstarts en batterijbesparing te overleven

JE WEEK IN ÉÉN OOGOPSLAG
• Tijdlijn en maandkalender van je hele rooster
• Widget op je startscherm met je volgende wekker
• Werkgeschiedenis, exporteerbaar naar CSV
• Optionele synchronisatie met de agenda van je apparaat / Google Agenda

SLAAPHULPMIDDELEN
• Een afbouw- en bedtijdherinnering rond je volgende wektijd
• Wit en bruin ruisgeluid met een timer voor automatisch stoppen

Liever een lichtere look? Wissel wanneer je wilt tussen het klassieke donkere thema en een warm crèmekleurig licht thema.

BELANGRIJK: Rostrik is een RESERVEWEKKER. Wekkers zijn afhankelijk van je telefoon en de instellingen, dus vertrouw voor iets belangrijks niet alleen op Rostrik. Houd een tweede wekker aan voor diensten die je niet mag missen.

Probeer alles 14 dagen gratis. Ontgrendel volledige toegang met één eenmalige aankoop — geen abonnement.
```

---

## 🇵🇱 Polish (pl-PL)

**App name**
```
Rostrik
```

**Short description**
```
Automatyczne budziki zapasowe dla pracowników zmianowych. Zbuduj grafik i wstań.
```

**Full description**
```
Rostrik to aplikacja-budzik stworzona dla pracowników zmianowych: pielęgniarek, kierowców, ratowników, załóg fabryk, gastronomii i każdego, kto codziennie zaczyna pracę o innej porze.

Ustaw swój grafik zmian raz, a Rostrik automatycznie zaplanuje budzik na każdą zmianę. Koniec z nastawianiem budzika co wieczór i zaspaniem po przejściu na nocki.

ZBUDUJ GRAFIK PO SWOJEMU
• Namaluj własną rotację (Ranna / Popołudniowa / Nocna / Wolne)
• Zacznij od gotowego wzorca lub edytuj dowolny grafik później
• Zaimportuj grafik, wklejając go do asystenta AI, albo zeskanuj wydrukowany grafik aparatem
• Dodawaj pojedyncze zmiany, oznaczaj urlop i wstrzymuj dni

BUDZIKI, KTÓRE NAPRAWDĘ BUDZĄ
• Budzik przed każdą zmianą — z wyprzedzeniem lub o dokładnej godzinie
• Tryb „Zmiana krytyczna" wyłączysz tylko mocnym, równym potrząśnięciem; zaspany dotyk nie wystarczy
• Wybierz własne dźwięki budzika
• Odporny na restarty i tryb oszczędzania baterii

TWÓJ TYDZIEŃ NA PIERWSZY RZUT OKA
• Oś czasu i kalendarz miesięczny całego grafiku
• Widżet na ekranie głównym z najbliższym budzikiem
• Historia pracy z eksportem do CSV
• Opcjonalna synchronizacja z kalendarzem urządzenia / Kalendarzem Google

NARZĘDZIA DO SNU
• Przypomnienie o wyciszeniu i porze snu dopasowane do najbliższej pobudki
• Biały i brązowy szum z licznikiem automatycznego wyłączenia

Wolisz jaśniejszy wygląd? W każdej chwili przełączaj się między klasycznym ciemnym motywem a ciepłym, kremowym jasnym motywem.

WAŻNE: Rostrik to budzik ZAPASOWY. Budziki zależą od telefonu i jego ustawień, więc w ważnych sprawach nie polegaj wyłącznie na Rostrik. Miej drugi budzik na zmiany, których nie możesz przegapić.

Wypróbuj wszystko bezpłatnie przez 14 dni. Odblokuj pełny dostęp jednym, jednorazowym zakupem — bez subskrypcji.
```

---

## 🇹🇷 Turkish (tr-TR)

**App name**
```
Rostrik
```

**Short description**
```
Vardiyalı çalışanlar için otomatik yedek alarmlar. Vardiyanı kur, zamanında kalk.
```

**Full description**
```
Rostrik, vardiyalı çalışanlar için tasarlanmış alarm uygulamasıdır: hemşireler, sürücüler, acil ekipler, fabrika çalışanları, konaklama sektörü ve her gün işe başlama saati değişen herkes.

Vardiya döngünü bir kez kur, Rostrik her vardiya için otomatik olarak bir alarm ayarlasın. Her gece alarmı yeniden kurmak yok, gece vardiyasına geçince uyuya kalmak yok.

VARDİYANI İSTEDİĞİN GİBİ OLUŞTUR
• Kendi döngünü çiz (Gündüz / Öğleden Sonra / Gece / İzin)
• Hazır bir desenle başla ya da herhangi bir vardiyayı sonradan düzenle
• Vardiyanı bir yapay zekâ asistanına yapıştırarak içe aktar veya basılı vardiyayı kameranla tara
• Tek seferlik vardiyalar ekle, izinleri işaretle ve günleri duraklat

SENİ GERÇEKTEN UYANDIRAN ALARMLAR
• Her vardiyadan önce bir alarm — süre öncesi ya da tam saatte
• "Kritik Vardiya" modu yalnızca sıkı ve düzenli bir sallamayla kapanır; yarı uykulu bir dokunuş yetmez
• Kendi alarm seslerini seç
• Yeniden başlatmalara ve pil tasarrufuna dayanacak şekilde tasarlandı

HAFTANI TEK BAKIŞTA GÖR
• Tüm vardiyanın zaman çizelgesi ve aylık takvimi
• Ana ekranda sıradaki alarmını gösteren widget
• CSV olarak dışa aktarılabilen çalışma geçmişi
• Cihaz takvimi / Google Takvim ile isteğe bağlı senkronizasyon

UYKU ARAÇLARI
• Sıradaki uyanışına göre ayarlanan yatış öncesi ve uyku hatırlatıcısı
• Otomatik durdurma zamanlayıcılı beyaz ve kahverengi gürültü sesleri

Daha aydınlık bir görünüm mü? Klasik koyu tema ile sıcak krem rengi açık tema arasında istediğin zaman geçiş yap.

ÖNEMLİ: Rostrik bir YEDEK alarmdır. Alarmlar telefonuna ve ayarlarına bağlıdır; bu yüzden önemli bir şey için tek alarmın olarak Rostrik'e güvenme. Kaçıramayacağın vardiyalar için ikinci bir alarm bulundur.

Her şeyi 14 gün ücretsiz dene. Tam erişimi tek seferlik tek bir satın alımla aç — abonelik yok.
```

---

## 🇮🇩 Indonesian (id-ID)

**App name**
```
Rostrik
```

**Short description**
```
Alarm cadangan otomatis untuk pekerja shift. Susun jadwal, bangun tepat waktu.
```

**Full description**
```
Rostrik adalah aplikasi alarm yang dibuat untuk pekerja shift: perawat, sopir, tim tanggap darurat, pekerja pabrik, perhotelan, dan siapa pun yang jam masuk kerjanya berubah setiap hari.

Atur rotasi shift-mu sekali saja, dan Rostrik otomatis menjadwalkan alarm untuk setiap shift. Tidak perlu lagi menyetel alarm tiap malam, dan tidak lagi kesiangan setelah pindah ke shift malam.

SUSUN JADWAL SESUAI CARAMU
• Gambar rotasimu sendiri (Pagi / Siang / Malam / Libur)
• Mulai dari pola siap pakai atau edit jadwal kapan saja
• Impor jadwal dengan menempelkannya ke asisten AI, atau pindai jadwal cetak dengan kamera
• Tambahkan shift sekali jalan, tandai cuti, dan jeda hari

ALARM YANG BENAR-BENAR MEMBANGUNKAN
• Alarm sebelum setiap shift — berdasarkan waktu ancang-ancang atau jam pasti
• Mode "Shift Kritis" hanya bisa dimatikan dengan guncangan mantap dan stabil; sentuhan setengah tidur tidak cukup
• Pilih nada alarmmu sendiri
• Dibuat agar bertahan dari mulai ulang dan mode hemat baterai

LIHAT PEKANMU SEKILAS
• Linimasa dan kalender bulanan seluruh jadwalmu
• Widget layar utama dengan alarm berikutnya
• Riwayat kerja yang bisa diekspor ke CSV
• Sinkronisasi opsional dengan kalender perangkat / Google Kalender

ALAT BANTU TIDUR
• Pengingat bersantai dan waktu tidur yang disesuaikan dengan waktu bangunmu berikutnya
• Suara white noise dan brown noise dengan timer berhenti otomatis

Suka tampilan lebih terang? Beralih antara tema gelap klasik dan tema terang krem yang hangat kapan saja.

PENTING: Rostrik adalah alarm CADANGAN. Alarm bergantung pada ponsel dan pengaturannya, jadi jangan andalkan Rostrik sebagai satu-satunya alarm untuk hal penting. Sediakan alarm kedua untuk shift yang tidak boleh terlewat.

Coba semuanya gratis selama 14 hari. Buka akses penuh dengan satu kali pembelian — tanpa langganan.
```

---

## 🇯🇵 Japanese (ja-JP)

**App name**
```
Rostrik
```

**Short description**
```
シフト勤務者のための自動バックアップアラーム。勤務表を作って、時間通りに起床。
```

**Full description**
```
Rostrik（ロストリック）は、シフト勤務の方のために作られたアラームアプリです。看護師、ドライバー、救急隊、工場勤務、接客業など、始業時間が毎日変わるすべての方に。

一度シフトのローテーションを設定すれば、Rostrik が各勤務に合わせてアラームを自動で設定します。毎晩アラームを設定し直す必要も、夜勤に切り替わった後の寝過ごしもなくなります。

自分好みに勤務表を作成
• 独自のローテーションを描く（日勤／午後／夜勤／休み）
• プリセットのパターンから始める、または後からいつでも編集
• シフトを AI アシスタントに貼り付けて取り込む、または印刷された勤務表をカメラでスキャン
• 単発の勤務を追加、休暇の記録、日の一時停止

本当に目を覚まさせるアラーム
• 各勤務の前にアラーム。事前の時間指定でも、正確な時刻でも設定可能
• 「クリティカルシフト」モードは、しっかり一定に振らないと止まりません。半分眠ったままのタップでは止められません
• アラーム音を自由に選べます
• 再起動やバッテリーセーバーにも耐える設計

一週間をひと目で把握
• 勤務表全体のタイムラインと月間カレンダー
• 次のアラームを表示するホーム画面ウィジェット
• CSV に書き出せる勤務履歴
• 端末カレンダー／Google カレンダーへの任意の同期

睡眠サポート機能
• 次の起床時間に合わせた、リラックスと就寝のリマインダー
• 自動停止タイマー付きのホワイトノイズ・ブラウンノイズ

明るい見た目がお好みですか？ 定番のダークテーマと、温かみのあるクリーム色のライトテーマをいつでも切り替えられます。

重要：Rostrik は「バックアップ用」のアラームです。アラームはスマートフォンとその設定に依存するため、重要な予定の唯一のアラームとして Rostrik だけに頼らないでください。絶対に外せない勤務には、二つ目のアラームもご用意ください。

すべての機能を14日間無料でお試しいただけます。買い切り一回のご購入でフルアクセスをアンロック。サブスクリプションはありません。
```

---

## 🇰🇷 Korean (ko-KR)

**App name**
```
Rostrik
```

**Short description**
```
교대 근무자를 위한 자동 백업 알람. 근무표를 만들고 제시간에 일어나세요.
```

**Full description**
```
Rostrik(로스트릭)은 교대 근무자를 위해 만든 알람 앱입니다. 간호사, 운전기사, 응급 요원, 공장 및 현장 근무자, 서비스업 등 매일 출근 시간이 바뀌는 모든 분을 위한 앱입니다.

교대 근무표를 한 번만 설정하면 Rostrik이 각 근무마다 기상 알람을 자동으로 예약합니다. 매일 밤 알람을 다시 맞출 필요도, 야간 근무로 바뀐 뒤 늦잠 잘 일도 없습니다.

내 방식대로 근무표 만들기
• 나만의 순환 근무를 그리기 (주간 / 오후 / 야간 / 휴무)
• 미리 설정된 패턴으로 시작하거나 언제든 근무표 수정
• 근무표를 AI 어시스턴트에 붙여넣어 가져오거나, 인쇄된 근무표를 카메라로 스캔
• 일회성 근무 추가, 휴가 표시, 날짜 일시중지

정말로 깨워주는 알람
• 모든 근무 전 알람 — 여유 시간 기준 또는 정확한 시각 기준
• "크리티컬 시프트" 모드는 단단하고 꾸준한 흔들기로만 꺼집니다. 반쯤 잠든 채 두드려서는 꺼지지 않습니다
• 원하는 알람 소리 선택
• 재부팅과 배터리 절약 모드에도 견디도록 설계

한눈에 보는 이번 주
• 전체 근무표의 타임라인과 월간 달력
• 다음 알람을 보여주는 홈 화면 위젯
• CSV로 내보낼 수 있는 근무 이력
• 기기 캘린더 / Google 캘린더와 선택적 동기화

수면 도구
• 다음 기상 시간에 맞춘 이완 및 취침 알림
• 자동 정지 타이머가 있는 백색 소음 및 갈색 소음

더 밝은 느낌을 원하시나요? 클래식한 다크 테마와 따뜻한 크림색 라이트 테마를 언제든 전환할 수 있습니다.

중요: Rostrik은 '백업' 알람입니다. 알람은 휴대폰과 그 설정에 따라 달라지므로, 중요한 일에 Rostrik을 유일한 알람으로 의존하지 마세요. 놓쳐서는 안 되는 근무에는 두 번째 알람을 준비해 두세요.

모든 기능을 14일 동안 무료로 사용해 보세요. 한 번의 일회성 구매로 전체 기능을 잠금 해제하세요. 구독이 아닙니다.
```

---

## 🇷🇺 Russian (ru-RU)

**App name**
```
Rostrik
```

**Short description**
```
Автоматические резервные будильники для сменных работников. Проснитесь вовремя.
```

**Full description**
```
Rostrik — приложение-будильник, созданное для сменных работников: медсестёр, водителей, спасателей, заводских и вахтовых бригад, сферы обслуживания и всех, у кого время начала работы меняется каждый день.

Настройте свой сменный график один раз, и Rostrik автоматически поставит будильник на каждую смену. Больше не нужно заводить будильник каждый вечер, и вы не проспите после перехода в ночную смену.

СОСТАВЬТЕ ГРАФИК ПО-СВОЕМУ
• Нарисуйте собственную ротацию (День / Вечер / Ночь / Выходной)
• Начните с готового шаблона или отредактируйте любой график позже
• Импортируйте график, вставив его в ИИ-ассистента, или отсканируйте распечатанный график камерой
• Добавляйте разовые смены, отмечайте отпуск и ставьте дни на паузу

БУДИЛЬНИКИ, КОТОРЫЕ ДЕЙСТВИТЕЛЬНО БУДЯТ
• Будильник перед каждой сменой — по времени заранее или в точное время
• Режим «Критическая смена» выключается только уверенным, ровным встряхиванием; сонное касание не сработает
• Выбирайте свои звуки будильника
• Работает даже после перезагрузки и в режиме энергосбережения

ВАША НЕДЕЛЯ С ПЕРВОГО ВЗГЛЯДА
• Лента и месячный календарь всего графика
• Виджет на главном экране со следующим будильником
• История работы с экспортом в CSV
• Необязательная синхронизация с календарём устройства / Google Календарём

ИНСТРУМЕНТЫ ДЛЯ СНА
• Напоминание расслабиться и лечь спать с учётом ближайшего пробуждения
• Белый и коричневый шум с таймером автоотключения

Предпочитаете более светлый вид? В любой момент переключайтесь между классической тёмной темой и тёплой кремовой светлой темой.

ВАЖНО: Rostrik — это РЕЗЕРВНЫЙ будильник. Будильники зависят от телефона и его настроек, поэтому не полагайтесь на Rostrik как на единственный будильник в важных случаях. Держите второй будильник для смен, которые нельзя пропустить.

Попробуйте всё бесплатно в течение 14 дней. Откройте полный доступ одной разовой покупкой — без подписки.
```

---

## In-app localisation (separate, larger job — not done here)
To translate the **app's own UI** (buttons, screens, alarm text) rather than the
store listing, the app first needs Flutter localisation set up:
1. Add `flutter_localizations` + an `l10n.yaml`.
2. Extract every hardcoded English string into `lib/l10n/app_en.arb` and refactor
   each screen to read from the generated `AppLocalizations`.
3. Only then add `app_es.arb`, `app_de.arb`, … per language.

This is a wide refactor (hundreds of strings across ~40 screens). The
**safety-critical "backup alarm" copy** in particular should be translated by a
native speaker, not machine-translated. Happy to scaffold step 1–2 (the English
template) whenever you want to start.
```
