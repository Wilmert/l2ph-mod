unit uGlobalFuncs;

interface

uses
  uResourceStrings, 
  uSharedStructs, 
  sysutils, 
  windows, 
  Classes, 
  TlHelp32, 
  PSAPI, 
  advApiHook,
  inifiles, 
  Controls, 
  Messages, 
  uencdec;

  const
    WM_Dll_Log = $04F0;               //�������� ��������� �� inject.dll
    WM_NewAction = WM_APP + 107; //
    WM_AddLog = WM_APP + 108; //
    WM_NewPacket = WM_APP + 109; //
    WM_ProcessPacket = WM_APP + 110; //
    WM_UpdAutoCompleate = WM_APP + 111; //
    WM_BalloonHint = WM_APP + 112; //

    //TencDec �������� �����
    TencDec_Action_LOG = 1; //������ � sLastPacket;  ���������� - PacketSend
    TencDec_Action_MSG = 2; //�a���� � sLastMessage; ���������� - Log
    TencDec_Action_GotName = 3; //������ � name; ���������� - UpdateComboBox1 (������� �������������)
    TencDec_Action_ClearPacketLog = 4; //������ ���. ������ �����; ���������� ClearPacketsLog
    //TSocketEngine �������� ���
    TSocketEngine_Action_MSG = 5; //������ � sLastMessage; ���������� - Log
    Ttunel_Action_connect_server = 6; //
    Ttunel_Action_disconnect_server = 7; //
    Ttunel_Action_connect_client = 8; //
    Ttunel_Action_disconnect_client = 9; //
    Ttulel_action_tunel_created = 10; //
    Ttulel_action_tunel_destroyed = 11; //
                                //Reserved 100-115!!!
  type
    SendMessageParam = class
    packet : tpacket;
    FromServer : boolean;
    Id : integer;
    tunel : Tobject;
  end;
  //�����������//
  function SymbolEntersCount(s : string) : string;
  function HexToString(Hex : String) : String;
  function ByteArrayToHex(str1 : array of Byte; size : Word) : String;
  function WideStringToString(const ws : WideString; codePage : Word) : AnsiString;
  function StringToHex(str1, Separator : String) : String;
  function StringToWideString(const s : AnsiString; codePage : Word) : WideString;
  procedure FillVersion_a;
  //�����������//

  function getversion : string;

  function AddDateTime : string; //������� "11.12.2009 02.03.06"
  function AddDateTimeNormal : string; //������� "11.12.2009 02 : 03 : 06"
  function TimeStepByteStr : string;

  //��������� ���������
  Function LoadLibraryXor(const name : string) : boolean; //��������� ������.��� ������������ � SettingsDialog
  Function LoadLibraryInject (const name : string) : boolean; //��������� ������.��� ������������ SettingsDialog
  procedure deltemps;
  procedure GetProcessList(var sl : TStrings); //�������� ������ ��������� ������������ � dmData.timerSearchProcesses

  procedure Reload;

  Function GetPacketName(var id : byte; var subid, sub2id : word; FromServer : boolean; var pname : string; var isshow : boolean) : boolean;
  function GetNamePacket(s : string) : string; // �������� �������� ������ �� ������

  var
    AppPath : String;
    isGlobalDestroying : boolean;
    hXorLib : THandle; //����� ���������� ������. ��������������� � SettingsDialog
    pInjectDll : Pointer; //������ � ������.��� ��������������� � SettingsDialog
    CreateXorIn : Function(Value : PCodingClass) : HRESULT; stdcall; //���� ���������� ������ (������)
    CreateXorOut : Function(Value : PCodingClass) : HRESULT; stdcall; //��� ��������������� � ��������������� � SettingsDialog (������)

    sClientsList, //������ ��������� ���������� ��������� ��������������� � SettingsDialog
    sIgnorePorts, //�������� ������ ���������� �� ������� ������������ ��������������� � SettingsDialog
    sNewxor, //���� � ������.��� ��������������� � SettingsDialog
    sInject, //���� � ������.��� ��������������� � SettingsDialog
    sLSP : string; //���� � ��� ������. ��������������� � SettingsDialog
    LocalPort : word; //������� ����. ��������������� � SettingsDialog.
    AllowExit : boolean; //��������� �����. ��������������� � SettingsDialog

    //����� �������������� NpcID, ��������� ��� ����������� ����������� ����� ���
    kNpcID : Cardinal;

    GlobalSettings : TEncDecSettings; //������� ��������� ��� ������ ��������������� � SettingsDialog
    filterS, filterC : string; //������ ��������

  //��������� (packets???.ini) �������������� ����������
  type
      TProtocolVersion = (AION, AION27,
                          CHRONICLE4, CHRONICLE5,
                          INTERLUDE,
                          GRACIA, GRACIAFINAL, GRACIAEPILOGUE,
                          FREYA,  HIGHFIVE,    GOD);
  var
      GlobalProtocolVersion : TProtocolVersion = AION;

  procedure AddToLog (msg : String); //��������� ������ � frmLogForm.log
  procedure BalloonHint(title, msg : string);
  procedure loadpos(Control : TControl);
  procedure savepos(Control : TControl);

  function GetModifTime(const FileName : string) : TDateTime;

  function DataPckToStrPck(var pck) : string; stdcall;
  var
    l2pxversion_array : array[0..3] of Byte; //������ ����������� ������� FillVersion_a
    l2pxversion : LongWord  absolute l2pxversion_array;

    MaxLinesInLog : Integer; //������������ ���������� ����� � ���� ����� �������� ���� ������� � ���� � �������� ���
    MaxLinesInPktLog : Integer; //������������ ���������� ����� � ���� ������� ����� �������� ���� ������� � ���� � �������� ���
    isDestroying : boolean = false;
    PacketsNames, PacketsFromS, PacketsFromC : TStringList;
    //��� Lineage II
    SysMsgIdList,  //�� ����
    ItemsList, 
    NpcIdList, 
    ClassIdList, 
    AugmentList, 
    SkillList : TStringList;
    //��� Aion
    SysMsgIdListAion, 
    ItemsListAion, 
    ClassIdListAion, 
    ClientStringsAion, 
    SkillListAion : TStringList; //� �� ���� - ������������ fPacketFilter

    GlobalRawAllowed : boolean; //���������� ��������� �� ����������� ���������� ������ ��� ������ ����������
    Options, PacketsINI : TMemIniFile;

implementation

uses uMainReplacer, uMain, uFilterForm, forms, udata, usocketengine, ulogform;

function GetModifTime(const FileName : string) : TDateTime;
var
  h : THandle;
  Info1, Info2, Info3 : TFileTime;
  SysTimeStruct : SYSTEMTIME;
  TimeZoneInfo : TTimeZoneInformation;
  Bias : Double;
begin
  Result := 0;
  Bias := 0;
  if not FileExists(FileName) then exit;
  h := FileOpen(FileName, fmOpenRead or fmShareDenyNone);
  if h > 0 then
  begin
    try
      if GetTimeZoneInformation(TimeZoneInfo) <> $FFFFFFFF then
        Bias := TimeZoneInfo.Bias / 1440; // 60x24
      GetFileTime(h, @Info1, @Info2, @Info3);
      if FileTimeToSystemTime(Info3, SysTimeStruct) then
        result := SystemTimeToDateTime(SysTimeStruct) - Bias;
    finally
      FileClose(h);
    end;
  end;
end;

procedure savepos(Control : TControl);
var
  ini : Tinifile;
begin
  ini := TIniFile.Create(AppPath+'settings\windows.ini');
  ini.WriteInteger(Control.ClassName, 'top', Control.Top);
  ini.WriteInteger(Control.ClassName, 'left', Control.Left);
  ini.WriteInteger(Control.ClassName, 'width', Control.Width);
  ini.WriteInteger(Control.ClassName, 'height', Control.Height);
  ini.Destroy;
end;

procedure loadpos(Control : TControl);
var
  ini : Tinifile;
begin
  if not FileExists(AppPath+'settings\windows.ini') then exit;
  ini := TIniFile.Create(AppPath+'settings\windows.ini');
  if not ini.SectionExists(Control.ClassName) then
  begin
    ini.Destroy;
    exit;
  end;
  if(ini.ReadInteger(Control.ClassName, 'width', control.Width) -
     ini.ReadInteger(Control.ClassName, 'left', control.Left) >= screen.WorkAreaWidth)
     and
    (ini.ReadInteger(Control.ClassName, 'height', control.height) -
     ini.ReadInteger(Control.ClassName, 'top', control.Top) >= Screen.WorkAreaHeight) then
  begin
    //����� ���� ���������������...
    //�� ���������
    if TForm(Control).Visible then
    begin
      ShowWindow(TForm(Control).Handle, SW_MAXIMIZE);
    end
    else
    begin
      ShowWindow(TForm(Control).Handle, SW_MAXIMIZE);
      ShowWindow(TForm(Control).Handle, SW_HIDE);
    end;
  end
  else
  begin
    control.Top := ini.ReadInteger(Control.ClassName, 'top', control.Top);
    control.Left := ini.ReadInteger(Control.ClassName, 'left', control.Left);
    control.Width := ini.ReadInteger(Control.ClassName, 'width', control.Width);
    control.height := ini.ReadInteger(Control.ClassName, 'height', control.height);
  end;
  ini.Destroy;
end;

procedure deltemps;
var
  SearchRec : TSearchRec;
  Mask : string;
begin
  Mask := AppPath+'\*.temp';
  if FindFirst(Mask, faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) <> faDirectory then
        DeleteFile(pchar(AppPath+'\'+SearchRec.Name));
    until FindNext(SearchRec)<>0;
    SysUtils.FindClose(SearchRec);
  end;
end;

function DataPckToStrPck(var pck) : string; stdcall;
var
  tpck : packed record
    size : Word;
    id : Byte;
  end absolute pck;
begin
  SetLength(Result, tpck.size-2);
  Move(tpck.id, Result[1], Length(Result));
end;

Procedure Reload;
begin
  // ��� Lineage II
  SysMsgIdList.Clear;
  AugmentList.Clear;
  SkillList.Clear;
  ClassIdList.Clear;
  NpcIdList.Clear;
  ItemsList.Clear;
  // ��� ����
  SysMsgIdListAion.Clear;
  SkillListAion.Clear;
  ClassIdListAion.Clear;
  ClientStringsAion.Clear;
  ItemsListAion.Clear;
  //��������� ������ ������ �����
  if ((GlobalProtocolVersion<CHRONICLE4))then // ��� ���� 2.1 - 2.7
  begin  //��� ����
    if fMain.lang.Language='Eng' then
    begin   //���������� ������
      SysMsgIdListAion.LoadFromFile(AppPath+'settings\en\SysMsgidAion.ini');
      ItemsListAion.LoadFromFile(AppPath+'settings\en\ItemsIdAion.ini');
      ClassIdListAion.LoadFromFile(AppPath+'settings\en\classidAion.ini');
      SkillListAion.LoadFromFile(AppPath+'settings\en\SkillsIdAion.ini');
      ClientStringsAion.LoadFromFile(AppPath+'settings\en\ClientStringsAion.ini');
    end
    else
    begin   //������� ������
      SysMsgIdListAion.LoadFromFile(AppPath+'settings\ru\SysMsgidAion.ini');
      ItemsListAion.LoadFromFile(AppPath+'settings\ru\ItemsIdAion.ini');
      ClassIdListAion.LoadFromFile(AppPath+'settings\ru\classidAion.ini');
      SkillListAion.LoadFromFile(AppPath+'settings\ru\SkillsIdAion.ini');
      ClientStringsAion.LoadFromFile(AppPath+'settings\ru\ClientStringsAion.ini');
    end;
  end
  else  //��� Lineage II
  begin
    if fMain.lang.Language='Eng' then
    begin //���������� ������
      SysMsgIdList.LoadFromFile(AppPath+'settings\en\sysmsgid.ini');
      ItemsList.LoadFromFile(AppPath+'settings\en\itemsid.ini');
      NpcIdList.LoadFromFile(AppPath+'settings\en\npcsid.ini');
      ClassIdList.LoadFromFile(AppPath+'settings\en\classid.ini');
      SkillList.LoadFromFile(AppPath+'settings\en\skillsid.ini');
      AugmentList.LoadFromFile(AppPath+'settings\en\augmentsid.ini');
    end
    else  //������� ������
    begin
      SysMsgIdList.LoadFromFile(AppPath+'settings\ru\sysmsgid.ini');
      ItemsList.LoadFromFile(AppPath+'settings\ru\itemsid.ini');
      NpcIdList.LoadFromFile(AppPath+'settings\ru\npcsid.ini');
      ClassIdList.LoadFromFile(AppPath+'settings\ru\classid.ini');
      SkillList.LoadFromFile(AppPath+'settings\ru\skillsid.ini');
      AugmentList.LoadFromFile(AppPath+'settings\ru\augmentsid.ini');
    end;
  end;
end;

function TimeStepByteStr : string;
var
  TimeStep : TDateTime;
  TimeStepB : array [0..7] of Byte;
begin
  TimeStep := Time;
  Move(TimeStep, TimeStepB, 8);
  result := ByteArrayToHex(TimeStepB, 8);
end;

function GetNamePacket(s : string) : string;
var
  ik : Word;
begin
  // ���� ����� ����� ������
  ik := Pos(':', s);
  if ik=0 then
    Result:=s
  else
    Result := copy(s, 1, ik-1);
end;

function StringToWideString(const s : AnsiString; codePage : Word) : WideString;
var
  l : integer;
begin
  if s = '' then Result := ''
else
  begin
    l := MultiByteToWideChar(codePage, MB_PRECOMPOSED, PChar(@s[1]), -1, nil, 0);
    SetLength(Result, l - 1);
    if l > 1 then
      MultiByteToWideChar(CodePage, MB_PRECOMPOSED, PChar(@s[1]), -1, PWideChar(@Result[1]), l - 1);
  end;
end;

function StringToHex(str1, Separator : String) : String;
var
  buf : String;
  i : Integer;
begin
  buf := '';
  for i := 1 to Length(str1) do begin
    buf := buf+IntToHex(Byte(str1[i]), 2)+Separator;
  end;
  Result := buf;
end;

function SymbolEntersCount(s : string) : string;
var
  i : integer;
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    if not(s[i] in [' ', #10, #13]) then  Result := Result+s[i];
  end;
end;

//���������� HEX ������ �������� � ����� ����
function HexToString(Hex : String) : String;
var
  buf : String;
  bt : Byte;
  i : Integer;
begin
  buf := '';
  Hex := SymbolEntersCount(UpperCase(Hex));
  for i := 0 to (Length(Hex) div 2)-1 do
  begin
    bt := 0;
    if (Byte(hex[i*2+1])>$2F)and(Byte(hex[i*2+1])<$3A)then bt := Byte(hex[i*2+1])-$30;
    if (Byte(hex[i*2+1])>$40)and(Byte(hex[i*2+1])<$47)then bt := Byte(hex[i*2+1])-$37;
    if (Byte(hex[i*2+2])>$2F)and(Byte(hex[i*2+2])<$3A)then bt := bt*16+Byte(hex[i*2+2])-$30;
    if (Byte(hex[i*2+2])>$40)and(Byte(hex[i*2+2])<$47)then bt := bt*16+Byte(hex[i*2+2])-$37;
    buf := buf+char(bt);
  end;
  HexToString := buf;
end;

procedure GetProcessList(var sl : TStrings);
var
  pe : TProcessEntry32;
  ph, snap : THandle; //����������� �������� � ������
  mh : hmodule; //���������� ������
  procs : array[0..$FFF] of dword; //������ ��� �������� ������������ ���������
  count, cm : cardinal; //���������� ���������
  i : integer;
  ModName : array[0..max_path] of char; //��� ������
  tmp : string;
begin
  sl.Clear;
  if Win32Platform = VER_PLATFORM_WIN32_WINDOWS then
  begin //���� ��� Win9x
    snap := CreateToolhelp32Snapshot(th32cs_snapprocess, 0);
    if integer(snap)=-1 then
    begin
      exit;
    end
    else
    begin
      pe.dwSize := sizeof(pe);
      if Process32First(snap, pe) then
        repeat
          sl.Add(string(pe.szExeFile));
        until not Process32Next(snap, pe);
    end;
  end
  else
  begin //���� WinNT/2000/XP
    if not EnumProcesses(@procs, sizeof(procs), count) then
    begin
      exit;
    end;
    try
      for i := 0 to (count div 4) - 1 do if procs[i] <> 4 then
      begin
        EnablePrivilegeEx(INVALID_HANDLE_VALUE, 'SeDebugPrivilege');
        ph := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, false, procs[i]);
        if ph > 0 then
        begin
          EnumProcessModules(ph, @mh, 4, cm);
          GetModuleFileNameEx(ph, mh, ModName, sizeof(ModName));
          tmp := LowerCase(ExtractFileName(string(ModName)));
          sl.Add(IntToStr(procs[i])+'='+tmp);
          CloseHandle(ph);
        end;
      end;
    except
    {}
    end;
  end;
end;

procedure BalloonHint(title, msg : string);
begin
  //+++
  if not isDestroying then
    SendMessage(fMainReplacer.Handle, WM_BalloonHint, integer(msg), integer(title));
end;

procedure AddToLog (msg : String);
begin
//  if isDestroying then exit;
//  if assigned(fLog) then
//    if not isDestroying then
//      if fLog.IsExists then
//        SendMessage(fLog.Handle, WM_AddLog, integer(msg), 0);
  //+++
  if (assigned(fLog) and (not isDestroying) and (fLog.IsExists)) then
    SendMessage(fLog.Handle, WM_AddLog, integer(msg), 0);
end;

Function LoadLibraryInject(const name : string) : boolean;
var
  sFile, Size : THandle;
  ee : OFSTRUCT;
  tmp : PChar;
begin
  if pInjectDll <> nil then
  begin
    FreeMem(pInjectDll);
    AddToLog(format(rsUnLoadDllSuccessfully, [name]));
  end;
  tmp := PChar(name);
  if fileExists (tmp) then begin
    sFile := OpenFile(tmp, ee, OF_READ);
    Result := true;
    AddToLog(format(rsLoadDllSuccessfully, [name]));
    Size := GetFileSize(sFile, nil);
    GetMem(pInjectDll, Size);
    ReadFile(sFile, pInjectDll^, Size, Size, nil);
    CloseHandle(sFile);
  end
  else
  begin
    result := false;
    AddToLog(format(rsLoadDllUnSuccessful, [name]));
  end;
end;

Function LoadLibraryXor(const name : string) : boolean;
begin
  // ��������� XOR dll
  if hXorLib <> 0 then
  begin
    FreeLibrary(hXorLib);
    AddToLog(format(rsUnLoadDllSuccessfully, [name]));
  end;
  hXorLib := LoadLibrary(PChar(name));
  if hXorLib > 0 then
  begin
    AddToLog(format(rsLoadDllSuccessfully, [name]));
    result := true;
    @CreateXorIn := GetProcAddress(hXorLib, 'CreateCoding');
    @CreateXorOut := GetProcAddress(hXorLib, 'CreateCodingOut');
    if @CreateXorOut=nil then CreateXorOut := CreateXorIn;
  end
  else
  begin
    Result := false;
    AddToLog(format(rsLoadDllUnSuccessful, [name]));
  end;
end;

function WideStringToString(const ws : WideString; codePage : Word) : AnsiString;
var
  l : integer;
begin
  if ws = '' then
    Result := ''
  else
  begin
    l := WideCharToMultiByte(codePage, WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR, @ws[1], -1, nil, 0, nil, nil);
    SetLength(Result, l - 1);
    if l > 1 then
      WideCharToMultiByte(codePage,WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR,
        @ws[1], -1, @Result[1], l - 1, nil, nil);
  end;
end;

function AddDateTime : string;
begin
  result := FormatDateTime('dd.mm.yyy hh.nn.ss' , now);
end;

function AddDateTimeNormal : string;
begin
  result := FormatDateTime('dd.mm.yyy hh:nn:ss' , now);
end;

function ByteArrayToHex(str1 : array of Byte; size : Word) : String;
var
  buf : String;
  i : Integer;
begin
  buf := '';
  for i := 0 to size-1 do
  begin
    buf := buf+IntToHex(str1[i], 2);
  end;
  Result := buf;
end;

procedure FillVersion_a; //���������� ������������ ? ... � ����!
var
  ver : string;
begin
  ver := getversion;
  l2pxversion_array[0] := StrToIntDef(copy(ver, 1, pos('.', ver)-1), 0);
  delete(ver, 1, pos('.', ver));
  l2pxversion_array[1] := StrToIntDef(copy(ver, 1, pos('.', ver)-1), 0);
  delete(ver, 1, pos('.', ver));
  l2pxversion_array[2] := StrToIntDef(copy(ver, 1, pos('.', ver)-1), 0);
  delete(ver, 1, pos('.', ver));
  l2pxversion_array[3] := StrToIntDef(ver, 0);
end;

function getversion : string;
type
  LANGANDCODEPAGE = record
    wLanguage : word;
    wCodePage : word;
  end;

var
  dwHandle, cbTranslate, lenBuf : cardinal;
  sizeVers : DWord;
  lpData, langData : Pointer;
  lpTranslate : ^LANGANDCODEPAGE;
  i : Integer;
  s : string;
  buf : PChar;
begin
  result := '';
  sizeVers := GetFileVersionInfoSize(pchar(ExtractFileName(ParamStr(0))), dwHandle);
  If sizeVers = 0 then
  exit;
  GetMem(lpData, sizeVers);
  try
    ZeroMemory(lpData, sizeVers);
    GetFileVersionInfo (pchar(ExtractFileName(ParamStr(0))), 0, sizeVers, lpData);
    If not VerQueryValue (lpData, '\VarFileInfo\Translation', langData, cbTranslate) then
    exit;
    For i := 0 to (cbTranslate div sizeof(LANGANDCODEPAGE)) do
    begin
      lpTranslate := Pointer(Integer(langData) + sizeof(LANGANDCODEPAGE) * i);
      s := Format('\StringFileInfo\%.4x%.4x\FileVersion', [lpTranslate^.wLanguage, lpTranslate^.wCodePage]);
      If VerQueryValue (lpData, PChar(s), Pointer(buf), lenBuf) then
      begin
        Result := buf;
        break;
      end;
    end;
  finally
    FreeMem(lpData);
  end;
end;

Function GetPacketName(var id : byte; var subid, sub2id : word; FromServer : boolean; var pname : string; var isshow : boolean) : boolean;
var
  i : integer;
begin
  result := false; //�� ���� unknown ����� ��� �������
  isshow := true;
  //------------------------------------------------------------------------
  //�������������� ���� ������� � ������ ����������� � ������ �������
  if FromServer then
  begin
    //�� �������
    if (GlobalProtocolVersion=AION)then // ��� ���� 2.1 - 2.6
    begin
      i := PacketsFromS.IndexOfName(IntToHex(id, 2));
      if i=-1 then
        pname := 'Unknown'+IntToHex(id, 2)
      else
      begin
        pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
        isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
        result := true;
      end;
    end
    else
    begin
      if (GlobalProtocolVersion=AION27)then // ��� ���� 2.7
      begin
        //���� ������� ����������� ID
        i := PacketsFromS.IndexOfName(IntToHex(subid, 4));
        if i=-1 then
        begin
          //����� ����������� ID
          i := PacketsFromS.IndexOfName(IntToHex(id, 2));
          subid := 0; //��������, ��� ����������� ID
          if i=-1 then
          begin
            //��� ����� �� �����, ������ Unknown
            pname := 'Unknown'+IntToHex(id, 2);
          end
          else
          begin
            pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
            isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
            result := true;
          end;
        end
        else
        begin
          pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
          isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
          result := true;
        end;
      end
      else
      begin
        if (GlobalProtocolVersion>AION27)then // ��� LineageII
        begin  //server four ID packets: c(ID)h(subID)h(sub2ID)
          if (subid=$FE97) or (subid=$FE98) or (subid=$FEB7) then
          begin
            //������� ������ ������
            i := PacketsFromS.IndexOfName(IntToHex(subid, 4)+IntToHex(sub2id, 4));
            if i=-1 then
            begin
              //����������� ����� �� �������
              pname := 'Unknown'+IntToHex(subid, 4)+IntToHex(sub2id, 4);
            end
            else
            begin
              pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
              isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
              result := true;
            end;
          end
          else
          begin
            if id=$FE then //server two ID packets: c(ID)h(subID)
            begin
              //������� ������ ������
              i := PacketsFromS.IndexOfName(IntToHex(subid, 4));
              if i=-1 then
              begin
                //����������� ����� �� �������
                pname := 'Unknown'+IntToHex(subid, 4);
              end
              else
              begin
                pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
                isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
                result := true;
              end;
            end
            else  //server one ID packets: c(ID)
            begin
              subid := 0;
              i := PacketsFromS.IndexOfName(IntToHex(id, 2));
              if i=-1 then
                pname := 'Unknown'+IntToHex(id, 2)
              else
              begin
                pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
                isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
                result := true;
              end;
            end;
          end;
        end;
      end;
    end;
  end
  else
  begin
    //�� �������
    if (GlobalProtocolVersion=AION)then // ��� ���� 2.1 - 2.6
    begin
      i := PacketsFromC.IndexOfName(IntToHex(id, 2));
      if i=-1 then
      begin
        pname := 'Unknown'+IntToHex(id, 2);
      end
      else
      begin
        pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
        isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
        result := true;
      end;
    end
    else
    begin
      if (GlobalProtocolVersion=AION27)then // ��� ���� 2.7
      begin
        //���� ������� ����������� ID
        i := PacketsFromC.IndexOfName(IntToHex(subid, 4));
        if i=-1 then
        begin
          //����� ����������� ID
          i := PacketsFromC.IndexOfName(IntToHex(id, 2));
          subid := 0; //��������, ��� ����������� ID
          if i=-1 then
          begin
            //��� ����� �� �����, ������ Unknown
            pname := 'Unknown'+IntToHex(id, 2);
          end
          else
          begin
            pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
            isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
            result := true;
          end;
        end
        else
        begin
          pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
          isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
          result := true;
        end;
      end
      else
      begin
        if (GlobalProtocolVersion<GRACIA) then begin
          //������ ����� 39 ��� ������ C4-C5-Interlude
          if (id in [$39, $D0]) then
            begin
              i := PacketsFromC.IndexOfName(IntToHex(subid, 4));
              if i=-1 then
                pname := 'Unknown'+IntToHex(subid, 4)
              else
              begin
                pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
                isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
                result := true;
              end;
            end
          else
          begin
            i := PacketsFromC.IndexOfName(IntToHex(id, 2));
            if i=-1 then
            begin
              pname := 'Unknown'+IntToHex(id, 2);
              end
            else
            begin
              pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
              isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
              result := true;
            end;
          end;
        end
        else    // Lineage II ��� ������ �� Gracia � ����
        begin  //client three ID packets: c(ID)h(subID)
          if (id=$D0) and (((subid>=$5100) and (subid<=$5105)) or (subid=$5A00)) then
          begin
            //������� ������ ������
            i := PacketsFromC.IndexOfName(IntToHex(id, 2)+IntToHex(sub2id, 4));
            if i=-1 then
            begin
              //����������� ����� �� �������
              pname := 'Unknown'+IntToHex(id, 2)+IntToHex(sub2id, 4);
            end
            else
            begin
              pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
              isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
              result := true;
            end;
          end
          else
          begin
            if (id=$D0) then
            begin
              i := PacketsFromC.IndexOfName(IntToHex(subid, 4));
              if i=-1 then
                pname := 'Unknown'+IntToHex(subid, 4)
              else
              begin
                pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
                isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
                result := true;
              end;
            end
            else
            begin
              subid := 0;
              i := PacketsFromC.IndexOfName(IntToHex(id, 2));
              if i=-1 then
                pname := 'Unknown'+IntToHex(id, 2)
              else
              begin
                pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
                isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
                result := true;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

end.
