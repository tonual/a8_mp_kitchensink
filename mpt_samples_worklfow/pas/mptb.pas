
Uses crt, sysutils, md1;

Const 
  md1_player = $3000;
  module_addr = $5040;
  sample_addr = $6000;

  module_filenames : array [0..2] Of string = ('D:TNL4.MD1', 'D:BLUE3.MD1', 'D:TRANSIL.MD1');
  sample_filenames : array [0..2] Of string = ('D:TNL4.D15', 'D:BLUE3.D15', 'D:TRANSIL.D15');

Var 
  msx: TMD1;
  ch: char;
  song_index: byte = 0;

{$r mptb.rc}

Procedure LoadAndRelocate(Const filename : String; new_address : word);
{--------------------------------------------------------------------}
{  Load a .MD1 (Music Pro Tracker) module from disk and relocate it   }
{  to NEW_ADDRESS exactly the way the MADS macro mpt_relocator.mac   }
{  does it at compile-time.                                           }
{--------------------------------------------------------------------}

Const 
  MAX_MODULE = 8192;
  // 8 KB is more than enough for any .MD1
  DOS_HDR   = 6;
  // DOS header size (FFFF …)

Var 
  f          : file;
  file_len   : word;
  // bytes actually read
  data_len   : word;
  // length of the module *without* DOS header
  old_addr   : word;
  // address stored in the DOS header
  ofs        : word;
  // offset of the first module byte
  i          : byte;
  tmp16      : word;
  tmp8       : byte;
  npt        : pointer;

  // a small buffer that can hold the whole file
  buffer     : array[0..MAX_MODULE-1] Of byte;

Begin
  // ----------------------------------------------------------------
  // 1) Load the binary file (DOS header + module data)
  // ----------------------------------------------------------------
  Assign(f, filename);
  Reset(f, 1);
  // record size = 1 byte
  file_len := 0;
  BlockRead(f, buffer, SizeOf(buffer), file_len);
  Close(f);

  If (file_len < DOS_HDR + 2) Or (buffer[0] <> $FF) Or (buffer[1] <> $FF) Then
    Begin
      WriteLn('ERROR: ', filename, ' is not a valid DOS binary file');
      Halt;
    End;

  // ----------------------------------------------------------------
  // 2) Extract old address and compute module length
  // ----------------------------------------------------------------
  old_addr := buffer[2] + buffer[3] shl 8;
  // original load address
  data_len := buffer[4] + buffer[5] shl 8 - old_addr + 1;
  // module size without header
  ofs      := DOS_HDR;
  // first module byte

  If file_len <> DOS_HDR + data_len Then
    Begin
      WriteLn('ERROR: file size mismatch (corrupted module?)');
      Halt;
    End;

  // ----------------------------------------------------------------
  // 3) Fix the DOS header so the file can be RUN again
  // ----------------------------------------------------------------
  buffer[2] := Lo(new_address);
  buffer[3] := Hi(new_address);
  buffer[4] := Lo(new_address + data_len - 1);
  buffer[5] := Hi(new_address + data_len - 1);

  // ----------------------------------------------------------------
  // 4) Relocate the 32 instrument pointers (offset $0000 … $003F)
  // ----------------------------------------------------------------
  For i := 0 To 31 Do
    Begin
      tmp16 := buffer[ofs + i*2] + buffer[ofs + i*2 + 1] shl 8;
      If tmp16 <> 0 Then
        Begin
          tmp16 := tmp16 - old_addr + new_address;
          buffer[ofs + i*2]     := Lo(tmp16);
          buffer[ofs + i*2 + 1] := Hi(tmp16);
        End;
    End;

  // ----------------------------------------------------------------
  // 5) Relocate the 64 pattern pointers (offset $0040 … $00BF)
  // ----------------------------------------------------------------
  For i := 0 To 63 Do
    Begin
      tmp16 := buffer[ofs + $40 + i*2] + buffer[ofs + $40 + i*2 + 1] shl 8;
      If tmp16 <> 0 Then
        Begin
          tmp16 := tmp16 - old_addr + new_address;
          buffer[ofs + $40 + i*2]     := Lo(tmp16);
          buffer[ofs + $40 + i*2 + 1] := Hi(tmp16);
        End;
    End;

  // ----------------------------------------------------------------
  // 6) Relocate the 4 track pointers
  //     low  bytes : $01C0 … $01C3
  //     high bytes : $01C4 … $01C7
  // ----------------------------------------------------------------
  For i := 0 To 3 Do
    Begin
      tmp16 := buffer[ofs + $1C0 + i] + buffer[ofs + $1C4 + i] shl 8;
      If tmp16 <> 0 Then
        Begin
          tmp16 := tmp16 - old_addr + new_address;
          buffer[ofs + $1C0 + i] := Lo(tmp16);
          buffer[ofs + $1C4 + i] := Hi(tmp16);
        End;
    End;

  // ----------------------------------------------------------------
  // 7) Copy the relocated module into its final memory location
  // ----------------------------------------------------------------
  npt := Pointer(new_address);
  Move(buffer[ofs],npt^, data_len);
End;


//DOS II+/D Version 6.4 (c) '87 by S.D.
Function LoadFileToAddr(Const filename: String; addr: word): Boolean;

Var 
  f: file;
  
  p: pointer;
  buf: array [0..255] Of byte;
  bytesRead: word;
  totalRead: word;

Begin
  totalRead := 0;
  writeln('reading file: ',filename);
  Result := false;
//{$I-}

  Assign(f, filename);
  Reset(f, 1);

  totalRead:=0;
  
  Repeat
    p := pointer(addr);
    BlockRead(f, buf, SizeOf(buf), bytesRead);    
    Move(buf, p^, bytesRead);
    addr := addr + bytesRead;
    totalRead := totalRead + bytesRead;
  Until bytesRead = 0;// SizeOf(buf);
  Close(f);
//{$I+}

  writeln('total bytes read: ',totalRead);
  Result := true;
End;

Procedure vbl;
interrupt;
Begin
  msx.play;
  asm { jmp xitvbv };
End;

Begin

  SetIntVec(iVBL, @vbl);

  While song_index < 3 Do
    Begin      
      LoadAndRelocate(module_filenames[song_index], module_addr);
      writeln('.md1 loaded');
      ch := readkey;
      LoadFileToAddr(sample_filenames[song_index], sample_addr);
      writeln('.d15 loaded');
      ch := readkey;

      msx.player := pointer(md1_player);
      msx.modul := pointer(module_addr);
      msx.sample := pointer(sample_addr);
      msx.init;

      Repeat
        msx.digi(true);
      Until keypressed;

      ch := readkey;
      msx.stop;
      Inc(song_index);
      writeln('Next song ', song_index);
    End;

  Repeat
  Until keypressed;
End.
