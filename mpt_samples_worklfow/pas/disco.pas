{$DEFINE BASICOFF}

Uses crt, sysutils, md1;

Const 
  DL_ADDR = $5A00;
  TITLE = 'POKEY DIGITALS VOL 1';
  COLBG   = $2C6;
  COLPF1  = $2C5;
  COLPF2  = $2C8;
  //MPT memory 
  ADDR_PLAYER   = $5b6e;
  ADDR_MD1      = $6499;
  ADDR_SAMPLES  = $7499;
  //files
  DRIVE   = 'D:';
  D15_EXT = '.D15';
  D8_EXT  = '.D8 ';
  //browser
  COL_ITEMS_CNT = 21;
  COL_WIDTH   = 8;
  COL_MARGIN  = 3;
  ROW_MARGIN  = 4;
  //charset
  ORNA_ADDR = $B400;
  ORNA_ADDR2 = $B600;
  //custom characters adress pointer, 12KB after samples addr, (must be * 1024) 
  //ORNA_ADDR = $B600;
  ORNAMENT_COL = 28;
  ORNAMENT_ROW = 16;
  //player
  MPT_SONGPOS_ADDROFF = $921;
  MPT_INSTR_HIT_ADDOFFS = $08F8;
  //+1 for each track (up to 8fb)
  MPT_TEMPO_ADDOFFS = $01C9;
  //PMG
  PMG_BASE = $B800;
  PMG_PLR_HEIGHT = 120;
  //dancer
  dncr_anim : array[0..13,0..7] Of byte = 
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


Var 
  //player
  msx: TMD1;
  is15Khz : boolean;
  song_name: string;
  //browser
  song_selected: boolean;
  cursor_col : byte;
  cursor_row : byte;
  col_cnt_on_page: byte;
  scrBase: word;
  //md1, song telemetry
  ptr : pointer;
  song_pos_addr : word;
  //
  qtick, vbldx,vbldx2 : byte;
  lst_t1_hit,lst_t2_hit,lst_t3_hit,lst_t4_hit, lst_pat_pos: byte;
  i: byte;
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
  songPos, songLength, lastSongPos,  progress : byte;
  DL: array[0..30] Of byte absolute DL_ADDR;

  t1,t2: byte;

{$r mptb.rc}

Procedure BuildDL;

Var i: byte;
Begin
  DL[0] := $70;
  // 8 blank lines (top overscan part 1)

  DL[1] := $70;
  // 8 blank lines (part 2)
  DL[2] := $70;
  // 8 blank lines (part 3) → total 24 blank scan lines (standard)

  DL[3] := $46 Or $40;
  // $46 = ANTIC 6 + LMS (first visible line)
  DL[4] := Lo(scrBase);
  // Screen RAM low
  DL[5] := Hi(scrBase);
  // Screen RAM high

  For i := 6 To 28 Do
    // 23 more mode 6 lines (total 24 visible)
    DL[i] := $06;
  // plain ANTIC 6 (no LMS!)

  DL[29] := $41;
  // JVB (jump on vertical blank)
  DL[30] := Lo(DL_ADDR);
  // point back to start of this DL
  DL[31] := Hi(DL_ADDR);
End;



Function GetTrackLength(ModuleAddr: Word): byte;

Var 
  T1_offset, T2_offset: Word;
Begin
  T1_offset := PByte(Pointer(ModuleAddr + $01C0))^ Or (PByte(Pointer(ModuleAddr + $01C4))^ shl 8);
  T2_offset := PByte(Pointer(ModuleAddr + $01C1))^ Or (PByte(Pointer(ModuleAddr + $01C5))^ shl 8);
  Result := (T2_offset - T1_offset) shr 1;
End;


Function ReadStrAt(x, y: byte): string;

Var 
  s: string[40];
  b: byte;
  p: byte;
  adr: word;
Begin
  adr := DPeek(88) + (y - 1) * 40 + (x - 1);

  s := '';
  p := 0;

  Repeat
    b := Peek(adr + p);

    If b < 128 Then
      Inc(b, 32)
    Else
      Dec(b, 128);

    If b = 32 Then break;

    Inc(s[0]);
    s[Ord(s[0])] := Chr(b);

    Inc(p);
  Until (x - 1 + p) = 40;

  ReadStrAt := s;
End;


Procedure WriteInverse(s: String);

Var 
  i: byte;
Begin
  For i := 1 To length(s) Do
    write(chr(byte(s[i]) + 128));
  write(chr(155));
End;


Function GetFileBase(fname: TString): string;

Var 
  i: byte;
Begin
  For i := Length(fname) Downto 1 Do
    If fname[i] = '.' Then
      Begin
        Result := Copy(fname, 1, i - 1);
        Exit;
      End;
  Result := fname;
End;


Procedure LoadAndRelocateMD1(Const filename: String; new_address: word);

Const 
  DOS_HDR = 6;

Var 
  f        : file;
  read_cnt : word;
  old_addr : word;
  data_len : word;
  ofs      : word;
  i        : byte;
  tmp      : word;
  ptn      : pointer;
  buffer   : array[0..4096] Of byte;


Begin

  Assign(f, filename);
  Reset(f, 1);
  read_cnt := 0;
  BlockRead(f, buffer, SizeOf(buffer), read_cnt);
  Close(f);

  //sanity checks
  If (read_cnt < DOS_HDR + 2) Or
     (buffer[0] <> $FF) Or (buffer[1] <> $FF) Then
    Begin
      Halt;
    End;

  //Extract old address and compute real module length
  old_addr := buffer[2] + buffer[3] shl 8;
  data_len := (buffer[4] + buffer[5] shl 8) - old_addr + 1;
  ofs      := DOS_HDR;

  If read_cnt <> DOS_HDR + data_len Then
    Begin
      Halt;
    End;
  //Patch the DOS header for the new address
  buffer[2] := Lo(new_address);
  buffer[3] := Hi(new_address);
  buffer[4] := Lo(new_address + data_len - 1);
  buffer[5] := Hi(new_address + data_len - 1);

  For i := 0 To 31 Do
    //instruments
    Begin
      tmp := buffer[ofs + i*2] + buffer[ofs + i*2 + 1] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + i*2]     := Lo(tmp);
          buffer[ofs + i*2 + 1] := Hi(tmp);
        End;
    End;

  For i := 0 To 63 Do
    //patterns
    Begin
      tmp := buffer[ofs + $40 + i*2] + buffer[ofs + $40 + i*2 + 1] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + $40 + i*2]     := Lo(tmp);
          buffer[ofs + $40 + i*2 + 1] := Hi(tmp);
        End;
    End;

  For i := 0 To 3 Do
    //tracks
    Begin
      tmp := buffer[ofs + $1C0 + i] + buffer[ofs + $1C4 + i] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + $1C0 + i] := Lo(tmp);
          buffer[ofs + $1C4 + i] := Hi(tmp);
        End;
    End;

  //Copy the relocated module to its final location
  ptn := Pointer(new_address);
  Move(buffer[ofs], ptn, data_len);
End;


Procedure LoadFileToAddr(Const filename: String; addr: word);

Var 
  f: file;
  p: pointer;
  buf: array [0..255] Of byte;
  bytesRead: word;

Begin
  Assign(f, filename);
  Reset(f, 1);

  Repeat
    p := pointer(addr);
    BlockRead(f, buf, SizeOf(buf), bytesRead);
    Move(buf, p^, bytesRead);
    addr := addr + bytesRead;
    //viz/random dots
    Poke(scrBase + 880 + (peek($d20a) and 14) + 10,  (peek($d20a) and 1) + 12);

  Until bytesRead = 0;
  Close(f);
End;


Procedure ListFiles;

Var 
  Info : TSearchRec;
  row,col : byte;
  song_name : string;

Begin
  col_cnt_on_page := 0;
  row := ROW_MARGIN;
  col := COL_MARGIN;

  If FindFirst(Concat(DRIVE,'*.MD1'), faAnyFile, Info) = 0 Then   // '*.MD1  ?

    Begin
      Repeat
        song_name := GetFileBase(Info.Name);
        GotoXY(col,row);
        write(song_name);
        Inc(row);

        If row > COL_ITEMS_CNT Then
          Begin
            row := ROW_MARGIN;
            col := col + COL_MARGIN + COL_WIDTH;
            Inc(col_cnt_on_page);
          End;

      Until FindNext(Info) <> 0;
      FindClose(Info);

    End;
End;


Procedure LoadSong;

Var 
  sample_file : string;
  song_file : string;
  fullname : string;

Begin
  Poke(65,0);
  //silence i/o noise  
  GotoXY(0,23);
  WriteInverse('LOADING..');
  //print loading
  is15Khz := true;
  //try .d15 ext first, then .d8
  song_file   := Concat(song_name, '.MD1');
  sample_file := Concat(song_name, D15_EXT);

  If (FileExists(Concat(DRIVE, sample_file)) <> true) Then //if not,then it is .d8 ext
    Begin
      sample_file := Concat(song_name, D8_EXT);
      is15Khz := false;
    End;
  fullname := Concat(DRIVE, song_file);
  LoadAndRelocateMD1(fullname, ADDR_MD1);

  //clear samples ram  
  ptr := Pointer(ADDR_SAMPLES);
  FillChar(Ptr^, 12288, 0);

  fullname := Concat(DRIVE, sample_file);
  LoadFileToAddr(fullname, ADDR_SAMPLES);
  //LoadFileToAddr(Concat(DRIVE,'ORNA1.FNT'), ORNA_ADDR);
  //songLength := GetTrackLength(ADDR_MD1);

  //figure out quarter tick based on tempo
  qtick := (peek(MPT_TEMPO_ADDOFFS + ADDR_MD1) + 1) ;
  //halftick shr 1, quartertick shr 2
  //clear loading text   
  For i := 0 To 27 Do
    Poke(scrBase + 880 + i, 0);
End;


Procedure Efx;
//player visualization and song progress

Var 
  pattPos, t1h,t2h,t3h,t4h, doofs : byte;

Begin
  //Delay(200);
  //rhythmic viz
  //when track 1-4 encounters note to play
  t1h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER);
  t2h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER + 1);
  t3h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER + 2);
  t4h := peek(MPT_INSTR_HIT_ADDOFFS + ADDR_PLAYER + 3);
  pattPos := peek(ADDR_PLAYER + $092a);


  If pattPos <> lst_pat_pos Then
    Begin
      lst_pat_pos := pattPos;
      Poke(53248, (20+peek($d20a) and 100));
      Poke(53249, (28+peek($d20a) and 100));
      Poke(53250, (36+peek($d20a) and 100));
      Poke(53251, (44+peek($d20a) and 100));
    End;

  Inc(vbldx2);
  If vbldx2 = qtick Then
    Begin

      //DANCER1         
      dncr_pos := scrBase + 32 + doofs;
      dncr_frm := dncr_frm Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm][i*2] +64);
          Poke(dncr_pos + 1, dncr_anim[dncr_frm][i*2+1] +64);
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm);

      //DANCER2         
      dncr_pos := scrBase + 38 + doofs;
      dncr_frm2 := dncr_frm2 Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm2][i*2] );
          Poke(dncr_pos + 1, dncr_anim[dncr_frm2][i*2+1] );
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm2);

      //DANCER3        
      dncr_pos := scrBase + 41 + doofs;
      dncr_frm3 := dncr_frm3 Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm3][i*2] +128);
          Poke(dncr_pos + 1, dncr_anim[dncr_frm3][i*2+1] +128);
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm3);

      //DANCER4        
      dncr_pos := scrBase + 143 + doofs;
      dncr_frm4 := dncr_frm4 Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm4][i*2] +64);
          Poke(dncr_pos + 1, dncr_anim[dncr_frm4][i*2+1] +64);
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm4);

      //DANCER5        
      dncr_pos := scrBase + 148 + doofs;
      dncr_frm5 := dncr_frm5 Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm5][i*2] +0);
          Poke(dncr_pos + 1, dncr_anim[dncr_frm5][i*2+1] +0);
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm5);

       //DANCER6        
      dncr_pos := scrBase + 151 + doofs;
      dncr_frm6 := dncr_frm6 Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm6][i*2] +128);
          Poke(dncr_pos + 1, dncr_anim[dncr_frm6][i*2+1] +128);
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm6);

       //DANCER7        
      dncr_pos := scrBase + 253 + doofs;
      dncr_frm7 := dncr_frm7 Mod 13;
      For i := 0 To 3 Do
        Begin
          Poke(dncr_pos    , dncr_anim[dncr_frm7][i*2] +64);
          Poke(dncr_pos + 1, dncr_anim[dncr_frm7][i*2+1] +64);
          dncr_pos := dncr_pos + 20;
        End;
      Inc(dncr_frm7);


      vbldx2 := 0;
    End;

  //aniamte PMG bars here
  Inc(vbldx);
  If vbldx = qtick shl 2 Then
    Begin
      Poke(704, Peek(704) - 2);
      Poke(705, Peek(705) - 2);
      Poke(706, Peek(706) - 2);
      Poke(707, Peek(707)- 2);
      vbldx := 0;
    End;

  If lst_t1_hit <> t1h Then
    Begin
      //eqv := (peek(53760) * peek(53761) +255) Div 512;     //PROBING POKEY IS //SLOWWW!
      //Poke(53248, 160); //player positions, //move to hotizontal pos
      Poke(704, $14);
      //c1:=$14;
      lst_t1_hit := t1h;
    End;
  //2
  If lst_t2_hit <> t2h  Then
    Begin
      //eqv := (peek(53762) * peek(53763)+255) Div 512;          
      //Poke(53249, 168);
      Poke(705, $18);

      //move to hotizontal pos          
      lst_t2_hit := t2h;
    End;
  //3
  If lst_t3_hit <> t3h Then
    Begin
      //eqv := (peek(53764) * peek(53765)+255) Div 512;          
      //Poke(53250, 176);          
      Poke(706, $dc);
      lst_t3_hit := t3h;
    End;
  //4
  If lst_t4_hit <> t4h  Then
    Begin
      //eqv := (peek(53766) * peek(53767)+255) Div 512;          
      //Poke(53251, 184);        
      Poke(707, $b6);

      lst_t4_hit := t4h;
    End;

  //doofs :=Peek(song_pos_addr);



  //song progress viz  
  songPos := Peek(song_pos_addr);
  If lastSongPos <> songPos Then
    Begin
      lastSongPos := songPos;
      //Inc(doofs);
      inc(progress);
      progress := progress Mod 2;
      If progress = 0 Then Poke($2F4, Hi(ORNA_ADDR2));
      If progress = 1 Then Poke($2F4, Hi(ORNA_ADDR));
      //progress := (27 * songPos) div (songLength shl 1);
      //for i := 0 to progress do Poke(scrBase + 880 + i, 12);      
    End;
End;


Procedure Vbl;
interrupt;
Begin
  t1 := PEEK($14);
  msx.play;
  If song_selected = true Then Efx;
  If keypressed() Then msx.stop;
  t2 := PEEK($14);
  If t1<>t2 Then Halt;
  //Poke($02C8, 0);    // black
  asm
  {     
    jmp xitvbv 
  };
End;

Procedure Browse();

Var 
  ch: char;
  offset: Word;

Begin

  If song_selected Then //restore song name from inverse
    Begin
      GotoXY(cursor_col + 1, cursor_row);
      writeln(song_name);
    End;

  song_selected := false;

  GotoXY(cursor_col + 1, cursor_row);
  song_name := ReadStrAt(cursor_col + 1, cursor_row);
  WriteInverse(song_name);

  ch := ReadKey;
  GotoXY(cursor_col + 1, cursor_row);
  writeln(song_name);

  Case ord(ch) Of 
    45: //up
        Begin
          If cursor_row > ROW_MARGIN Then Dec(cursor_row);
        End;
    61: //down
        Begin
          offset := cursor_row * 40 + cursor_col;
          If Peek(scrBase + offset) <> 0 Then Inc(cursor_row);
        End;
    42: //right
        Begin
          offset := (cursor_row - 1) * 40 + (cursor_col + COL_MARGIN + COL_WIDTH);
          If Peek(scrBase + offset) <> 0 Then
            Begin
              cursor_col := cursor_col + COL_MARGIN + COL_WIDTH;
            End;
        End;
    43: //left
        Begin
          If cursor_col > COL_MARGIN + 1 Then
            Begin
              cursor_col := cursor_col - (COL_MARGIN + COL_WIDTH);
            End;
        End;
    155: //ENTER - sleltect song, make inversed
         Begin
           song_selected := true;
           GotoXY(cursor_col + 1, cursor_row);
           WriteInverse(song_name);
         End;
  End;
  //BLIP
  Sound(0, 255, 10, 3);
  Delay(12);
  Sound(0, 0, 0, 0);
End;


Begin
  ClrScr;
  CursorOff;

  GetIntVec(iVBL, OldVBL);
  //backgorund
  Poke($02C8, 0);
  // black
  Poke($02C6, $28);
  // orange (normal lum)
  Poke($02C7, $C6);
  // light green (half lum)
  //
  scrBase := DPeek(88);
  //Tell ANTIC our font is the "official" one
  Poke($2F4, Hi(ORNA_ADDR));
  //def curren song pos address
  song_pos_addr := ADDR_PLAYER + MPT_SONGPOS_ADDROFF;
  //browser cursor
  cursor_col := COL_MARGIN - 1;
  cursor_row := ROW_MARGIN;
  song_selected := false;

  //dancer pos
  dncr_pos := scrBase + ORNAMENT_ROW * 40 + ORNAMENT_COL;

  //ListFiles();
  song_name := 'TNL4';
  song_selected := true;

  //DL
  BuildDL;

  Poke($230, Lo(DL_ADDR));
  // SDLSTL
  Poke($231, Hi(DL_ADDR));

  Poke($22F, $22);
  // DMACTL: enable DL + playfield

  dncr_frm := 0;
  dncr_frm2 := 2;
  dncr_frm3 := 6;
  dncr_frm4 := 9;
  dncr_frm5 := 12;
  dncr_frm6 := 1;
  dncr_frm7 := 4;

  //browse/load/listen/repeat
  While true Do
    Begin
      //Repeat
      //Browse()
      //Until song_selected = true;
      LoadSong();
      // PMG setup
      Poke(54279, PMG_BASE shr 8);
      Poke(53275, 0);
      //over chracters      
      Poke(559,   46);
      //$22F
      // DMACTL: 3 for double-line + players + missiles ... $0C for quad lines
      Poke(53277, 3);
      // GRACTL: enable players + missiles      
      // normal size
      FillChar(pointer(53256), 4, 0);
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

      msx.digi(is15Khz);
      msx.stop();

      //pmg off
      Poke(53248, 0);
      Poke(53249, 00);
      Poke(53250, 00);
      Poke(53251, 0);

      SetIntVec(iVBL,oldVBL);
      vbldx := 0;
      vbldx2 := 0;
      dncr_frm := 0;

      //clean up MD1 data
      ptr := Pointer(ADDR_MD1);
      FillChar(Ptr^, 4096, 0);
      //bold assumption md1 module <= 4096 bytes
    End;
End.
