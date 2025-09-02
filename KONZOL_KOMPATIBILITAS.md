# Konzol Kompatibilitás Kezelés

A Robot Framework Duplikáció Ellenőrző rendszer támogatja mind a modern Unicode ikonokat, mind a régi CMD terminálok számára az ASCII karaktereket.

## Beállítás

A `Duplikacio.config` fájlban állíthatod be a konzol módot:

```ini
# Konzol megjelenítés mód (unicode/ascii)
# unicode: emojik és Unicode karakterek használata (PowerShell, modern terminálok)
# ascii: csak ASCII karakterek használata (régi CMD kompatibilitás)
console_mode=unicode
```

## Támogatott módok

### Unicode mód (console_mode=unicode)
- **Használat**: Modern PowerShell, VSCode terminal, Windows Terminal
- **Ikonok**: 📋 📧 📂 📁 📬 📊 🎯 🔍 📈 🟢 🟡 🔴 🏆 ✅ ❌ ⚠️

### ASCII mód (console_mode=ascii)  
- **Használat**: Régi Windows CMD, régi terminálok
- **Ikonok**: [CONFIG] [EMAIL] [INPUT] [OUTPUT] [SUBJECT] [EXCEL] [TARGET] [SEARCH] [CHART] [OK] [WARN] [ERROR] [RESULT] [FAIL]

## Automatikus észlelés

Ha CMD-ből futtatod és nem jelennek meg az ikonok megfelelően, állítsd át a konfigurációt ASCII módra:

```ini
console_mode=ascii
```

## Példa kimenet

### Unicode mód:
```
📋 KONFIGURACIO BETOLTESE...
✅ Konfiguracio sikeresen betoltve!
📧 Email: lovasz.otto@clarity.hu
📂 Bementi konyvtar: d:\tmp
```

### ASCII mód:
```
[CONFIG] KONFIGURACIO BETOLTESE...
[OK] Konfiguracio sikeresen betoltve!
[EMAIL] Email: lovasz.otto@clarity.hu
[INPUT] Bementi konyvtar: d:\tmp
```
