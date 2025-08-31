program BigScreenFrameAnim;

{$R poc.rc}
uses
  crt;

var
  screen_base: Word = $9000;
  dl: array[0..102] of Byte absolute $8000;
  frame_ptrs: array[0..5] of Pointer; // Pointers to frame data
  i, j: Byte;
  offset: Word = 40 * 40 + 16; // Animation positioned at y=40, x=64 (64 / 4 = 16 bytes)
  target: Pointer;  
  tempPtr: Pointer; // resource loading

procedure BuildDisplayList;
var
  k: Byte;
begin
  dl[0] := 112; // 3 blank lines
  dl[1] := 112;
  dl[2] := 112;
  dl[3] := 77; // LMS + ANTIC mode D (64 + 13)
  dl[4] := Lo(screen_base);
  dl[5] := Hi(screen_base);
  for k := 6 to 100 do dl[k] := 13; // 95 mode D lines
  dl[101] := 65; // JVB
  dl[102] := Lo(Word(@dl));
  dl[103] := Hi(Word(@dl));
end;

procedure LoadResources;
begin
  // Load main image
  GetResourceHandle(tempPtr, 'MAIN_IMAGE');
  Move(tempPtr, Pointer(screen_base), 3072);

  // Load frame pointers using temporary variable
  GetResourceHandle(tempPtr, 'FRAME0');
  frame_ptrs[0] := tempPtr;
  GetResourceHandle(tempPtr, 'FRAME1');
  frame_ptrs[1] := tempPtr;
  GetResourceHandle(tempPtr, 'FRAME2');
  frame_ptrs[2] := tempPtr;
  GetResourceHandle(tempPtr, 'FRAME3');
  frame_ptrs[3] := tempPtr;
  GetResourceHandle(tempPtr, 'FRAME4');
  frame_ptrs[4] := tempPtr;
  GetResourceHandle(tempPtr, 'FRAME5');
  frame_ptrs[5] := tempPtr;
end;

begin
  
  BuildDisplayList;
  Poke(559, 0); // Disable DMA

  // Set display list pointer
  Poke(560, Lo(Word(@dl)));
  Poke(561, Hi(Word(@dl)));

  // Set colors
  Poke(708, 0);   // PF0: black
  Poke(709, 40);  // PF1: blue
  Poke(710, 200); // PF2: orange
  Poke(711, 14);  // PF3: white
  Poke(712, 0);   // Background: black

  // Load resources
  LoadResources;

  // Set animation target position
  target := Pointer(screen_base + offset);

  // Enable DMA
  Poke(559, 34);

  while not KeyPressed do
  begin
    for i := 0 to 5 do
    begin
      // Copy frame to screen (16 lines, 8 bytes per line)
      for j := 0 to 15 do
      begin        
        Move(Pointer(Word(frame_ptrs[i]) + j * 8), 
             Pointer(Word(target) + j * 40), 
             8);
      end;
      
      //wait?
    end;
  end;
end.