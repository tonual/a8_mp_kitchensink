{$DEFINE BASICOFF}

Uses crt, md1;

Const 

  ADDR_PLAYER   = $3000;
  // 2.5 KB
  ADDR_MD1      = $4000;
  // 2 KB
  DL_ADDR       = $4800;
  // 500 B
  ADDR_SAMPLES  = $5000;
  // 12 KB 
  //charsets
  ORNA_ADDR = $8000;
  //500 B per charset (32 chars)
  ORNA_ADDR2 = $8200;
  //
  MPT_PATTPOS_ADDROFF = $92A;
  MPT_SONGPOS_ADDROFF = $921;
  MPT_INSTR_HIT_ADDOFFS = $08F8;
  MPT_TEMPO_ADDOFFS = $01C9;
  //PMG
  PMG_BASE = $B000;
  PMG_PLR_HEIGHT = 120;

Var 
  msx: TMD1;
  ch: char;
  scrBase: word;
  //md1, song telemetry
  ptr : pointer;
  song_pos_addr : word;
  //
  qtick, vbldx,vbldx2 : byte;
  lst_t1_hit,lst_t2_hit,lst_t3_hit,lst_t4_hit, lst_pat_pos: byte;
  i,j,k: byte;
  col: byte;
  //dancer frame cnt
  dncr_frm : byte;
  dncr_frm2 : byte;
  dncr_frm3 : byte;
  dncr_frm4 : byte;
  dncr_frm5 : byte;
  dncr_frm6 : byte;
  dncr_frm7 : byte;
  dncr_pos: word;
  oldVBL : pointer;
  //
  DL: array[0..30] Of byte absolute DL_ADDR;

  t1,t2: byte;
  dncr_anim : array[0..13,0..7] Of 
              byte = 
                     (
                      ( 0,  1,  8,  9, 16, 17, 24, 25),
                     ( 2,  3, 10, 11, 18, 19, 26, 27),
                     ( 4,  5, 12, 13, 20, 21, 28, 29),
                     ( 6,  7, 14, 15, 22, 23, 30, 31),
                     ( 32, 33, 40, 41, 48, 49, 56, 57),
                     ( 34, 35, 42, 43, 50, 51, 58, 59),
                     ( 36, 37, 44, 45, 52, 53, 60, 61),
                     ( 38, 39, 46, 47, 54, 55, 62, 63),
                     ( 36, 37, 44, 45, 52, 53, 60, 61),
                     ( 34, 35, 42, 43, 50, 51, 58, 59),
                     ( 32, 33, 40, 41, 48, 49, 56, 57),
                     ( 6,  7, 14, 15, 22, 23, 30, 31),
                     ( 4,  5, 12, 13, 20, 21, 28, 29),
                     ( 2,  3, 10, 11, 18, 19, 26, 27)
                     );

{$r intro1.rc}

Procedure BuildDL;

Var i: byte;
Begin
  DL[0] := $70;
  // 8 blank lines (top overscan part 1)
  DL[1] := $70;
  // 8 blank lines (part 2)
  DL[2] := $70;
  // 8 blank lines (part 3) → total 24 blank scan lines
  DL[3] := $47 Or $40;
  // $47 = ANTIC 7 + LMS (first visible line)
  DL[4] := Lo(scrBase);
  // Screen RAM low
  DL[5] := Hi(scrBase);
  // Screen RAM high
  For i := 6 To 28 Do
  // 23 more ANTIC 7 lines (total 24 visible)
  DL[i] := $07;
  // plain ANTIC 7 (no LMS)
  DL[29] := $41;
  // JVB (jump on vertical blank)
  DL[30] := Lo(DL_ADDR);
  // point back to start of this DL
  DL[31] := Hi(DL_ADDR);
End;


Procedure Efx;


Var 
  pattPos, t1h,t2h,t3h,t4h, doofs : byte;

Begin

  //rhythmic viz
  //when track 1-4 encounters note to play
  t1h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER);
  t2h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER + 1);
  t3h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER + 2);
  t4h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER + 3);
  pattPos := peek(ADDR_PLAYER + MPT_PATTPOS_ADDROFF);

  If pattPos <> lst_pat_pos Then //new patt pos entered
    Begin
      lst_pat_pos := pattPos;
     Poke(704, Peek(704) - 2);
      Poke(705, Peek(705) - 2);
      Poke(706, Peek(706) - 2);
      Poke(707, Peek(707)- 2);
    End;

  Inc(vbldx2);
  If vbldx2 = qtick  shl 2 Then //tempo tick encountered
    Begin
      //PERFORM TEST
      // Inc(j);
      // Poke(scrBase + j , dncr_anim[9][7]+16 );

      //DANCER1         
      dncr_pos := scrBase + 32 + doofs;
      dncr_frm := dncr_frm Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm][i*2] +32);
          Poke(dncr_pos + 1, dncr_anim[dncr_frm][i*2+1] +32);
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm);
      vbldx2 := 0;
    End;

  //aniamte PMG bars color here
  Inc(vbldx);
  If vbldx = qtick  Then //tempo tick slower
    Begin
      
            Poke(704, $14);
      Poke(705, $18);
      Poke(706, $dc);
      Poke(707, $b6);
      vbldx := 0;
    End;

  //note hits
  If lst_t1_hit <> t1h Then
    Begin
      //eqv := (peek(53760) * peek(53761) +255) Div 512;     //PROBING POKEY IS //SLOWWW!
      //Poke(53248, 160); //player positions, //move to hotizontal pos
      

Poke(53248, (20+peek($d20a) and 100));
      

      //c1:=$14;
      lst_t1_hit := t1h;
    End;
  //2
  If lst_t2_hit <> t2h  Then
    Begin
      //eqv := (peek(53762) * peek(53763)+255) Div 512;          
      //Poke(53249, 168);
      

      Poke(53249, (28+peek($d20a) and 100));
      

      //move to hotizontal pos          
      lst_t2_hit := t2h;
    End;
  //3
  If lst_t3_hit <> t3h Then
    Begin
      //eqv := (peek(53764) * peek(53765)+255) Div 512;          
      //Poke(53250, 176);          
      

      Poke(53250, (36+peek($d20a) and 100));
      
      lst_t3_hit := t3h;
    End;
  //4
  If lst_t4_hit <> t4h  Then
    Begin
      //eqv := (peek(53766) * peek(53767)+255) Div 512;          
      //Poke(53251, 184);        
      

      Poke(53251, (44+peek($d20a) and 100));

      lst_t4_hit := t4h;
    End;

  //doofs :=Peek(song_pos_addr);



  //song progress viz  
  //   songPos := Peek(song_pos_addr);
  //   If lastSongPos <> songPos Then
  //     Begin
  //       lastSongPos := songPos;
  //       //Inc(doofs);
  //       inc(progress);
  //       progress := progress Mod 2;
  //       If progress = 0 Then Poke($2F4, Hi(ORNA_ADDR2));
  //       If progress = 1 Then Poke($2F4, Hi(ORNA_ADDR));
  //       //progress := (27 * songPos) div (songLength shl 1);
  //       //for i := 0 to progress do Poke(scrBase + 880 + i, 12);      
  //     End;
End;


Procedure Vbl;
interrupt;
Begin
  //t1 := PEEK($14);
  msx.play;
  Efx;

  //t2 := PEEK($14);
  //If t1<>t2 Then Halt;
  //Poke($02C8, 0);    // black
  asm
  {     
    jmp xitvbv 
  };
End;

Begin
  ClrScr;
  CursorOff;

  GetIntVec(iVBL, OldVBL);
  //COLORS
  Poke($02C8, 0);
  Poke($02C6, $28);
  Poke($02C7, $C6);
  //SCREEN MEMORY ADRESS
  scrBase := DPeek(88);
  //CUSTOM CHARSET ADDRESS
  Poke($2F4, Hi(ORNA_ADDR));
  BuildDL;
  //DL
  Poke($230, Lo(DL_ADDR));
  Poke($231, Hi(DL_ADDR));
  Poke($22F, $22);
  // DMACTL: enable DL + playfield?
  qtick := (peek(MPT_TEMPO_ADDOFFS + ADDR_MD1) + 1) ;
  song_pos_addr := ADDR_PLAYER + MPT_SONGPOS_ADDROFF;
  dncr_frm := 0;
  dncr_frm2 := 2;
  dncr_frm3 := 6;
  dncr_frm4 := 9;
  dncr_frm5 := 12;
  dncr_frm6 := 1;
  dncr_frm7 := 4;


  While true Do
    Begin

      // PMG setup
      Poke(54279, PMG_BASE shr 8);
      //over chracters      
      Poke(53275, 0);
      // DMACTL: 3 for double-line + players + missiles ... $0C for quad lines
      Poke(559,   46);
      // GRACTL: enable players + missiles      
      Poke(53277, 3);
      FillChar(pointer(53256), 4, 0);
      //?

      //draw PMG PLAYERS once
      ptr := Pointer(PMG_BASE + $200);
      FillChar(ptr^, PMG_PLR_HEIGHT, $ff);
      ptr := Pointer(PMG_BASE + $280);
      FillChar(ptr^, PMG_PLR_HEIGHT, $ff);
      ptr := Pointer(PMG_BASE + $300);
      FillChar(ptr^, PMG_PLR_HEIGHT, $ff);
      ptr := Pointer(PMG_BASE + $380);
      FillChar(ptr^, PMG_PLR_HEIGHT, $ff);
      //end PMG setup

      SetIntVec(iVBL, @Vbl);
      msx.player  := pointer(ADDR_PLAYER);
      msx.modul   := pointer(ADDR_MD1);
      msx.sample  := pointer(ADDR_SAMPLES);
      msx.init;

      msx.digi(true);
      msx.stop();

      //pmg off
      Poke(53248, 0);
      Poke(53249, 00);
      Poke(53250, 00);
      Poke(53251, 0);
      //restore vbl to calm down the hardware
      SetIntVec(iVBL,oldVBL);
      //cleanup
      vbldx := 0;
      vbldx2 := 0;

      ptr := Pointer(ADDR_MD1);
      FillChar(Ptr^, 4096, 0);
    End;
End.
