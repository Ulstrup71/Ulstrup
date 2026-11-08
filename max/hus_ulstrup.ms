/*
    hus_ulstrup.ms
    ----------------------------------------------------------------------
    Opbygger huset fra plantegningen (stueetage 128 m2, "kaelder" 74 m2,
    2 x overdaekket terrasse, carport med redskabsrum) i 3ds Max 2027.

    Koer:  Scripting > Run Script...  og vaelg denne fil
           (eller traek filen ind i et viewport).

    Koordinatsystem (meter):
      X = husets laengderetning, 0 = vestlig ydervaeg (mod terrassen)
      Y = nord (planens top = Y 0, sydfacaden ligger ved Y = -7.6)
      Z = 0 = faerdigt gulv i stueetagen, kaelderens gulv = -2.95

    Alle objekter faar navne der starter med "HUS_" og placeres paa lag
    der starter med "HUS_". Koerer man scriptet igen, slettes de gamle
    HUS_-objekter foerst, saa man kan rette maal og koere igen.

    Maalene er afledt af tegningens maalestok og rumarealer, se README.md.
*/
(
    ---------------------------------------------------------------- enheder
    units.SystemType  = #Meters
    units.DisplayType = #Metric
    units.MetricType  = #Meters

    ---------------------------------------------------------------- oprydning
    delete (for o in objects where matchPattern o.name pattern:"HUS_*" collect o)

    ---------------------------------------------------------------- hjaelpere
    fn getLayer nm =
    (
        local l = LayerManager.getLayerFromName nm
        if l == undefined do l = LayerManager.newLayerFromName nm
        l
    )

    -- Box ud fra to hjoerner i PLAN-koordinater (y nedad i planen = syd).
    fn mkBox nm x0 y0 z0 x1 y1 z1 mat lay =
    (
        local w = abs (x1 - x0), l = abs (y1 - y0), h = abs (z1 - z0)
        if w < 0.001 or l < 0.001 or h < 0.001 then undefined else
        (
            local b = Box name:(uniqueName ("HUS_" + nm + "_")) \
                          width:w length:l height:h \
                          pos:[(x0 + x1) / 2.0, -(y0 + y1) / 2.0, amin z0 z1]
            b.material = mat
            if mat != undefined do b.wirecolor = mat.base_color
            (getLayer lay).addNode b
            b
        )
    )

    -- axis #x: a = x-interval, c = y-interval.  axis #y: a = y, c = x.
    fn segBox nm axis a0 a1 c0 c1 z0 z1 mat lay =
    (
        if axis == #x then mkBox nm a0 c0 z0 a1 c1 z1 mat lay
                      else mkBox nm c0 a0 z0 c1 a1 z1 mat lay
    )

    -- Vaeg med aabninger. openings: #(#(fra, til, brystning, overkant, type), ...)
    -- type: #glass (vindue/glasparti), #door (massiv doer), #open (hul)
    fn mkWall nm axis a0 a1 c0 c1 z0 z1 openings matW matG matF matD lay =
    (
        local cur = a0
        local cm = (c0 + c1) / 2.0
        for op in openings do
        (
            local oa = op[1], ob = op[2], zs = z0 + op[3], zh = z0 + op[4], kind = op[5]
            if oa > cur do segBox nm axis cur oa c0 c1 z0 z1 matW lay
            if zs > z0 + 0.001 do segBox (nm + "_Bryst") axis oa ob c0 c1 z0 zs matW lay
            if zh < z1 - 0.001 do segBox (nm + "_Overligger") axis oa ob c0 c1 zh z1 matW lay
            case kind of
            (
                #glass:
                (
                    local ft = 0.06, fd = 0.05
                    segBox (nm + "_Glas") axis oa ob (cm - 0.01) (cm + 0.01) zs zh matG "HUS_Glas"
                    segBox (nm + "_Ramme") axis oa (oa + ft) (cm - fd) (cm + fd) zs zh matF "HUS_Rammer"
                    segBox (nm + "_Ramme") axis (ob - ft) ob (cm - fd) (cm + fd) zs zh matF "HUS_Rammer"
                    segBox (nm + "_Ramme") axis oa ob (cm - fd) (cm + fd) zs (zs + ft) matF "HUS_Rammer"
                    segBox (nm + "_Ramme") axis oa ob (cm - fd) (cm + fd) (zh - ft) zh matF "HUS_Rammer"
                    local n = ceil ((ob - oa) / 1.4)
                    for i = 1 to (n - 1) do
                    (
                        local m = oa + (ob - oa) * i / n
                        segBox (nm + "_Post") axis (m - ft / 2) (m + ft / 2) (cm - fd) (cm + fd) zs zh matF "HUS_Rammer"
                    )
                )
                #door:
                (
                    segBox (nm + "_Doer") axis oa ob (cm - 0.03) (cm + 0.03) zs zh matD "HUS_Doere"
                )
                default: ()
            )
            cur = ob
        )
        if cur < a1 do segBox nm axis cur a1 c0 c1 z0 z1 matW lay
    )

    -- Indervaeg 12 cm centreret om c, doere som huller med overligger i 2.1 m
    fn iWall nm axis c a0 a1 z0 z1 doors mat lay =
    (
        local ops = for d in doors collect #(d[1], d[2], 0.0, 2.1, #open)
        mkWall nm axis a0 a1 (c - 0.06) (c + 0.06) z0 z1 ops mat undefined undefined undefined lay
    )

    -- Glsvaern 1.0 m med haandliste
    fn railing nm axis a0 a1 c z0 matG matS =
    (
        segBox (nm + "_Glas") axis a0 a1 (c - 0.01) (c + 0.01) z0 (z0 + 1.0) matG "HUS_Vaern"
        segBox (nm + "_Haandliste") axis a0 a1 (c - 0.025) (c + 0.025) (z0 + 1.0) (z0 + 1.05) matS "HUS_Vaern"
    )

    ---------------------------------------------------------------- materialer
    local mPuds   = PhysicalMaterial name:"HUS_Puds_Hvid"    base_color:(color 238 236 230) roughness:0.75
    local mInd    = PhysicalMaterial name:"HUS_Indervaeg"    base_color:(color 245 245 242) roughness:0.85
    local mBeton  = PhysicalMaterial name:"HUS_Beton"        base_color:(color 170 170 165) roughness:0.8
    local mGlas   = PhysicalMaterial name:"HUS_Glas"         base_color:(color 200 215 220) roughness:0.0 \
                                     transparency:0.95 trans_color:(color 235 245 245) thin_walled:true
    local mRamme  = PhysicalMaterial name:"HUS_Ramme_Antracit" base_color:(color 45 47 50) roughness:0.4
    local mStaal  = PhysicalMaterial name:"HUS_Staal_Antracit" base_color:(color 40 40 42) roughness:0.35 metalness:1.0
    local mTrae   = PhysicalMaterial name:"HUS_Trae_Eg"      base_color:(color 176 140 98) roughness:0.6
    local mDaek   = PhysicalMaterial name:"HUS_Terrassedaek" base_color:(color 140 105 75) roughness:0.7
    local mDoer   = PhysicalMaterial name:"HUS_Doer"         base_color:(color 60 55 50) roughness:0.5
    local mBekl   = PhysicalMaterial name:"HUS_Beklaedning_Sort" base_color:(color 35 33 30) roughness:0.8
    local mTag    = PhysicalMaterial name:"HUS_Tag"          base_color:(color 240 240 238) roughness:0.7
    local mJord   = PhysicalMaterial name:"HUS_Terraen"      base_color:(color 95 120 70) roughness:0.95
    local mFlise  = PhysicalMaterial name:"HUS_Fliser"       base_color:(color 150 148 140) roughness:0.85
    local mStof   = PhysicalMaterial name:"HUS_Stof"         base_color:(color 120 125 130) roughness:0.9

    ---------------------------------------------------------------- hovedmaal
    local L    = 17.0     -- stueetagens laengde (x)
    local D    = 7.6      -- husets dybde (y)
    local LK   = 9.0      -- kaelderens laengde (x)
    local T    = 0.35     -- ydervaeg
    local H    = 2.6      -- loftshoejde stue
    local zK   = (-2.95)    -- kaeldergulv
    local TER  = 3.0      -- terrassedybde mod vest
    local BAL  = 9.0      -- altan mod syd gaar til y = 9.0

    -- ============================================================== STUEETAGE
    ---------------------------------------------------------------- daek (med trappehul)
    -- trappehul: x 4.1-7.6, y 3.75-4.75
    mkBox "Daek_Stue" 0.0 0.0 (-0.35) 4.1 D 0.0 mBeton "HUS_Daek"
    mkBox "Daek_Stue" 7.6 0.0 (-0.35) L   D 0.0 mBeton "HUS_Daek"
    mkBox "Daek_Stue" 4.1 0.0 (-0.35) 7.6 3.75 0.0 mBeton "HUS_Daek"
    mkBox "Daek_Stue" 4.1 4.75 (-0.35) 7.6 D 0.0 mBeton "HUS_Daek"

    ---------------------------------------------------------------- ydervaegge
    -- Nord (planens top)
    local ops_Ydervaeg_N = #(#(1.2, 3.8, 0.0, 2.6, #glass),   -- alrum
          #(4.6, 7.0, 1.0, 2.3, #glass),   -- koekken over bordplade
          #(8.2, 9.8, 0.9, 2.3, #glass),   -- vaerelse 8.3
          #(11.2, 12.8, 0.9, 2.3, #glass), -- vaerelse 12.0
          #(14.4, 16.0, 0.9, 2.3, #glass))
    mkWall "Ydervaeg_N" #x 0.0 L 0.0 T 0.0 H ops_Ydervaeg_N mPuds mGlas mRamme mDoer "HUS_Ydervaegge"
    -- Syd
    local ops_Ydervaeg_S = #(#(0.5, 2.0, 0.0, 2.6, #glass),   -- doer til altan
          #(3.0, 5.6, 0.0, 2.6, #glass),   -- alrum
          #(7.8, 8.8, 1.6, 2.3, #glass),   -- wc/bad (hoejt vindue)
          #(10.0, 11.8, 0.9, 2.3, #glass), -- aabent kontor
          #(13.4, 15.2, 0.9, 2.3, #glass))
    mkWall "Ydervaeg_S" #x 0.0 L (D - T) D 0.0 H ops_Ydervaeg_S mPuds mGlas mRamme mDoer "HUS_Ydervaegge"
    -- Vest (mod overdaekket terrasse)
    local ops_Ydervaeg_V = #(#(0.6, 3.4, 0.0, 2.6, #glass),
          #(4.2, 7.0, 0.0, 2.6, #glass))
    mkWall "Ydervaeg_V" #y T (D - T) 0.0 T 0.0 H ops_Ydervaeg_V mPuds mGlas mRamme mDoer "HUS_Ydervaegge"
    -- Oest (mod carport)
    local ops_Ydervaeg_O = #(#(1.0, 2.6, 0.9, 2.3, #glass),   -- vaerelse 12.0
          #(3.9, 4.9, 0.0, 2.2, #door),    -- hoveddoer til entre
          #(5.8, 6.8, 0.9, 2.3, #glass))
    mkWall "Ydervaeg_O" #y T (D - T) (L - T) L 0.0 H ops_Ydervaeg_O mPuds mGlas mRamme mDoer "HUS_Ydervaegge"

    ---------------------------------------------------------------- indervaegge stue
    local lw = "HUS_Indervaegge"
    iWall "Indervaeg" #y 7.5  T 2.96 0.0 H #() mInd lw                         -- koekken | vaerelse 8.3
    iWall "Indervaeg" #x 2.9  7.44 10.46 0.0 H #(#(7.65, 8.45)) mInd lw        -- vaerelse 8.3 | gang/vrkt
    iWall "Indervaeg" #y 8.4  2.96 3.54 0.0 H #() mInd lw                      -- vrkt vest
    iWall "Indervaeg" #x 3.6  8.34 (L - T) 0.0 H \
          #(#(9.0, 9.8), #(10.9, 11.8), #(14.1, 15.0)) mInd lw                 -- gang/entre nordside
    iWall "Indervaeg" #y 10.4 T 3.54 0.0 H #() mInd lw                         -- vaerelse | vaerelse
    iWall "Indervaeg" #y 13.6 T 3.54 0.0 H #() mInd lw                         -- vaerelse | vaerelse
    iWall "Indervaeg" #y 7.4  4.86 (D - T) 0.0 H #() mInd lw                   -- alrum | wc/bad
    iWall "Indervaeg" #x 4.8  7.34 9.66 0.0 H #(#(8.0, 8.8)) mInd lw           -- wc/bad nordside
    iWall "Indervaeg" #y 9.6  4.86 (D - T) 0.0 H #() mInd lw                   -- wc/bad | kontor
    iWall "Indervaeg" #x 5.1  12.34 (L - T) 0.0 H #(#(13.0, 13.9)) mInd lw     -- entre | bryggers
    iWall "Indervaeg" #y 12.4 5.16 (D - T) 0.0 H #() mInd lw                   -- kontor | bryggers

    ---------------------------------------------------------------- tag
    mkBox "Tag" (-TER - 0.3) (-0.4) H (L + 0.3) (D + 0.4) (H + 0.4) mTag "HUS_Tag"

    ---------------------------------------------------------------- overdaekket terrasse + altan (stueplan)
    mkBox "Terrasse_Oevre" (-TER) 0.0 (-0.35) 0.0 D 0.0 mDaek "HUS_Terrasser"
    mkBox "Altan_Syd" (-TER) D (-0.3) LK BAL 0.0 mDaek "HUS_Terrasser"
    -- soejler under taget
    for y in #(0.0, D - 0.2) do mkBox "Soejle" (-TER) y 0.0 (-TER + 0.2) (y + 0.2) H mStaal "HUS_Soejler"
    -- vaern
    railing "Vaern_N" #x (-TER + 0.2) 0.0 0.05 0.0 mGlas mStaal
    railing "Vaern_V" #y 0.2 (BAL - 0.05) (-TER + 0.05) 0.0 mGlas mStaal
    railing "Vaern_S" #x (-TER) LK (BAL - 0.05) 0.0 mGlas mStaal
    railing "Vaern_O" #y D BAL (LK - 0.05) 0.0 mGlas mStaal

    -- ============================================================== KAELDER
    local zKt = (-0.35)     -- underside af daek over kaelder
    mkBox "Daek_Kaelder" 0.0 0.0 (zK - 0.35) LK D zK mBeton "HUS_Daek"

    local ops_Kaeldervaeg_N = #(#(1.0, 1.8, 1.6, 2.3, #glass),   -- wc/bad
          #(3.4, 4.9, 0.9, 2.3, #glass))
    mkWall "Kaeldervaeg_N" #x 0.0 LK 0.0 T zK zKt ops_Kaeldervaeg_N mPuds mGlas mRamme mDoer "HUS_Ydervaegge"
    local ops_Kaeldervaeg_S = #(#(0.6, 2.6, 0.0, 2.6, #glass),
          #(3.2, 6.2, 0.0, 2.6, #glass))
    mkWall "Kaeldervaeg_S" #x 0.0 LK (D - T) D zK zKt ops_Kaeldervaeg_S mPuds mGlas mRamme mDoer "HUS_Ydervaegge"
    local ops_Kaeldervaeg_V = #(#(1.0, 2.2, 1.6, 2.3, #glass),   -- wc/bad
          #(3.9, 7.0, 0.0, 2.6, #glass))
    mkWall "Kaeldervaeg_V" #y T (D - T) 0.0 T zK zKt ops_Kaeldervaeg_V mPuds mGlas mRamme mDoer "HUS_Ydervaegge"
    -- oestvaeg er stoettevaeg mod terraenet
    mkWall "Kaeldervaeg_O" #y T (D - T) (LK - T) LK zK zKt #() mBeton undefined undefined undefined "HUS_Ydervaegge"

    -- indervaegge kaelder
    iWall "Indervaeg_K" #x 3.5 T (LK - T) zK zKt \
          #(#(1.6, 2.4), #(2.9, 3.7), #(7.8, 8.6)) mInd lw   -- wc, sovevaerelse, teknik
    iWall "Indervaeg_K" #y 2.7 T 3.44 zK zKt #() mInd lw      -- wc/bad | sovevaerelse
    iWall "Indervaeg_K" #y 5.6 T 3.44 zK zKt #(#(1.0, 1.8)) mInd lw  -- sovevaerelse | walk-in
    iWall "Indervaeg_K" #y 7.3 T 3.44 zK zKt #() mInd lw      -- walk-in | teknik
    iWall "Indervaeg_K" #x 5.6 7.54 (LK - T) zK zKt #(#(7.9, 8.6)) mInd lw  -- depot
    iWall "Indervaeg_K" #y 7.6 5.54 (D - T) zK zKt #() mInd lw              -- depot vest

    ---------------------------------------------------------------- trappe (svaevende trin)
    local nSteps = 15
    local rise = (0.0 - zK) / nSteps
    for i = 1 to (nSteps - 1) do
    (
        local x0 = 4.1 + (i - 1) * 0.25
        mkBox "Trappetrin" x0 3.8 (zK + i * rise - 0.05) (x0 + 0.27) 4.7 (zK + i * rise) mTrae "HUS_Trappe"
    )
    railing "Trappevaern" #x 4.1 7.5 3.78 0.0 mGlas mStaal
    railing "Trappevaern" #x 4.1 7.34 4.72 0.0 mGlas mStaal
    railing "Trappevaern" #y 3.75 4.75 4.13 0.0 mGlas mStaal

    ---------------------------------------------------------------- nedre overdaekket terrasse
    mkBox "Terrasse_Nedre" (-TER - 0.5) (-0.5) (zK - 0.05) 0.0 (BAL + 0.5) zK mFlise "HUS_Terrasser"
    mkBox "Terrasse_Nedre" 0.0 D (zK - 0.05) LK (BAL + 0.5) zK mFlise "HUS_Terrasser"
    for p in #([-TER, 0.0], [-TER, 3.7], [-TER, D - 0.2], [-TER, BAL - 0.2], [3.0, BAL - 0.2], [LK - 0.2, BAL - 0.2]) do
        mkBox "Soejle_K" p.x p.y zK (p.x + 0.2) (p.y + 0.2) (-0.35) mStaal "HUS_Soejler"

    -- ============================================================== CARPORT + REDSKABSRUM
    local cx0 = L, cx1 = L + 6.4, cy0 = 3.7, cy1 = 12.6, zC = 2.5
    mkBox "Carport_Gulv" cx0 cy0 (-0.35) cx1 cy1 (-0.33) mFlise "HUS_Carport"
    mkBox "Carport_Tag" cx0 cy0 zC cx1 cy1 (zC + 0.3) mTag "HUS_Carport"
    for p in #([cx1 - 0.15, cy0], [cx1 - 0.15, 8.2], [cx0, 8.2]) do
        mkBox "Carport_Soejle" p.x p.y (-0.35) (p.x + 0.15) (p.y + 0.15) zC mStaal "HUS_Carport"
    -- redskabsrum 10.1 m2 i carportens sydende
    local ry0 = 10.9
    mkWall "Redskab_N" #x cx0 cx1 ry0 (ry0 + 0.15) (-0.35) zC #(#(19.2, 20.2, 0.0, 2.1, #door)) \
        mBekl mGlas mRamme mDoer "HUS_Carport"
    mkBox "Redskab_S" cx0 (cy1 - 0.15) (-0.35) cx1 cy1 zC mBekl "HUS_Carport"
    mkBox "Redskab_V" cx0 (ry0 + 0.15) (-0.35) (cx0 + 0.15) (cy1 - 0.15) zC mBekl "HUS_Carport"
    mkBox "Redskab_O" (cx1 - 0.15) (ry0 + 0.15) (-0.35) cx1 (cy1 - 0.15) zC mBekl "HUS_Carport"

    -- ============================================================== INVENTAR (simpelt)
    local li = "HUS_Inventar"
    mkBox "Koekken"   4.6 T 0.0 7.3 (T + 0.6) 0.9 mInd li
    mkBox "Ko_Oe"     4.8 1.8 0.0 6.8 2.7 0.9 mInd li
    mkBox "Spisebord" 1.6 1.4 0.72 3.6 2.4 0.75 mTrae li
    mkBox "Spisebord_Fod" 2.4 1.8 0.0 2.8 2.0 0.72 mStaal li
    mkBox "Sofa"      0.8 6.3 0.0 3.4 7.15 0.75 mStof li
    mkBox "Seng"      8.7 0.6 0.0 9.6 2.6 0.5 mStof li
    mkBox "Seng"      12.2 0.6 0.0 13.4 2.6 0.5 mStof li
    mkBox "Seng"      15.3 1.0 0.0 16.5 3.0 0.5 mStof li
    mkBox "Seng_Dobbelt" 3.25 0.5 zK 5.05 2.5 (zK + 0.5) mStof li
    mkBox "Sofa_K"    1.0 6.35 zK 3.6 7.15 (zK + 0.75) mStof li

    -- ============================================================== TERRAEN
    -- oevre plateau oest for kaelderen (stueniveau), nedre plateau vest
    mkBox "Terraen_Oevre" LK (-12.0) (-3.3) 35.0 22.0 (-0.35) mJord "HUS_Terraen"
    mkBox "Terraen_Nedre" (-25.0) (-12.0) (-3.5) LK 22.0 (zK - 0.05) mJord "HUS_Terraen"

    -- ============================================================== KAMERAER
    local tgt1 = Targetobject name:"HUS_Kamera_SV_Maal" pos:[5.0, (-4.0), (-0.8)]
    local cam1 = Targetcamera name:"HUS_Kamera_SV" fov:55 pos:[-14.0, (-26.0), 1.0] target:tgt1
    local tgt2 = Targetobject name:"HUS_Kamera_Indgang_Maal" pos:[17.0, (-5.0), 1.0]
    local cam2 = Targetcamera name:"HUS_Kamera_Indgang" fov:60 pos:[32.0, (-2.0), 1.6] target:tgt2
    for o in #(tgt1, cam1, tgt2, cam2) do (getLayer "HUS_Kameraer").addNode o

    ---------------------------------------------------------------- afslut
    try (viewport.setType #view_persp_user; max zoomext sel all) catch ()
    completeRedraw()
    format "HUS: % objekter oprettet.\n" (for o in objects where matchPattern o.name pattern:"HUS_*" collect o).count
)
