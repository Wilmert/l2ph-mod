unit LSPStructures;
interface
uses windows, JwaWinsock2;

const
  //� ��� ��� ����������... -)
  Apendix = '{27-06-22-78-28-31-94-8-30-50}';
  Mutexname = 'm' + Apendix;

  //������
  Action_client_connect = 1;
  Action_client_recv = 2;
  Action_client_send = 3;
  Action_client_disconnect = 4;
  Action_sendtoServer = 5;
  Action_sendtoClient = 6;
  Action_closesocket = 7;

  //�������
  WM_action = $04F1;               

type

  //������.
  Tbuffer = array [0..$FFFF] of Byte;

  PShareMapMain = ^TShareMapMain;
  //�������� ����� ���������
  TShareMapMain = record
    ReciverHandle : Thandle;  //���� - ����� ������ ���������
    ProcessesForHook : string[100];  //���� - �� �������� � ������� ����� ������������� �������.
  end;

  TSendRecvStruct = packed record
      exists:boolean;
      SockNum : integer;
      CurrentBuff: Tbuffer;
      CurrentSize : Word;
    end;

  TDisconnectStruct = packed record
      exists:boolean;
      SockNum : integer;
      lpErrno : integer;
    end;


  //����� ������� ������
  PTmemoryBuffer = ^TMemoryBuffer;

  TConnectStruct = packed record
    Exists:boolean;
    application:string[255]; //��� �� ����������
    pid: Cardinal; //pid ��������
    SockNum : integer;
    ip : string[15];  //���� ���������� �����
    port : Cardinal;  //�� ����� ����
    HookIt : boolean;
    reddirect:boolean;
    ReciverHandle : thandle;
    /////////////////
    MemBuf : PTmemoryBuffer;
    MemBufHandle : THandle;
  end;


  TMemoryBuffer = packed record
    ConnectStruct : TConnectStruct;
    DisconnectStruct: TDisconnectStruct;
    SendStruct, SendProcessed,
    RecvStruct, RecvProcessed,
    SendRecv : TSendRecvStruct;
  end;


  TClient = class(tobject)
      canWork:boolean;
      MemBuf : PTmemoryBuffer;
      MemBufHandle : THandle;
    /////////////////////////////
      SockNum : Integer;  //�����
      ControlHandle : thandle;
      InRecv, inSend : boolean;
    end;

  TshareMain = record
      MapData : PShareMapMain; //���������
      MapHandle : THandle; //������. -)
    end;
 
implementation

end.
