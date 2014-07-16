// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
library inject;
uses
  windows,
  IniFiles,
  SysUtils,
  advApiHook in 'units\advApiHook.pas',
  NativeAPI in 'units\NativeAPI.pas';

//(* ��������� �� ����� ������ �������� �����
{$SETPEFlAGS IMAGE_FILE_DEBUG_STRIPPED or
  IMAGE_FILE_LINE_NUMS_STRIPPED or IMAGE_FILE_LOCAL_SYMS_STRIPPED}
//{$WEAKLINKRTTI ON}
//{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
//*)

const
  user32    = 'user32.dll';
  kernel32  = 'kernel32.dll';
  winsocket = 'wsock32.dll';
  Opcodes1: array [0..255] of word =
  (
    $4211, $42E4, $2011, $20E4, $8401, $8C42, $0000, $0000, $4211, $42E4,
    $2011, $20E4, $8401, $8C42, $0000, $0000, $4211, $42E4, $2011, $20E4,
     $8401, $8C42, $0000, $0000, $4211, $42E4, $2011, $20E4, $8401, $8C42,
     $0000, $0000, $4211, $42E4, $2011, $20E4, $8401, $8C42, $0000, $8000,
     $4211, $42E4, $2011, $20E4, $8401, $8C42, $0000, $8000, $4211, $42E4,
     $2011, $20E4, $8401, $8C42, $0000, $8000, $0211, $02E4, $0011, $00E4,
     $0401, $0C42, $0000, $8000, $6045, $6045, $6045, $6045, $6045, $6045,
     $6045, $6045, $6045, $6045, $6045, $6045, $6045, $6045, $6045, $6045,
     $0045, $0045, $0045, $0045, $0045, $0045, $0045, $0045, $6045, $6045,
     $6045, $6045, $6045, $6045, $6045, $6045, $0000, $8000, $00E4, $421A,
     $0000, $0000, $0000, $0000, $0C00, $2CE4, $0400, $24E4, $0000, $0000,
     $0000, $0000, $1400, $1400, $1400, $1400, $1400, $1400, $1400, $1400,
     $1400, $1400, $1400, $1400, $1400, $1400, $1400, $1400, $0510, $0DA0,
     $0510, $05A0, $0211, $02E4, $A211, $A2E4, $4211, $42E4, $2011, $20E4,
     $42E3, $20E4, $00E3, $01A0, $0000, $E046, $E046, $E046, $E046, $E046,
     $E046, $E046, $8000, $0000, $0000, $0000, $0000, $0000, $0000, $8000,
     $8101, $8142, $0301, $0342, $0000, $0000, $0000, $0000, $0401, $0C42,
     $0000, $0000, $8000, $8000, $0000, $0000, $6404, $6404, $6404, $6404,
     $6404, $6404, $6404, $6404, $6C45, $6C45, $6C45, $6C45, $6C45, $6C45,
     $6C45, $6C45, $4510, $45A0, $0800, $0000, $20E4, $20E4, $4510, $4DA0,
     $0000, $0000, $0800, $0000, $0000, $0400, $0000, $0000, $4110, $41A0,
     $4110, $41A0, $8400, $8400, $0000, $8000, $0008, $0008, $0008, $0008,
     $0008, $0008, $0008, $0008, $1400, $1400, $1400, $1400, $8401, $8442,
     $0601, $0642, $1C00, $1C00, $0000, $1400, $8007, $8047, $0207, $0247,
     $0000, $0000, $0000, $0000, $0000, $0000, $0008, $0008, $0000, $0000,
     $0000, $0000, $0000, $0000, $4110, $01A0
  );

  Opcodes2: array [0..255] of word =
  (
    $0118, $0120, $20E4, $20E4, $FFFF, $0000, $0000, $0000, $0000, $0000,
    $FFFF, $FFFF, $FFFF, $0110, $0000, $052D, $003F, $023F, $003F, $023F,
     $003F, $003F, $003F, $023F, $0110, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF,
     $FFFF, $FFFF, $4023, $4023, $0223, $0223, $FFFF, $FFFF, $FFFF, $FFFF,
     $003F, $023F, $002F, $023F, $003D, $003D, $003F, $003F, $0000, $8000,
     $8000, $8000, $0000, $0000, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF,
     $FFFF, $FFFF, $FFFF, $FFFF, $20E4, $20E4, $20E4, $20E4, $20E4, $20E4,
     $20E4, $20E4, $20E4, $20E4, $20E4, $20E4, $20E4, $20E4, $20E4, $20E4,
     $4227, $003F, $003F, $003F, $003F, $003F, $003F, $003F, $003F, $003F,
     $003F, $003F, $003F, $003F, $003F, $003F, $00ED, $00ED, $00ED, $00ED,
     $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED,
     $0065, $00ED, $04ED, $04A8, $04A8, $04A8, $00ED, $00ED, $00ED, $0000,
     $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $0265, $02ED, $1C00, $1C00,
     $1C00, $1C00, $1C00, $1C00, $1C00, $1C00, $1C00, $1C00, $1C00, $1C00,
     $1C00, $1C00, $1C00, $1C00, $4110, $4110, $4110, $4110, $4110, $4110,
     $4110, $4110, $4110, $4110, $4110, $4110, $4110, $4110, $4110, $4110,
     $0000, $0000, $8000, $02E4, $47E4, $43E4, $C211, $C2E4, $0000, $0000,
     $0000, $42E4, $47E4, $43E4, $0020, $20E4, $C211, $C2E4, $20E4, $42E4,
     $20E4, $22E4, $2154, $211C, $FFFF, $FFFF, $05A0, $42E4, $20E4, $20E4,
     $2154, $211C, $A211, $A2E4, $043F, $0224, $0465, $24AC, $043F, $8128,
     $6005, $6005, $6005, $6005, $6005, $6005, $6005, $6005, $FFFF, $00ED,
     $00ED, $00ED, $00ED, $00ED, $02ED, $20AC, $00ED, $00ED, $00ED, $00ED,
     $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED,
     $003F, $02ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED,
     $FFFF, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED, $00ED,
     $00ED, $00ED, $00ED, $00ED, $00ED, $0000                            
  );

  Opcodes3: array [0..9] of array [0..15] of word =
  (
     ($0510, $FFFF, $4110, $4110, $8110, $8110, $8110, $8110, $0510, $FFFF,
      $4110, $4110, $8110, $8110, $8110, $8110),
     ($0DA0, $FFFF, $41A0, $41A0, $81A0, $81A0, $81A0, $81A0, $0DA0, $FFFF,
      $41A0, $41A0, $81A0, $81A0, $81A0, $81A0),
     ($0120, $0120, $0120, $0120, $0120, $0120, $0120, $0120, $0036, $0036,
      $0030, $0030, $0036, $0036, $0036, $0036),
     ($0120, $FFFF, $0120, $0120, $0110, $0118, $0110, $0118, $0030, $0030,
      $0000, $0030, $0000, $0000, $0000, $0000),
     ($0120, $0120, $0120, $0120, $0120, $0120, $0120, $0120, $0036, $0036,
      $0036, $0036, $FFFF, $0000, $FFFF, $FFFF),
     ($0120, $FFFF, $0120, $0120, $FFFF, $0130, $FFFF, $0130, $0036, $0036,
      $0036, $0036, $0000, $0036, $0036, $0000),
     ($0128, $0128, $0128, $0128, $0128, $0128, $0128, $0128, $0236, $0236,
      $0030, $0030, $0236, $0236, $0236, $0236),
     ($0128, $FFFF, $0128, $0128, $0110, $FFFF, $0110, $0118, $0030, $0030,
      $0030, $0030, $0030, $0030, $FFFF, $FFFF),
     ($0118, $0118, $0118, $0118, $0118, $0118, $0118, $0118, $0236, $0236,
      $0030, $0236, $0236, $0236, $0236, $0236),
     ($0118, $FFFF, $0118, $0118, $0130, $0128, $0130, $0128, $0030, $0030,
      $0030, $0030, $0000, $0036, $0036, $FFFF)
  );
  PAGE_EXECUTE_READWRITE = $40;
type
  HWND = type LongWord;
  DWORD = LongWord;
  UINT = LongWord;
  WPARAM = Longint;
  LPARAM = Longint;
  LRESULT = Longint;
  LPCSTR = PAnsiChar;
  FARPROC = Pointer;
  {$EXTERNALSYM u_char}
  u_char = Char;
  {$EXTERNALSYM u_short}
  u_short = Word;
  {$EXTERNALSYM u_int}
  u_int = Integer;
  {$EXTERNALSYM u_long}
  u_long = Longint;
  {$EXTERNALSYM SunB}
  SunB = packed record
    s_b1, s_b2, s_b3, s_b4: u_char;
  end;

  {$EXTERNALSYM SunW}
  SunW = packed record
    s_w1, s_w2: u_short;
  end;
  in_addr = record
    case integer of
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: u_long);
  end;
  TInAddr = in_addr;
  sockaddr_in = record
    case Integer of
      0: (sin_family: u_short;
          sin_port: u_short;
          sin_addr: TInAddr;
          sin_zero: array[0..7] of Char);
      1: (sa_family: u_short;
          sa_data: array[0..13] of Char)
  end;
  TSockAddrIn = sockaddr_in;

var
  ConnectNextHook : function (s: Integer; var Name: sockaddr_in; namelen: Integer): Integer; stdcall;

{function FindWindow(lpClassName, lpWindowName: PAnsiChar): HWND; stdcall; external user32 name 'FindWindowA';
//function FindWindow; external user32 name 'FindWindowA';
function SendMessage(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; external user32 name 'SendMessageA';
//function SendMessage; external user32 name 'SendMessageA';}
function inet_addr(cp: PAnsiChar): u_long; stdcall;  external    winsocket name 'inet_addr';
//function inet_addr;         external    winsocket name 'inet_addr';

//by xkor
function GetCurrentModuleImagePath: string;
var
  mbi: MEMORY_BASIC_INFORMATION;
  pBuf: array[0..MAX_PATH] of char;
begin
  VirtualQuery(@GetCurrentModuleImagePath, mbi, sizeof(mbi));
  GetModuleFileName(Cardinal(mbi.AllocationBase), pBuf, MAX_PATH);
  result:=pBuf;
end;

function ConnectHookProc(s: Integer; var Name: sockaddr_in; namelen: Integer): Integer; stdcall;
var
//  buf: array[0..5] of Byte;
  apph: HWND;
  x: packed record
    lo: Word;
    hi: Word;
  end absolute apph;
  Options :TIniFile;
  wcnL2PH : string;
begin
  Options:=TIniFile.Create(ExtractFilePath(GetCurrentModuleImagePath)+'settings\Options.ini');
  wcnL2PH := Options.ReadString('general', 'WinClassName', 'TfMainRep');
  Options.Destroy;
  if (Length(wcnL2PH)<=64) AND (Length(wcnL2PH)<>0) then
  begin
    //MessageBox(0, 'inject', PChar(String(wcnL2PH)), MB_OK);
    apph:=FindWindow(PChar(String(wcnL2PH)), nil);
  end else
  begin
    //MessageBox(0, 'inject', 'TfMainRep', MB_OK);
    apph:=FindWindow('TfMainRep', nil);
  end;

  if (apph>0)then begin
    apph:=SendMessage(apph,$04F0,Name.sin_addr.S_addr,Name.sin_port);
    if x.lo=1 then begin
      Name.sin_addr.S_addr:=inet_addr('127.0.0.1');
      Name.sin_port:=x.hi;
    end;
  end;
  result:=ConnectNextHook(s, Name, namelen);
end;

{��������� ������� ������� �������� �������� �� ��������� �� ��� }
function SizeOfCode(Code: pointer): dword;
var
  Opcode: word;
  Modrm: byte;
  Fixed, AddressOveride: boolean;
  Last, OperandOveride, Flags, Rm, Size, Extend: dword;
begin
  try
    Last := dword(Code);
    if Code <> nil then
    begin
      AddressOveride := False;
      Fixed := False;
      OperandOveride := 4;
      Extend := 0;
      repeat
        Opcode := byte(Code^);
        Code := pointer(dword(Code) + 1);
        if Opcode = $66 then OperandOveride := 2
        else if Opcode = $67 then  AddressOveride := True
        else
        if not ((Opcode and $E7) = $26) then
         if not (Opcode in [$64..$65]) then  Fixed := True;
      until Fixed;
      if Opcode = $0f then
      begin
        Opcode := byte(Code^);
        Flags := Opcodes2[Opcode];
        Opcode := Opcode + $0f00;
        Code := pointer(dword(Code) + 1);
      end
      else Flags := Opcodes1[Opcode];

      if ((Flags and $0038) <> 0) then
      begin
        Modrm := byte(Code^);
        Rm := Modrm and $7;
        Code := pointer(dword(Code) + 1);

        case (Modrm and $c0) of
          $40: Size := 1;
          $80: if AddressOveride then Size := 2 else Size := 4;
          else Size := 0;
        end;

        if not (((Modrm and $c0) <> $c0) and AddressOveride) then
        begin
          if (Rm = 4) and ((Modrm and $c0) <> $c0) then Rm := byte(Code^) and $7;
          if ((Modrm and $c0 = 0) and (Rm = 5)) then Size := 4;
          Code := pointer(dword(Code) + Size);
        end;

        if ((Flags and $0038) = $0008) then
        begin
          case Opcode of
            $f6: Extend := 0;
            $f7: Extend := 1;
            $d8: Extend := 2;
            $d9: Extend := 3;
            $da: Extend := 4;
            $db: Extend := 5;
            $dc: Extend := 6;
            $dd: Extend := 7;
            $de: Extend := 8;
            $df: Extend := 9;
          end;
          if ((Modrm and $c0) <> $c0) then
            Flags := Opcodes3[Extend][(Modrm shr 3) and $7] else
            Flags := Opcodes3[Extend][((Modrm shr 3) and $7) + 8];
        end;

      end;
      case (Flags and $0C00) of
        $0400: Code := pointer(dword(Code) + 1);
        $0800: Code := pointer(dword(Code) + 2);
        $0C00: Code := pointer(dword(Code) + OperandOveride);
        else
        begin
          case Opcode of
            $9a, $ea: Code := pointer(dword(Code) + OperandOveride + 2);
            $c8: Code := pointer(dword(Code) + 3);
            $a0..$a3:
              begin
                if AddressOveride then
                  Code := pointer(dword(Code) + 2)
                  else Code := pointer(dword(Code) + 4);
              end;
          end;
        end;
      end;
    end;
    Result := dword(Code) - Last;
  except
    Result := 0;
  end;
end;

{ �������� ����� � ������ ������� }
procedure CopyMemory(Destination: Pointer; Source: Pointer; Length: DWORD);
begin
  Move(Source^, Destination^, Length);
end;

function SaveOldFunction(Proc: pointer; Old: pointer): dword;
var
  SaveSize, Size: dword;
  Next: pointer;
begin
  SaveSize := 0;
  Next := Proc;
  //��������� ��������� ��������� ��������, ���� ���� ������� ����������
  while SaveSize < 5 do
  begin
    Size := SizeOfCode(Next);
    Next := pointer(dword(Next) + Size);
    Inc(SaveSize, Size);
  end;
  CopyMemory(Old, Proc, SaveSize);
  //���������� ������� �� ��������� ���������� ����� ������������ �������
  byte(pointer(dword(Old) + SaveSize)^) := $e9;
  dword(pointer(dword(Old) + SaveSize + 1)^) := dword(Next) - dword(Old) - SaveSize - 5;
  Result := SaveSize;
end;

{function VirtualProtect(lpAddress: Pointer; dwSize, flNewProtect: DWORD;
  lpflOldProtect: Pointer): Boolean; external kernel32 name 'VirtualProtect';
function VirtualProtect(lpAddress: Pointer; dwSize, flNewProtect: DWORD;
  var OldProtect: DWORD): Boolean; external kernel32 name 'VirtualProtect';
{
  ��������� ��������� �������.
  TargetProc - ����� ��������������� �������,
  NewProc    - ����� ������� ������,
  OldProc    - ����� ����� �������� ����� ����� � ������ �������.
}
function HookCode(TargetProc, NewProc: pointer; var OldProc: pointer): boolean;
var
  Address: dword;
  OldProtect: dword;
  OldFunction: pointer;
  Proc: pointer;
begin
  Result := False;
  try
    Proc := TargetProc;
    //��������� ����� �������������� (jmp near) �������� �� ����� �������
    Address := dword(NewProc) - dword(Proc) - 5;
    if not VirtualProtect(Proc, 5, PAGE_EXECUTE_READWRITE, OldProtect) then begin
      Exit;
//      MessageBox(0,'VirtualProtect Error','title',MB_OK);
    end;
    //������� ������ ��� true �������
    GetMem(OldFunction, 255);
    //�������� ������ 4 ����� �������
    dword(OldFunction^) := dword(Proc);
    byte(pointer(dword(OldFunction) + 4)^) := SaveOldFunction(Proc, pointer(dword(OldFunction) + 5));
    //byte(pointer(dword(OldFunction) + 4)^) - ����� ������������ �������
    byte(Proc^) := $e9; //������������� �������
    dword(pointer(dword(Proc) + 1)^) := Address;
    VirtualProtect(Proc, 5, OldProtect, OldProtect);
    OldProc := pointer(dword(OldFunction) + 5);
  except
    Exit;
  end;
  Result := True;
end;


{
 ��������� ��������� ������� �� Dll � ������� ��������.
 lpModuleName - ��� ������,
 lpProcName   - ��� �������,
 NewProc    - ����� ������� ������,
 OldProc    - ����� ����� �������� ����� ����� � ������ �������.
 � ������ ���������� ������ � ������� ��, ����� ������� ������� ��� ���������.
}{
function GetModuleHandle(lpModuleName: PAnsiChar): HMODULE; stdcall; external kernel32 name 'GetModuleHandleA';
//function GetModuleHandle; external kernel32 name 'GetModuleHandleA';
function GetProcAddress(hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall; external kernel32 name 'GetProcAddress';
//function GetProcAddress; external kernel32 name 'GetProcAddress';
function LoadLibrary(lpLibFileName: PAnsiChar): HMODULE; stdcall; external kernel32 name 'LoadLibraryA';
{$EXTERNALSYM LoadLibrary}
//function LoadLibrary; external kernel32 name 'LoadLibraryA';}

function HookProc(lpModuleName, lpProcName: PAnsiChar;
                  NewProc: pointer; var OldProc: pointer): boolean;
var
 hModule: dword;
 fnAdr: pointer;
begin
 Result := false;
 hModule := GetModuleHandleA(lpModuleName);
 if hModule = 0 then hModule := LoadLibraryA(lpModuleName);
 if hModule = 0 then Exit;
 fnAdr := GetProcAddress(hModule, lpProcName);
 if fnAdr = nil then Exit;
 Result := HookCode(fnAdr, NewProc, OldProc);
end;

procedure CvtInt;
{ IN:
    EAX:  The integer value to be converted to text
    ESI:  Ptr to the right-hand side of the output buffer:  LEA ESI, StrBuf[16]
    ECX:  Base for conversion: 0 for signed decimal, 10 or 16 for unsigned
    EDX:  Precision: zero padded minimum field width
  OUT:
    ESI:  Ptr to start of converted text (not start of buffer)
    ECX:  Length of converted text
}
asm
        OR      CL,CL
        JNZ     @CvtLoop
@C1:    OR      EAX,EAX
        JNS     @C2
        NEG     EAX
        CALL    @C2
        MOV     AL,'-'
        INC     ECX
        DEC     ESI
        MOV     [ESI],AL
        RET
@C2:    MOV     ECX,10

@CvtLoop:
        PUSH    EDX
        PUSH    ESI
@D1:    XOR     EDX,EDX
        DIV     ECX
        DEC     ESI
        ADD     DL,'0'
        CMP     DL,'0'+10
        JB      @D2
        ADD     DL,('A'-'0')-10
@D2:    MOV     [ESI],DL
        OR      EAX,EAX
        JNE     @D1
        POP     ECX
        POP     EDX
        SUB     ECX,ESI
        SUB     EDX,ECX
        JBE     @D5
        ADD     ECX,EDX
        MOV     AL,'0'
        SUB     ESI,EDX
        JMP     @z
@zloop: MOV     [ESI+EDX],AL
@z:     DEC     EDX
        JNZ     @zloop
        MOV     [ESI],AL
@D5:
end;

function IntToStr(Value: Integer): string;
//  FmtStr(Result, '%d', [Value]);
begin
  str(Value,Result);
end;
{asm
        PUSH    ESI
        MOV     ESI, ESP
        SUB     ESP, 16
        XOR     ECX, ECX       // base: 0 for signed decimal
        PUSH    EDX            // result ptr
        XOR     EDX, EDX       // zero filled field width: 0 for no leading zeros
        CALL    CvtInt
        MOV     EDX, ESI
        POP     EAX            // result ptr
        CALL    System.@LStrFromPCharLen
        ADD     ESP, 16
        POP     ESI
end;}

Function MarkProcessInjected:boolean;
var
 hMutex : cardinal;
begin
 result := false;
 hMutex := CreateMutex(nil, false, PChar('jec'+inttostr(GetCurrentProcessId)));
 if GetLastError = ERROR_ALREADY_EXISTS then
 begin
   ReleaseMutex(hMutex);
   CloseHandle(hMutex);
   exit;
 end;
 result := true;
end;

begin
  if MarkProcessInjected then
  begin
    StopProcess(GetCurrentProcessId);
    if not HookProc('ws2_32.dll', 'connect', @ConnectHookProc, @ConnectNextHook) then
      HookProc('wsock32.dll', 'connect', @ConnectHookProc, @ConnectNextHook);
    RunProcess(GetCurrentProcessId);
  end;
end.

//
//begin
//...
//  dllPath:=  ExtractFilePath(GetCurrentModuleImagePath);
//...
//end.
