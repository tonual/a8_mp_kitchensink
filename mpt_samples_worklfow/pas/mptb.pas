{$DEFINE BASICOFF}

Uses crt, sysutils, md1;

Const 
  TITLE = 'POKEY DIGITALS VOL 1';
  INSTR = 'USE ARROWS & ENTER';
  PLS_WAIT = 'LAODING...';
  //colors
  COLBG   = $2C6;
  COLPF1  = $2C5;
  COLPF2  = $2C8;
  //MPT memory 
  ADDR_PLAYER   = $6b7d;
  ADDR_MD1      = $74a8;
  //bold assumption md1 module <= 4096 bytes
  //ADDR_SAMPLES  = $852B;
  //files
  DRIVE   = 'D:';
  D15_EXT = '.D15';
  D8_EXT  = '.D8 ';
  //browser
  COL_ITEMS_CNT = 20;
  COL_WIDTH   = 8;
  COL_MARGIN  = 2;
  ROW_MARGIN  = 4;
  //charset
  CHARSET_ADDR = $B400;
  ORNA_ADDR = $B600;
  //custom characters adress pointer, 12KB after samples addr, (must be * 1024) 
  //ornament pos
  ORNAMENT_COL = 28;
  ORNAMENT_ROW = 14;
  //player
  SNGPOS_ADDROFF = $921;
  SNG_INSTR_HIT_BASE = $08F8;
  //+1 for each track (up to 8fb)
  //PMG
  PMG_BASE = $B800;
  P_HEIGHT = 127;


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
  songPos: byte;
  lastSongPos : byte;
  songLength : byte;
  progress: byte;
  //PMG
  P0: array [0..P_HEIGHT-1] Of byte absolute PMG_BASE + 512;
  P1: array [0..P_HEIGHT-1] Of byte absolute PMG_BASE + 640;
  P2: array [0..P_HEIGHT-1] Of byte absolute PMG_BASE + 768;
  P3: array [0..P_HEIGHT-1] Of byte absolute PMG_BASE + 896;
  lst_t1_hit,lst_t2_hit,lst_t3_hit,lst_t4_hit, lst_pat_pos: byte;
  i: byte;
  //
  md1module_size : word;


{$r mptb.rc}


Function GetTrackLength(ModuleAddr: Word): byte;

Var 
  T1_offset, T2_offset: Word;
Begin
  T1_offset := PByte(Pointer(ModuleAddr + $01C0))^ Or (PByte(Pointer(ModuleAddr + $01C4))^ shl 8);
  T2_offset := PByte(Pointer(ModuleAddr + $01C1))^ Or (PByte(Pointer(ModuleAddr + $01C5))^ shl 8);
  Result := (T2_offset - T1_offset) shr 1;

End;


Function ReadStrAt(X, Y: Byte): string;

Var 
  ScreenBase : Word;
  Offset     : Word;
  Pos        : Byte;
  Internal   : Byte;
  ResultStr  : string;

Begin
  ResultStr := '';
  ScreenBase := DPeek(88);
  Offset     := (Y-1) * 40 + (X-1);
  Pos := 0;
  While (X-1 + Pos < 40) Do
    Begin
      Internal := Peek(ScreenBase + Offset + Pos);
      If Internal < 128 Then
        Internal := Internal + 32
      Else
        Internal := Internal - 128;
      If Chr(Internal) = ' ' Then
        break;
      ResultStr := Concat(ResultStr, Chr(Internal));
      Inc(Pos);
    End;

  ReadStrAt := ResultStr;
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
  //are there bigger modules? (how to recycle memory from this buffer btw)  

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
  md1module_size := read_cnt;
  //TODO read_cnt redundant
End;


Procedure LoadFileToAddr(Const filename: String; addr: word);

Var 
  f: file;
  p: pointer;
  buf: array [0..255] Of byte;
  bytesRead: word;
  ldr,r: byte;

Begin
  ldr := 10;
  //loading indicator start columns
  Assign(f, filename);
  Reset(f, 1);

  Repeat
    p := pointer(addr);
    BlockRead(f, buf, SizeOf(buf), bytesRead);
    Move(buf, p^, bytesRead);
    addr := addr + bytesRead;
    Inc(ldr);
    If ldr > 24 Then ldr := 10;
    Poke(scrBase + 840 + ldr, (peek($d20a) and 1) + 12);
    //loader viz    
  Until bytesRead = 0;
  Close(f);

  For ldr := 0 To 27 Do
    Poke(scrBase + 840 + ldr, 13);
  //restore line

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
        GotoXY(col,row);
        song_name := GetFileBase(Info.Name);
        writeln(song_name);
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
  GotoXY(0,22);
  WriteInverse(PLS_WAIT);
  //print loading
  is15Khz := true;
  //try .d15 ext first, then .d8
  song_file   := Concat(song_name, '.MD1');
  sample_file := Concat(song_name, D15_EXT);
  fullname := Concat(DRIVE, sample_file);
  If (FileExists(fullname) <> true) Then //if not,then it is .d8 ext
    Begin
      sample_file := Concat(song_name, D8_EXT);
      is15Khz := false;
    End;
  fullname := Concat(DRIVE, song_file);
  LoadAndRelocateMD1(fullname, ADDR_MD1);
  fullname := Concat(DRIVE, sample_file);
  LoadFileToAddr(fullname, ADDR_MD1 + md1module_size + 4);
End;


Procedure Efx;
//player visualization and song progress

Var 
  pattPos, t1h,t2h,t3h,t4h,eqv : byte;


Begin
  //rhythmic viz
  t1h := peek(SNG_INSTR_HIT_BASE + ADDR_PLAYER);
  t2h := peek(SNG_INSTR_HIT_BASE + ADDR_PLAYER + 1);
  t3h := peek(SNG_INSTR_HIT_BASE + ADDR_PLAYER + 2);
  t4h := peek(SNG_INSTR_HIT_BASE + ADDR_PLAYER + 3);
  pattPos := peek(ADDR_PLAYER + $092a);

  If pattPos <> lst_pat_pos Then
    Begin
      FillChar(P0, P_HEIGHT, 0);
      FillChar(P1, P_HEIGHT, 0);
      FillChar(P2, P_HEIGHT, 0);
      FillChar(P3, P_HEIGHT, 0);
      lst_pat_pos := pattPos;
      
      If lst_t1_hit <> t1h Then
        Begin
          //eqv := (peek(53760) * peek(53761) +255) Div 512;
          //freq * valume normalized for screen
          //FillChar(P0, P_HEIGHT , 0);        
          FillChar(P0, P_HEIGHT, $ff);
          lst_t1_hit := t1h;
        End;
      //2
      If lst_t2_hit <> t2h  Then
        Begin
          //eqv := (peek(53762) * peek(53763)+255) Div 512;
          //FillChar(P1, P_HEIGHT, 0);
          FillChar(P1,P_HEIGHT, $ff);
          lst_t2_hit := t2h;
        End;
      //3
      If lst_t3_hit <> t3h Then
        Begin
          //eqv := (peek(53764) * peek(53765)+255) Div 512;
          //FillChar(P2, P_HEIGHT, 0);
          FillChar(P2, P_HEIGHT, $ff);
          lst_t3_hit := t3h;
        End;
      //4
      If lst_t4_hit <> t4h  Then
        Begin
          //eqv := (peek(53766) * peek(53767)+255) Div 512;
          //FillChar(P3, P_HEIGHT, 0);
          FillChar(P3, P_HEIGHT, $ff);
          lst_t4_hit := t4h;
        End;

    End;


  //song progress viz  
  songPos := Peek(song_pos_addr);
  If lastSongPos <> songPos Then
    Begin
      lastSongPos := songPos;
      progress := (27 * songPos shr 1) Div songLength;
      for i := 0 to progress do Poke(scrBase + 840 + i, 12);      
    End;
End;


Procedure Vbl;
interrupt;
Begin
  msx.play;
  If song_selected = true Then Efx;
  If keypressed() Then msx.stop;
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


Procedure DrawOrnament();

Var 
  c, startChar: byte;
  r0,r1 : word;

Begin
  WriteInverse(TITLE);
  //ornament gfx
  startChar := 64;
  r0 := scrBase + ORNAMENT_ROW * 40 + ORNAMENT_COL;
  r1 := scrBase + (ORNAMENT_ROW + 8) * 40;
  While r0 <= r1 Do
    Begin
      For c := 0 To 7 Do
        Begin
          Poke(r0 + c, startChar);
          Inc(startChar);
        End;
      Inc(r0, 40);
    End;
  //line    
  For c := 0 To 27 Do
    Poke(scrBase + 840 + c, 13);
  //instr
  GotoXY(0,23);
  writeln(INSTR);
End;


Begin

  ClrScr;
  CursorOff;
  //backgorund
  Poke(COLBG, $04);
  Poke(COLPF1, $2a);
  Poke(COLPF2, $04);
  //
  scrBase := DPeek(88);
  //Tell ANTIC our font is the "official" one
  Poke($2F4, Hi(CHARSET_ADDR));
  //def curren song pos address
  song_pos_addr := ADDR_PLAYER + SNGPOS_ADDROFF;
  //browser cursor
  cursor_col := COL_MARGIN - 1;
  cursor_row := ROW_MARGIN;
  song_selected := false;
  DrawOrnament();
  ListFiles();

  While true Do
    Begin
      Repeat
        Browse()
      Until song_selected = true;

      LoadSong();
      songLength := GetTrackLength(ADDR_MD1);

      // PMG setup
      Poke(54279, PMG_BASE shr 8);
      // PMBASE
      Poke(559,   46);
      // DMACTL: double-line + players + missiles
      Poke(53277, 3);
      // GRACTL: enable players + missiles
      // player colors
      Poke(704, $34);
      Poke(705, $28);
      Poke(706, $EC);
      Poke(707, $C6);
      // player positions horizontal
      Poke(53248, 160);
      Poke(53249, 168);
      Poke(53250, 176);
      Poke(53251, 184);
      // normal size
      FillChar(pointer(53256), 4, 0);
      //end PMG setup

      SetIntVec(iVBL, @Vbl);
      msx.player  := pointer(ADDR_PLAYER);
      msx.modul   := pointer(ADDR_MD1);
      msx.sample  := pointer(ADDR_MD1 + md1module_size + 4);
      msx.init;
      msx.digi(is15Khz);
      msx.stop();

      //clean up MD1 data
      ptr := Pointer(ADDR_MD1);
      FillChar(Ptr^, 4096, 0);
      //bold assumption md1 module <= 4096 bytes
    End;
End.
