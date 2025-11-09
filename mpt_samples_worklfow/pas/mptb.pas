{$DEFINE BASICOFF}
Uses crt, sysutils, md1;

Const 
  ver = '0.107';
  
  COLBG   = $2C6;   // 710 – background / border
  COLPF1  = $2C5;   // 709 – playfield 1 (normal text)
  COLPF2  = $2C8;   // 712 – playf

  ADDR_PLAYER  = $7000;
  ADDR_MD1 = $8000;
  ADDR_SAMPLES = $9000;

  DRIVE   = 'D:';
  MD1_EXT = '.MD1';
  D15_EXT = '.D15';
  D8_EXT  = '.D8 ';

  MAX_BROWSE_ITEMS: byte = 63;
  MAX_COLUMN_ITEMS: byte = 18;
  COLUMN_WIDTH = 9;
  COLUMN_MARGIN = 3;
  ROW_MARGIN = 3;

Var 
  msx: TMD1;
  ch: char;
  browse_offset: byte = 0;
  is15Khz : boolean;
  song_name: string;
  

{$r mptb.rc}
  //md1player resource

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
  // no dot found
End;

//DOS II+/D Version 6.4 (c) '87 by S.D.
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
  buffer   : array[0..8191] Of byte;
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
      WriteLn('ERROR: ', filename, ' - not a valid DOS binary!');
      Halt;
    End;

  //Extract old address and compute real module length
  old_addr := buffer[2] + buffer[3] shl 8;
  data_len := (buffer[4] + buffer[5] shl 8) - old_addr + 1;
  ofs      := DOS_HDR;

  If read_cnt <> DOS_HDR + data_len Then
    Begin
      WriteLn('ERROR: file size mismatch');
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


//DOS II+/D Version 6.4 (c) '87 by S.D.
Procedure LoadFileToAddr(Const filename: String; addr: word);

Var 
  f: file;
  p: pointer;
  buf: array [0..255] Of byte;
  bytesRead: word;
  totalRead: word;

Begin
  totalRead := 0;
  Assign(f, filename);
  Reset(f, 1);

  Repeat
    p := pointer(addr);
    BlockRead(f, buf, SizeOf(buf), bytesRead);
    Move(buf, p^, bytesRead);
    addr := addr + bytesRead;
  Until bytesRead = 0;
  Close(f);
End;

//40x24
Procedure Browse;

Var 
  Info : TSearchRec;
  row,col : byte;
  song_name : string;
  
Begin  
  row := ROW_MARGIN;
  col := COLUMN_MARGIN;

  If FindFirst('D:*.MD1', faAnyFile, Info) = 0 Then   // '*.MD1  ?

    Begin
      Repeat        
        GotoXY(col,row);        
        song_name := GetFileBase(Info.Name);                    
        writeln(song_name);
        Inc(row);

        if row > MAX_COLUMN_ITEMS Then
          Begin
            row := ROW_MARGIN;
            col := col + COLUMN_MARGIN + COLUMN_WIDTH;
          End;

      Until (FindNext(Info) <> 0) or (shown = MAX_BROWSE_ITEMS);      
      FindClose(Info);

    End;
End;




Procedure LoadSong;

Var 
  sample_file : string;
  song_file : string;
  fullname : string;

Begin

  writeln('Now Loading: ',song_name);

  is15Khz := true;
  song_file   := Concat(song_name, MD1_EXT);
  sample_file := Concat(song_name, D15_EXT);

  fullname := Concat(DRIVE, sample_file);
  If (FileExists(fullname) <> true) Then
    Begin
      writeln('not 15Khz');
      sample_file := Concat(song_name, D8_EXT);
      is15Khz := false;
    End;

  fullname := Concat(DRIVE, song_file);
  LoadAndRelocateMD1(fullname, ADDR_MD1);
  fullname := Concat(DRIVE, sample_file);
  LoadFileToAddr(fullname, ADDR_SAMPLES);
End;


Procedure vbl;
interrupt;
Begin
  msx.play;
  asm { jmp xitvbv };
End;


Begin
  ClrScr;
  CursorOff;
  Poke(COLBG, $04);          // background black
  Poke(COLPF1, $2A);         // border black (same as background)  
  Poke(COLPF2, $00);// orange = hue 2, luminance 10 → $2A  (2*16 + 10)
  
  writeln('ver. ',ver);

  SetIntVec(iVBL, @vbl);
  
  Browse();

  While browse_offset < 255 Do
    Begin

      Repeat
        ch := ReadKey;  { get second code for special keys }
        // ClrScr;

        // Case ord(ch) Of 
        //   45://up arrow
        //       Begin
        //         Dec(browse_offset);
        //         Browse();
        //       End;
        //   61://down arrow
        //       Begin
        //         Inc(browse_offset);
        //         Browse();
        //       End;
        //   42://right arrow
        //       Begin
             
        //       End;
        //   43://left arrow
        //     Begin
             
        //       End;
        //   155:

        //        Else writeln('char: ', ord(ch));
        //End;
      Until ord(ch) = 155;
      //'E' like exit


      LoadSong();

      msx.player  := pointer(ADDR_PLAYER);
      msx.modul   := pointer(ADDR_MD1);
      msx.sample  := pointer(ADDR_SAMPLES);
      msx.init;

      Repeat
        msx.digi(is15Khz);
      Until keypressed;

      msx.stop;

      writeln('stopped , press any key');
    End;
  Repeat
  Until keypressed;
End.
