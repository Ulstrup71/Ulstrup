# Ulstrup – 3D-model af huset i 3ds Max 2027

`max/hus_ulstrup.ms` er et MAXScript, der bygger huset fra plantegningen op i 3ds Max 2027:
stueetage, kælder i skrånende terræn, to overdækkede terrasser, altan mod syd, svævende trappe, flat tag med udhæng og carport med redskabsrum.

## Sådan kører du det

1. Åbn 3ds Max 2027 (gerne en tom scene).
2. Vælg **Scripting → Run Script…** og vælg `max/hus_ulstrup.ms`. Du kan også trække filen ind i et viewport.
3. Scriptet sætter enhederne til meter og opretter alle objekter med navne, der starter med `HUS_`, fordelt på lag (`HUS_Ydervaegge`, `HUS_Indervaegge`, `HUS_Glas`, `HUS_Rammer`, `HUS_Tag`, `HUS_Carport`, `HUS_Terraen`, `HUS_Inventar`, `HUS_Kameraer` m.fl.).
4. Kører du scriptet igen, slettes de gamle `HUS_`-objekter først. Du kan altså rette et mål i scriptet og bare køre det igen.

Der oprettes to kameraer: `HUS_Kamera_SV`, som svarer nogenlunde til perspektivet på tegningen, og `HUS_Kamera_Indgang` ved carporten. Materialerne er Physical Materials, så de virker med både Arnold og Scanline/ART. Lys er ikke med; tilføj et Sun Positioner efter behov.

## Mål og fortolkning af tegningen

Tegningen har ingen målkæder, så målene er udledt af tegningens målestok og de oplyste rumarealer.

| Del | Model | Tegning |
|---|---|---|
| Stueetage | 17,0 × 7,6 m = 129 m² | 128 m² |
| Kælder (under den vestlige del) | 9,0 × 7,6 m = 68 m² brutto | 74 m² |
| Overdækket terrasse, stue og kælder | 2 × 3,0 × 7,6 m = 22,8 m² | 23,2 m² |
| Carport inkl. redskabsrum | 6,4 × 8,9 m = 57 m² | 57 m² |
| Redskabsrum | 6,4 × 1,7 m | 10,1 m² |

**Stueetage (vest → øst):** køkken/alrum med trappehul, værelse på 8,3 m² og vrkt. på 1,5 m², to værelser på 12 m², gang, wc/bad, åbent kontor, entré med hoveddør mod carporten og bryggers.

**Kælder:** wc/bad, soveværelse, walk-in, stue på 28,9 m² med glasparti mod den nedre terrasse, depot og teknik. Kælderens østvæg er støttevæg mod terrænet.

**Højder:**
- Loftshøjden er 2,60 m.
- Dækkene er 0,35 m tykke, så etagehøjden er 2,95 m.
- Trappen har 15 stigninger på 19,7 cm og grund på 25 cm.
- Vinduesbrystninger er 0,9 m. I badene sidder vinduerne højt, med brystning i 1,6 m.

Vinduernes placering er vurderet ud fra de massive vægstykker i planen og facadetegningen. Alle mål står som tal i scriptet, så de er nemme at justere. Hovedmålene (`L`, `D`, `LK`, `H`, `TER` …) står samlet øverst i afsnittet "hovedmaal".

## Begrænsninger

- Væggene er bygget som separate bokse uden booleans. Det er nemt at redigere, men ikke en sammenhængende mesh. Brug evt. *Attach* plus *ProBoolean* eller *Weld*, hvis du skal eksportere til andre programmer.
- Inventaret er kun simple klodser til skala.
- Terrænet er to plane flader med et spring ved kælderens østvæg. Det er ikke et egentligt skrånende terræn.
