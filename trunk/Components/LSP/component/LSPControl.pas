unit LSPControl;

interface

uses LSPInstalation, LSPStructures, windows, messages, sysutils, Classes, SyncObjs;

const
  LSP_Install_success = 1;
  LSP_Already_installed = 2;
  LSP_Uninstall_success = 3;
  LSP_Not_installed = 4;
  LSP_Install_error = 5;
  LSP_UnInstall_error = 6;
  LSP_Install_error_badspipath = 7;


type
  tOnSendOrRecv = procedure (const inStruct : TSendRecvStruct; var OutStruct: TSendRecvStruct) of object;
  tOnConnect = procedure (var Struct : TConnectStruct; var hook:boolean) of object;
  tOnDisconnect = procedure (var Struct : TDisconnectStruct) of object;
  tLspModuleState = procedure (state : byte) of object;

  TLSPModuleControl = class(TComponent)
  private
    fOnRecv,fOnSend: tOnSendOrRecv;
    fOnConnect:tOnConnect;
    fOnDisconnect:tOnDisconnect;
    fPathToLspModule : string;
    fLookFor:string;
    fonLspModuleState : tLspModuleState;
    fWasStarted : boolean; //true - ���� ���������� �������, ����� �����������.
    ShareClient : array[0..255] of TConnectStruct;
    ClientCount : integer;
    ShareMain : TshareMain;

    ReciverMEssageProcessThreadId: DWORD;
    ReciverMEssageProcessThreadHandle: THandle;
    ReciverWndClass:TWndClassEx; //������, ����� ������� �������� ���������� ��� ����� ���������� � ����� ������... ������ ����� ����.
    MutexHandle : THandle;

    function FindIndexBySocketNum(SocketNum : integer):integer;
    Function CreateReciverWnd: Thandle;
    Procedure addclient(Wparam:integer);
    Procedure deleteclient(Wparam:integer);
    Procedure clientsend(Wparam:integer);
    Procedure clientrecv(Wparam:integer);
    procedure setlookfor(newLookFor:string);
    function isLspinstalled:boolean;
  public
    Function SendToServer(Struct : TSendRecvStruct):boolean;
    Function SendToClient(Struct : TSendRecvStruct):boolean;
    Procedure CloseSocket(SockNum:integer);
    Procedure setlspstate(state: boolean);

  published
    property WasStarted:boolean read fWasStarted;
    property PathToLspModule:string read fPathToLspModule write fPathToLspModule;
    property isLspModuleInstalled:boolean read islspinstalled;

    property LookFor:string read fLookFor write setlookfor;
    property onLspModuleState:tLspModuleState read fonLspModuleState write fonLspModuleState;
    property onConnect:tOnConnect read fOnConnect write fOnConnect;
    property onDisconnect:tOnDisconnect read fOnDisconnect write fOnDisconnect;
    property onRecv:tOnSendOrRecv read fOnRecv write fOnRecv;
    property onSend:tOnSendOrRecv read fOnSend write fOnSend;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;


var
  this_component : TLSPModuleControl;
  cs : RTL_CRITICAL_SECTION;
  Mmsg: MSG;  //���������

procedure Register;

implementation


procedure Register;
begin
  RegisterComponents('LSP', [TLSPModuleControl]);
end;



// ��������� ��������� ���������
function WindowProc (wnd: HWND; msg: integer; wparam: WPARAM; lparam: LPARAM):LRESULT;STDCALL;

begin

  result := 0;
  case msg of
  WM_action:
  begin
    case lparam of
    Action_client_connect:
      this_component.addclient(wparam);
    Action_client_disconnect:
      this_component.deleteclient(wparam);
    Action_client_send:
      this_component.clientsend(wparam);
    Action_client_recv:
      this_component.clientrecv(wparam);
    end;

  end;
  else
    Result := DefWindowProc(wnd,msg,wparam,lparam);
  end;
end;


procedure pReciverMessageProcess;
begin
  // ���� ��������� ���������}
  while GetMessage (Mmsg,0,0,0) do
  begin
    TranslateMessage (Mmsg);
    DispatchMessage (Mmsg);
  end;
end;

Function TLSPModuleControl.CreateReciverWnd;
begin
 //��� ��� �� ������� ������.
  ReciverWndClass.cbSize := sizeof (ReciverWndClass);
  with ReciverWndClass do
  begin
    lpfnWndProc := @WindowProc;
    cbClsExtra := 0;
    cbWndExtra := 0;
    hInstance := HInstance;
    lpszMenuName := nil;
    lpszClassName := Apendix;
  end;
  RegisterClassEx (ReciverWndClass);
  // �������� ���� �� ������ ���������� ������
  result := CreateWindowEx(0, Apendix, Apendix, WS_OVERLAPPEDWINDOW,0,0,0,0,0,0,Hinstance,nil);
end;

constructor TLSPModuleControl.create;
begin
  inherited Create(AOwner);
  fWasStarted := false; //�� ��� �� ����������.
  if csDesigning in self.ComponentState then exit;
  InitializeCriticalSection(cs);
  EnterCriticalSection(cs);
  //������� ������ ��������� ���� ����� �������� ��� �������� ���������� - ��������.
  MutexHandle := CreateMutex(nil, False, Mutexname);

  If (GetLastError = ERROR_ALREADY_EXISTS) then
    begin
      //�� ��� ����������....
      LeaveCriticalSection(cs);
      MessageBox(0, '������ ��������� TLSPModuleControl ��� ����������.'#10#13+
                    '����� �������� �� ����� ���� ������.', 'TLSPModuleControl', MB_OK);
      exit;
    end;

  ClientCount := 0;//���������� ��������� ��� � ��� ���� ��������

  //������� �������.
  ShareMain.MapHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil,
        PAGE_READWRITE, 0, SizeOf(TShareMapMain), Apendix);
  if ShareMain.MapHandle = 0 then
  ShareMain.MapHandle := OpenFileMapping(PAGE_READWRITE, false, Apendix);
  ShareMain.MapData := MapViewOfFile(ShareMain.MapHandle, FILE_MAP_ALL_ACCESS,
        0, 0, SizeOf(TShareMapMain));

  if ShareMain.MapHandle = 0 then
    begin
      setlspstate(false);
      MessageBox(0, '���������� �������� ������ � ������ ������� ������.'#10#13+
                    '����������� LSP ���������� ������������� �����'#10#13+
                    '������������� ������.', 'TLSPModuleControl', MB_OK);
      exit;    
    end;
  //������� ��������.
  ShareMain.MapData^.ReciverHandle := CreateReciverWnd;

  //������� �����, ������� ����� ������������ ��������� �� ���������
  ReciverMessageProcessThreadHandle := CreateThread(nil, 0, @pReciverMessageProcess, nil, 0, ReciverMEssageProcessThreadId);
  ResumeThread(ReciverMEssageProcessThreadHandle);

  //��������� � ����� ����������� ����� �������������
  ShareMain.MapData^.ProcessesForHook := flookfor;
  fWasStarted := true; //�� ���������� �������.
  LeaveCriticalSection(cs);
  this_component := self;
end;

destructor TLSPModuleControl.destroy;
begin
  if WasStarted then
    begin
      ReleaseMutex(MutexHandle); //���� ��������. (�� ��� �� ��������).
      CloseHandle(MutexHandle);
      TerminateThread(ReciverMEssageProcessThreadHandle, 0); //������ ���� � ���������� ���������
      DestroyWindow(ShareMain.MapData^.ReciverHandle); //������� ���� ��������
      ShareMain.MapData^.ReciverHandle := 0;
      windows.UnregisterClass(apendix, HInstance);
    end;
  inherited destroy;
end;


procedure TLSPModuleControl.addclient;
var
  Membuf : PTMemoryBuffer;
  MemHandle:thandle;
begin
  memHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil,
       PAGE_READWRITE, 0, SizeOf(TMemoryBuffer), pchar(Apendix + inttostr(wparam))); { TODO : ��� ����� ���� ��������� �������� }
  Membuf := MapViewOfFile(memHandle, FILE_MAP_ALL_ACCESS,
       0, 0, SizeOf(TMemoryBuffer));
  CloseHandle(memHandle);


  Membuf^.ConnectStruct.HookIt := true;
  if assigned(onConnect) then
    onConnect(Membuf^.ConnectStruct, Membuf^.ConnectStruct.HookIt);
  //���� ������ ���� ������ ?
  if Membuf^.ConnectStruct.HookIt then
  begin
    //���� �� - ��������� � ����������� ���--�� ������� �� 1.
    //�������������
    ShareClient[ClientCount].HookIt := true; //��������� ����� -) �� ����� �����
    ShareClient[ClientCount].ReciverHandle := Membuf^.ConnectStruct.ReciverHandle;
    ShareClient[ClientCount].SockNum := Membuf^.ConnectStruct.SockNum;
    ShareClient[ClientCount].ip := Membuf^.ConnectStruct.ip;
    ShareClient[ClientCount].port := Membuf^.ConnectStruct.port;
    ShareClient[ClientCount].application := Membuf^.ConnectStruct.application;
    ShareClient[ClientCount].pid := Membuf^.ConnectStruct.pid;    //����������� ���-�� ������� �� 1.
    ShareClient[ClientCount].MemBuf := Membuf;
    ShareClient[ClientCount].MemBufHandle := MemHandle;
    Inc(ClientCount);
  end
  else //�� ���� ? �������� ������ �� �������. ����� � ��������.
  begin
    ShareClient[ClientCount].SockNum := 0;
  end;
end;

procedure TLSPModuleControl.deleteclient;
var
  i : integer;
begin
  i := 0;
  //����� ���� �� ������� ��� sockid; ��� �� ������� -)
  while (i < ClientCount) and (ShareClient[i].SockNum <> Wparam) do
    inc(i);

  if i = ClientCount then //�� ����� -)... ���������� �������.. -)
    exit;

  if assigned(onDisconnect) then
    onDisconnect(ShareClient[i].MemBuf^.DisconnectStruct);

  //������ ������� ���� ���� ������
  inc(i);

  //� �������� ��� ������������� ������.
  while i < ClientCount do
    begin
      ShareClient[i-1] := ShareClient[i];
      inc(i);
    end;


  // -1 ������������
  Dec(ClientCount);
end;

function TLSPModuleControl.FindIndexBySocketNum;
begin
  result := 0;
  //����� ���� �� ������� ��� sockid; ��� �� ������� -)
  while (result < ClientCount) and (ShareClient[result].SockNum <> SocketNum) do
    inc(result);

  if Result = ClientCount then Result := -1;

end;

procedure TLSPModuleControl.clientrecv;
var
  index : integer;
begin
  index := FindIndexBySocketNum(Wparam);
  if Assigned(onRecv) and (index >= 0) then
    onRecv(ShareClient[index].MemBuf^.RecvStruct, ShareClient[index].MemBuf^.RecvProcessed)
  else
    ShareClient[index].MemBuf^.RecvProcessed := ShareClient[index].MemBuf^.RecvStruct;
  ShareClient[index].MemBuf^.RecvStruct.CurrentSize := 0;
  fillchar(ShareClient[index].MemBuf^.RecvStruct.CurrentBuff[0], $ffff, #0);
end;

procedure TLSPModuleControl.clientsend;
var
  index : integer;
begin
  index := FindIndexBySocketNum(wparam);
  if Assigned(onSend) and (index >= 0) then
    onSend(ShareClient[index].MemBuf^.SendStruct, ShareClient[index].MemBuf^.SendProcessed)
  else
    ShareClient[index].MemBuf^.SendProcessed := ShareClient[index].MemBuf^.SendStruct;

  ShareClient[index].MemBuf^.SendStruct.CurrentSize := 0;
  fillchar(ShareClient[index].MemBuf^.SendStruct.CurrentBuff[0], $ffff, #0);
end;

//���������� ������ �� ����� ������� ������������� �������� ����� ������
function TLSPModuleControl.SendToServer;
var
  index : integer;
begin
  index := FindIndexBySocketNum(Struct.SockNum);
  Result := (index >= 0);
  if not Result then
    exit;
  ShareClient[index].MemBuf^.SendRecv := Struct; 
  SendMessage(ShareClient[index].ReciverHandle, WM_action, Struct.SockNum, Action_sendtoserver);
end;

//���������� ������ ������� ������������� �������� ����� ������
function TLSPModuleControl.SendToClient;
var
  index : integer;
begin
  index := FindIndexBySocketNum(Struct.SockNum);
  Result := (index >= 0);
  if not Result then
    exit;
  ShareClient[index].MemBuf^.SendRecv := Struct;
  SendMessage(ShareClient[index].ReciverHandle, WM_action, Struct.SockNum, Action_sendtoClient);
end;

procedure TLSPModuleControl.setlookfor(newLookFor: string);
begin
fLookFor := newLookFor;
if ShareMain.MapData <> nil then
  ShareMain.MapData^.ProcessesForHook := flookfor;
end;

function TLSPModuleControl.islspinstalled: boolean;
begin
  result := isinstalled;
end;

Procedure TLSPModuleControl.setlspstate(state: boolean);
var
  result : byte;
begin
  if state then
    result := InstallProvider(fPathToLspModule)
  else
    result := RemoveProvider;

if assigned(onLspModuleState) then
  onLspModuleState(result);

end;

procedure TLSPModuleControl.CloseSocket;
var
 index: integer;
begin
  index := FindIndexBySocketNum(SockNum);
  if index = -1 then exit;
  SendMessage(ShareClient[index].ReciverHandle, WM_action, SockNum, Action_closesocket);
end;

end.
