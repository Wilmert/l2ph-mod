unit usocketengine;

interface

uses
    uResourceStrings,
    forms,
    uencdec,
    Windows,
    SysUtils,
    WinSock,
    usharedstructs,
    classes,
    uVisualContainer,
    ComCtrls,
    SyncObjs,
    uMainReplacer;

const
    WSA_VER = $202;

type

    Ttunel = class (TObject)
        initserversocket,              //������������������ ��������� �����
        serversocket,              //��������� �����
        clientsocket : integer;    //����������
        curSockEngine : TObject;   //�������� ������ ��������� ���� ������ (��� �������� ����� �� ��������)
        ConnectOrErrorEvent : cardinal;   //����� ����������� ��� ���������� ����������� ������
        hServerThread, hClientThread : integer;  //������ �������
        idServerThread, idClientThread : longword;  //threadid �������
        sLastMessage : string;
        tempfilename : string;
    private
    public
        active : boolean;
        isRawAllowed : boolean;
        RawLog : TFileStream;
        Visual : TfVisual;
        NeedDeinit : boolean;
        AssignedTabSheet : TTabSheet;
        TunelWork : boolean;
        noFreeAfterDisconnect : boolean; //�� ����� ������������ ������ ��� ����������
        noFreeOnServerDisconnect : boolean; //��� ���������� ������� ����� ������������������ ��������� �������
        noFreeOnClientDisconnect : boolean; //� ��������
        MustBeDestroyed : boolean;
        CharName : string;
        EncDec : TEncDec;
        procedure AddToRawLog(dirrection : byte; var data; size : word);
        procedure EncryptAndSend(Packet : Tpacket; ToServer : boolean);
        procedure SendNewAction(action : byte);
        procedure NewAction(action : byte; Caller : TObject);
        procedure NewPacket(var Packet : tpacket; FromServer : boolean; Caller : TObject);
    published
        constructor create(SockEngine : TObject);
        procedure RUN;
        destructor Destroy; override;
    end;

    TSocketEngine = class (TObject)
        sLastMessage : string;
        tunels : TList;
    private
        WSA : TWSAData;
        hServerListenThread : integer;
        idServerListenThread : cardinal;
        ServerListenSock : integer;
        procedure sendNewAction(Action : integer);
        procedure NewAction(action : byte; Caller : TObject);
        procedure sendMSG(MSG : string);

        function WaitClient(var hSocket, NewSocket : TSocket) : boolean;
        function WaitForData(Socket : TSocket; Timeout : longint) : boolean;
        procedure DeInitSocket(var hSocket : integer; const ExitCode : integer);
        function InitSocket(var hSocket : TSocket; Port : word; IP : string) : boolean;
        function AuthSocks5(var sock : integer; var srvIP : integer; var srvPort : word) : boolean;
        function GetSocketData(Socket : TSocket; var Data; const Size : word) : boolean;
        function ConnectToServer(var hSocket : TSocket; Port : word; IP : integer) : boolean;

    public
   //���������� ����� Init
        ServerPort : word;
        donotdecryptnextconnection : boolean;
   //����� ������ � ������ ������
        isSocks5 : boolean;
        RedirrectIP : integer;
        RedirrectPort : word;
   //���������� ���� ���� ���� ����������
        isServerTerminating : boolean;
    published
        procedure destroyDeadTunels;
        constructor create; //�������� � �������������
        procedure StartServer; //������, �������� ����� ������� � ��������� ���� ��������
        destructor Destroy; override; //�� ������� �������� ��� ��������� ���������� Ttunel
    end;


procedure ClientBody(thisTunel : Ttunel);
procedure ServerBody(thisTunel : Ttunel);
procedure showpacket(str : string; packet : TPacket);
function AuthOnSocks5(var socket : integer; Sock5Host : string; Socks5Port : cardinal; RedirrectIP : integer; RedirrectPort : word; Socks5NeedAuth : boolean; Socks5AuthUsername, Socks5AuthPwd : string) : integer;

implementation

uses
    uglobalfuncs,
    umain,
    Math;

{ TSocketEngine }
procedure TSocketEngine.DeInitSocket;
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
  // ���� ���� ������ - ������� ��
    if (ExitCode <> 0) and (ExitCode <> 5) and (ExitCode <> 6) then
    begin
        if hsocket >= 0 then
        begin
            SendMSG(format(rsTsocketEngineSocketError, [hsocket, ExitCode, SysErrorMessage(ExitCode)]));
        end;
    end;
  // ��������� �����
    if hSocket <> INVALID_SOCKET then
    begin
        closesocket(hSocket);
    end;
    hSocket := -1;
end;


procedure showpacket(str : string; packet : TPacket);
begin
    OutputDebugString(pchar(str + ByteArrayToHex(packet.PacketAsByteArray, packet.Size)));
    ;
end;

procedure ServerListen(CurrentEngine : TSocketEngine);
var
    NewSocket : TSocket;
    NewTunel : Ttunel;
begin
    with CurrentEngine do
    begin

        if not InitSocket(ServerListenSock, ServerPort, '0.0.0.0') then
        begin
            sendMSG(format(rsFailedLocalServer, [ServerPort]));
            exit;
        end;
        sendMSG(format(rsStartLocalServer, [ServerPort]));

        while WaitClient(ServerListenSock, NewSocket) do
        begin
            sendMSG(rsSocketEngineNewConnection);
      //����� ���������� �� ��������� �����. ������� ������.
            NewTunel := Ttunel.create(CurrentEngine);
            NewTunel.serversocket := NewSocket; //���� ���������� ������ = ��� �����������
            NewTunel.initserversocket := NewSocket; //���� ���������� ������ = ��� �����������
            NewTunel.CharName := '[Proxy]#' + IntToStr(NewSocket);
            NewTunel.RUN; //� ��������� ���
        end;
    end;
end;

procedure ServerBody(thisTunel : Ttunel);
var
    StackAccumulator : TCharArrayEx;
    PreAccumulator : TCharArray;
    AccumulatorLen : cardinal;
    BytesInStack : longint;
    curPacket : TPacket;
    RecvBytes : int64;
    PreSize, LastResult : word;
    EventTimeout : boolean;
    IP : integer;
    IPb : array[0..3] of byte absolute ip;
begin

    with TSocketEngine(thisTunel.curSockEngine) do
    begin
  //����������� �� ������, ������ �������� ����� ����������
        if isSocks5 then
        begin
            if not AuthSocks5(thisTunel.serversocket, RedirrectIP, RedirrectPort) then
            begin
                Exit;
            end;
        end;

        thisTunel.ConnectOrErrorEvent := CreateEvent(nil, true, false, pchar('ConnectOrErrorEvent' +
            IntToStr(thisTunel.hServerThread)));
  //����� � ��������� �� ������
        thisTunel.hClientThread := BeginThread(nil, 0, @ClientBody, thisTunel, 0, thisTunel.idClientThread);

        thisTunel.SendNewAction(Ttunel_Action_connect_server);

        EventTimeout := (WaitForSingleObject(thisTunel.ConnectOrErrorEvent, 30000) <> 0);
        if (EventTimeout) or (not thisTunel.TunelWork) then
        begin
            CloseHandle(thisTunel.ConnectOrErrorEvent);
            thisTunel.MustBeDestroyed := true; //������ ���� ������������ � ��� ��� ���� ������ �� �����.
            thisTunel.TunelWork := false;
            AddToLog(Format(rsTunelTimeout, [integer(pointer(thisTunel))]));

            DeinitSocket(thisTunel.serversocket, WSAGetLastError);
            TerminateThread(thisTunel.hServerThread, 0);
        end;


        CloseHandle(thisTunel.ConnectOrErrorEvent);

        ip := RedirrectIP;
        if GlobalSettings.UseSocks5Chain then
        begin
            AddToLog(Format(rsTunelConnectedProxyUse, [integer(pointer(thisTunel)), thisTunel.initserversocket, thisTunel.clientsocket, IntToStr(IPb[0]) + '.' + IntToStr(IPb[1]) + '.' + IntToStr(IPb[2]) + '.' + IntToStr(IPb[3]), ntohs(RedirrectPort)]));
        end
        else
        begin
            AddToLog(Format(rsTunelConnected, [integer(pointer(thisTunel)), thisTunel.initserversocket, thisTunel.clientsocket, IntToStr(IPb[0]) + '.' + IntToStr(IPb[1]) + '.' + IntToStr(IPb[2]) + '.' + IntToStr(IPb[3]), ntohs(RedirrectPort)]));
        end;
  //////////////////////////////////////////////////////////////
        AccumulatorLen := 0;
        LastResult := 1;
        FillChar(PreAccumulator[0], $ffff, 0);

        while (thisTunel.serversocket <> -1) do
        begin
            try //������ ���� �� ���������

    //������� ��� � ������ ?!
                ioctlsocket(thisTunel.serversocket, FIONREAD, BytesInStack);
                if BytesInStack = 0 then
                begin
                    BytesInStack := 1;
                end;

                RecvBytes := recv(thisTunel.serversocket, PreAccumulator[0], BytesInStack, 0);//������ 1 ���� ��� ���� ������ �����
                if RecvBytes <= 0 then
                begin
                    break;
                end
                else
                begin
                    PreSize := RecvBytes;
                end;

                LastResult := PreSize;

                if lastresult = 1 then
                begin
                    ioctlsocket(thisTunel.serversocket, FIONREAD, BytesInStack);
                    if BytesInStack > $FFFE then
                    begin
                        BytesInStack := $FFFE;
                    end; //� ���������� ������� - �� ����� ��� �� ��� ����� ������� �� ���.
                    if BytesInStack > 0 then
                    begin//����������
                        RecvBytes := recv(thisTunel.serversocket, PreAccumulator[presize], BytesInStack, 0);
                        if RecvBytes <= 0 then
                        begin
                            break;
                        end
                        else
                        begin
                            LastResult := LastResult + RecvBytes;
                        end;
                    end;
                end;

                if LastResult > 0 then
                begin
                    thisTunel.AddToRawLog(PCK_GS_ToServer, Preaccumulator[0], LastResult);

                    if not thisTunel.EncDec.Settings.isNoProcessToServer then
                    begin
                        thisTunel.EncDec.xorC.PreDecrypt(Preaccumulator, LastResult);
                    end;

                    Move(PreAccumulator[0], StackAccumulator[AccumulatorLen], LastResult);
                    FillChar(PreAccumulator[0], $ffff, 0);
                    inc(AccumulatorLen, LastResult);

                    if not thisTunel.EncDec.Settings.isNoProcessToServer then
                    begin
                        if AccumulatorLen >= 2 then
                        begin //� ����������� ������ �� 2+ ��������
                            try
            //������ �����
                                move(StackAccumulator[0], curPacket.PacketAsByteArray[0], $ffff);
            //������ �� � ����������� ������ ��� ������ ?
                                while (AccumulatorLen >= curPacket.Size) and (AccumulatorLen >= 2) and (curPacket.Size >= 2) do
                                begin
                  //������� � ��������� ����� �����������
                                    move(StackAccumulator[curPacket.Size], StackAccumulator[0], AccumulatorLen);
                  //�������� ������
                                    fillchar(curPacket.PacketAsCharArray[curPacket.Size], AccumulatorLen - curPacket.Size, #0);
                  //��������� ����� � �����������
                                    dec(AccumulatorLen, curPacket.Size);
                                    if curPacket.Size > 2 then
                                    begin
                    //����������
                                        thisTunel.EncDec.DecodePacket(curPacket, PCK_GS_ToServer);

                    //���� ����� ����������� � ��������� ����� ��� ��� ���� ��
                                        if curPacket.Size >= 2 then
                                        begin
                      //��������
                                            thisTunel.EncDec.EncodePacket(CurPacket, PCK_GS_ToServer);
                      //���������
                                            Move(curPacket, PreAccumulator[0], curPacket.Size);
                                            presize := curPacket.Size;
                                            thisTunel.EncDec.xorC.PostEncrypt(PreAccumulator, PreSize);
                      //� ����������
                                            send(thisTunel.clientsocket, PreAccumulator[0], PreSize, 0);
                                        end;
                                    end;

                  //�������� �������� �����. ��� �����
                                    if AccumulatorLen >= 2 then
                                    begin
                                        move(StackAccumulator[0], curPacket.PacketAsByteArray[0], $ffff);
                                    end
                                    else
                                    begin
                                        FillChar(curPacket.PacketAsByteArray[0], $ffff, #0);
                                    end;
                                end;
                            finally
                            end;
                        end; // if AccumulatorLen >= 2 then
                    end //if not thisTunel.EncDec.Settings.isNoDecryptToServer then
                    else //�� ���� ��������. ������ ����.
                    begin
                        send(thisTunel.clientsocket, StackAccumulator[0], AccumulatorLen, 0);
                        AccumulatorLen := 0;
                    end;
                end;
            except
                break;
            end;
        end;//While LastResult <> SOCKET_ERROR do
        try
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //���� �������� ����� ��������� ������
  //����� � ���
            AddToLog(Format(rsTunelClientDisconnect, [integer(pointer(thisTunel))]));

  //���������� �������
            thisTunel.sendNewAction(Ttunel_Action_disconnect_server);

  //��������� ��������� ������ � �������
            thisTunel.Visual.ThisOneDisconnected;

  //����� � ��� (�������� �����)
            DeinitSocket(thisTunel.serversocket, WSAGetLastError);

  //�� ��������� ����� c �������� ���� �������� ������ � noFreeOnServerDisconnect
            while thisTunel.noFreeOnClientDisconnect and (thisTunel.clientsocket <> -1) do
            begin
                sleep(1);
            end;

  //���������  ������
            if thisTunel.clientsocket <> -1 then
            begin
                DeinitSocket(thisTunel.clientsocket, WSAGetLastError);
            end;
            thisTunel.TunelWork := false;

  //������ ����� ������� ������ ��������� ���� ����.
            if not thisTunel.noFreeAfterDisconnect then
            begin
                thisTunel.MustBeDestroyed := true;
            end;
        except
        end;
    end;
end;


procedure ClientBody(thisTunel : Ttunel);
var
    socks5ok : string;
    PreAccumulator : TCharArray;
    StackAccumulator : TCharArrayEx;
    AccumulatorLen : cardinal;
    BytesInStack : longint;
    curPacket : TPacket;
    PreSize, LastResult : word;
    IP : integer;
    IPb : array[0..3] of byte absolute ip;
    res : integer;
    recvbytes : int64;
begin
    with TSocketEngine(thisTunel.curSockEngine) do
    begin
        if not InitSocket(thisTunel.clientsocket, 0, '0.0.0.0') then
        begin
            EndThread(0);
        end;
        ip := RedirrectIP;

        if GlobalSettings.UseSocks5Chain then //�� ���������� ������������ 0_�!
        begin
            AddToLog(Format(rsTunelConnecting, [integer(pointer(thisTunel)), thisTunel.serversocket, thisTunel.clientsocket, GlobalSettings.Socks5Host, GlobalSettings.Socks5Port]));
            res := AuthOnSocks5(thisTunel.clientsocket, GlobalSettings.Socks5Host, GlobalSettings.Socks5Port, RedirrectIP, RedirrectPort, GlobalSettings.Socks5NeedAuth, GlobalSettings.Socks5AuthUsername, GlobalSettings.Socks5AuthPwd);
            if res > 0 then
            begin
        //���������
                case res of
                    1 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs101]));
                    end;
                    2 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs102]));
                    end;
                    3 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs103]));
                    end;
                    4 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs104]));
                    end;
                    5 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs105]));
                    end;
                    6 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs106]));
                    end;
                    7 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs107]));
                    end;
                    8 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs108]));
                    end;
                    9 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs109]));
                    end;
                    10 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs110]));
                    end;
                    11 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs111]));
                    end;
                    12 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs112]));
                    end;
                    13 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs113]));
                    end;
                    14 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs114]));
                    end;
                    15 :
                    begin
                        AddToLog(format(rsTunel, [integer(pointer(thisTunel)), rs115]));
                    end;
                end;
                DeInitSocket(thisTunel.clientsocket, WSAGetLastError);
                SetEvent(thisTunel.ConnectOrErrorEvent); //��������� ��������� � ����� � ����������
                EndThread(0);
            end;
        end
        else //�� �� ���������� ������. ������� ��������.
        if not ConnectToServer(thisTunel.clientsocket, RedirrectPort, RedirrectIP) then
        begin
            AddToLog(Format(rsTunelConnecting, [integer(pointer(thisTunel)), thisTunel.serversocket, thisTunel.clientsocket, IntToStr(IPb[0]) + '.' + IntToStr(IPb[1]) + '.' + IntToStr(IPb[2]) + '.' + IntToStr(IPb[3]), ntohs(RedirrectPort)]));
            SetEvent(thisTunel.ConnectOrErrorEvent); //��������� ��������� � ����� � ����������
            EndThread(0);
        end;

        if isSocks5 then //�� �������� ����5 ��������. �������� ����������� �������������.
        begin
            socks5ok := #5#0#0#1#$7f#0#0#1#0#0;
            send(thisTunel.serversocket, socks5ok[1], Length(socks5ok), 0);
        end;


        thisTunel.sendNewAction(Ttunel_Action_connect_client);
        thisTunel.TunelWork := true;
        SetEvent(thisTunel.ConnectOrErrorEvent); //��������� ��������� � ����� � ����������
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        AccumulatorLen := 0;
        LastResult := 1;

        while (thisTunel.clientsocket <> -1) do
        begin //������ ���� �� ���������

    //������� ��� � ������ ?!
            ioctlsocket(thisTunel.clientsocket, FIONREAD, BytesInStack);
            if BytesInStack = 0 then
            begin
                BytesInStack := 1;
            end;

            RecvBytes := recv(thisTunel.clientsocket, PreAccumulator[0], BytesInStack, 0);//������ 1 ���� ��� ���� ������ �����
            if RecvBytes <= 0 then
            begin
                break;
            end
            else
            begin
                PreSize := RecvBytes;
            end;


            LastResult := PreSize;

            if lastresult = 1 then //�� ����� ������. ������� ��� 1 ����. ����������.
            begin
                ioctlsocket(thisTunel.clientsocket, FIONREAD, BytesInStack);
                if BytesInStack > $FFFE then
                begin
                    BytesInStack := $FFFE;
                end; //� ���������� ������� - �� ����� ��� �� ��� ����� ������� �� ���.
                if BytesInStack > 0 then //����������
                begin
                    RecvBytes := recv(thisTunel.clientsocket, PreAccumulator[presize], BytesInStack, 0);
                    if RecvBytes <= 0 then
                    begin
                        break;
                    end
                    else
                    begin
                        LastResult := LastResult + RecvBytes;
                    end;
                end;
            end;


            if LastResult > 0 then
            begin
                thisTunel.AddToRawLog(PCK_GS_ToClient, Preaccumulator[0], LastResult);

                if not thisTunel.EncDec.Settings.isNoProcessToClient then
                begin
                    thisTunel.EncDec.xorS.PreDecrypt(Preaccumulator, LastResult);
                end;

                Move(PreAccumulator[0], StackAccumulator[AccumulatorLen], LastResult);
                FillChar(PreAccumulator[0], $ffff, 0);
                inc(AccumulatorLen, LastResult);


                if not thisTunel.EncDec.Settings.isNoProcessToClient then
                begin
                    if AccumulatorLen >= 2 then
                    begin //� ����������� ������ �� 2+ ��������
                        try
            //������ �����
                            move(StackAccumulator[0], curPacket.PacketAsByteArray[0], $ffff);
                            if curPacket.Size = 29754 then
                            begin
                                curPacket.Size := 267;
                            end;
            //������ �� � ����������� ������ ��� ������ ?
                            while (AccumulatorLen >= curPacket.Size) and (AccumulatorLen >= 2) and (curPacket.Size >= 2) do
                            begin
                  //������� � ��������� ����� �����������
                                move(StackAccumulator[curPacket.Size], StackAccumulator[0], AccumulatorLen);
                  //�������� ������
                                fillchar(curPacket.PacketAsCharArray[curPacket.Size], AccumulatorLen - curPacket.Size, #0);
                  //��������� ����� � �����������
                                dec(AccumulatorLen, curPacket.Size);
                                if curPacket.Size > 2 then
                                begin
                    //����������
                                    thisTunel.EncDec.DecodePacket(curPacket, PCK_GS_ToClient);
                    //���� ����� ����������� � ��������� ����� ��� ��� ���� ��
                                    if curPacket.Size >= 2 then
                                    begin
                      //��������
                                        thisTunel.EncDec.EncodePacket(CurPacket, PCK_GS_ToClient);
                      //���������
                                        Move(curPacket, PreAccumulator[0], curPacket.Size);
                                        presize := curPacket.Size;
                                        thisTunel.EncDec.xorS.PostEncrypt(PreAccumulator, PreSize);
                      //� ����������
                                        send(thisTunel.serversocket, PreAccumulator[0], PreSize, 0);
                                    end;
                                end;

                  //�������� �������� �����. ��� �����
                                if AccumulatorLen >= 2 then
                                begin
                                    move(StackAccumulator[0], curPacket.PacketAsByteArray[0], $ffff);
                                end
                                else
                                begin
                                    FillChar(curPacket.PacketAsByteArray[0], $ffff, #0);
                                end;
                            end;
                        finally
                        end;
                    end; // if AccumulatorLen >= 2 then
                end //if not thisTunel.EncDec.Settings.isNoDecryptToServer then
                else //�� ���� ��������. ������ ����.
                begin
                    send(thisTunel.serversocket, StackAccumulator[0], AccumulatorLen, 0);
                    AccumulatorLen := 0;
                end;
            end;
        end;//While LastResult <> SOCKET_ERROR do
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //���� �������� ����� ��������� ������

  //����� � ���
        AddToLog(Format(rsTunelServerDisconnect, [integer(pointer(thisTunel))]));

  //���������� �������
        thisTunel.sendNewAction(Ttunel_Action_disconnect_client);

  //��������� ��������� ������ � �������
        thisTunel.Visual.ThisOneDisconnected;

  //����� � ��� (�������� �����)
        DeinitSocket(thisTunel.clientsocket, WSAGetLastError);

  //�� ��������� ����� c �������� ���� �������� ������ � noFreeOnClientDisconnect
        while (thisTunel.noFreeOnServerDisconnect) and (thisTunel.serversocket <> -1) do
        begin
            sleep(1);
        end;


  //��������� ��������� �����
        if thisTunel.clientsocket <> -1 then
        begin
            DeinitSocket(thisTunel.serversocket, WSAGetLastError);
        end;
        thisTunel.TunelWork := false;

  //������ ����� ������� ������ ��������� ���� ����.
        if not thisTunel.noFreeAfterDisconnect then
        begin
            thisTunel.MustBeDestroyed := true;
        end;

    end;
end;


function TSocketEngine.initSocket(var hSocket : TSocket; Port : word; IP : string) : boolean;
var
    Addr_in : sockaddr_in;
begin
    Result := false;
  // ������� �����
    hSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if hSocket = INVALID_SOCKET then
    begin
        DeInitSocket(hSocket, WSAGetLastError);
        Exit;
    end;
    FillChar(Addr_in, SizeOf(sockaddr_in), 0);
    Addr_in.sin_family := AF_INET;
  // ��������� �� ����� ����������� ����� �������
    Addr_in.sin_addr.s_addr := inet_addr(pchar(IP));
    Addr_in.sin_port := HToNS(Port);
  // ��������� ����� � ��������� �������
    if bind(hSocket, Addr_in, SizeOf(sockaddr_in)) <> 0 then  //������, ���� ������ ����
    begin
        DeInitSocket(hSocket, WSAGetLastError);
        Exit;
    end;
    Result := true;
end;

constructor TSocketEngine.create;
begin
    isSocks5 := false;
    donotdecryptnextconnection := false;
    isServerTerminating := false;
    tunels := TList.Create;
end;

destructor TSocketEngine.destroy;
begin
    SuspendThread(hServerListenThread);
    while tunels.Count > 0 do
    begin
        Ttunel(tunels.Items[0]).Destroy;
    end;
    tunels.Destroy;
    TerminateThread(hServerListenThread, 0);
    WSACleanup;
    inherited;
end;


procedure TSocketEngine.StartServer;
begin
    if not (WSAStartup(WSA_VER, WSA) = NOERROR) then
    begin
        sendMSG(Format(rsTsocketEngineError, [SysErrorMessage(WSAGetLastError)]));
        exit;
    end;

    hServerListenThread := BeginThread(nil, 0, @ServerListen, self, 0, idServerListenThread);
    ResumeThread(hServerListenThread);
end;

procedure TSocketEngine.sendNewAction(Action : integer);
begin
    NewAction(action, Self);
end;

procedure TSocketEngine.sendMSG(MSG : string);
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    sLastMessage := MSG;
    sendNewAction(TSocketEngine_Action_MSG);
end;

function TSocketEngine.WaitClient(var hSocket, NewSocket : TSocket) : boolean;
var
    Addr_in : sockaddr_in;
    AddrSize : integer;
begin
    Result := false;
    if listen(hSocket, 1) <> 0 then
    begin
        DeInitSocket(hSocket, WSAGetLastError);
        Exit;
    end;
    FillChar(Addr_in, SizeOf(sockaddr_in), 0);
    Addr_in.sin_family := AF_INET;
    Addr_in.sin_addr.s_addr := inet_addr(pchar('0.0.0.0'));
    Addr_in.sin_port := HToNS(0);
    AddrSize := SizeOf(Addr_in);
    while not isServerTerminating do
    begin
        if WaitForData(hSocket, 5000) then
        begin
            NewSocket := accept(hSocket, @Addr_in, @AddrSize);
            break;
        end;
    end;
    if NewSocket > 0 then
    begin
        Result := true;
    end;
    if not Result then
    begin
        DeInitSocket(hSocket, WSAGetLastError);
        DeInitSocket(NewSocket, WSAGetLastError);
    end;
end;

function TSocketEngine.WaitForData(Socket : TSocket; Timeout : integer) : boolean;
var
    FDSet : TFDSet;
    TimeVal : TTimeVal;
begin
    TimeVal.tv_sec := Timeout div 1000;
    TimeVal.tv_usec := (Timeout mod 1000) * 1000;
    FD_ZERO(FDSet);
    FD_SET(Socket, FDSet);
    Result := select(0, @FDSet, nil, nil, @TimeVal) > 0;
end;

function TSocketEngine.AuthSocks5(var sock : integer; var srvIP : integer; var srvPort : word) : boolean;
var
    buf : string;
    i : integer;
    authOk : boolean;
    p : PHostEnt;
begin
    Result := false;
  // �������� ������ ������ � ���������� �������������� ������� �����������
    SetLength(buf, 2);
    if (not GetSocketData(sock, buf[1], 2)) or (buf[1] <> #5) then
    begin
        DeInitSocket(sock, WSAGetLastError);
        Exit;
    end;

  // �������� �������������� �������� ������ �����������
    SetLength(buf, 2 + byte(buf[2]));
    if (not GetSocketData(sock, buf[3], byte(buf[2]))) then
    begin
        DeInitSocket(sock, WSAGetLastError);
        Exit;
    end;
    authOk := false;
    for i := 3 to Length(buf) do
    begin
        if buf[i] = #0 then
        begin
            authOk := true;
        end;
    end;

    if not authOk then
    begin
        DeInitSocket(sock, WSAGetLastError);
        Exit;
    end;

  // ������� ��� ����������� �� ���������
    buf := #5#0;
    send(sock, buf[1], 2, 0);

  // �������� ������ �� �����������
    SetLength(buf, 4);
    if (not GetSocketData(sock, buf[1], 4)) or (buf[1] <> #5) // ��������� ������ ���������
        or (buf[2] <> #1) // ��������� ������� CMD = CONNECT
    then
    begin
        DeInitSocket(sock, WSAGetLastError);
        Exit;
    end;

    if (buf[4] = #1) then
    begin          // ���� ������� �� IP
        GetSocketData(sock, srvIP, 4);
        GetSocketData(sock, srvPort, 2);
        Result := true;
    end
    else
    if (buf[4] = #3) then
    begin // ���� �� ��������� �����
        i := 0;
        GetSocketData(sock, i, 1);
        SetLength(buf, i);
        GetSocketData(sock, buf[1], i);
        GetSocketData(sock, srvPort, 2);
        p := GetHostByName(pchar(buf));
        srvIP := PInAddr(p.h_addr_list^)^.S_addr;
        Result := true;
    end;
end;

function TSocketEngine.GetSocketData(Socket : TSocket; var Data; const Size : word) : boolean;
var
    Position : word;
    Len : integer;
    DataB : array[0..$FFFF] of byte absolute Data;
begin
    Result := false;
    Position := 0;
    while Position < Size do
    begin
        Len := recv(Socket, DataB[Position], 1, 0);
        if Len <= 0 then
        begin
            Exit;
        end;
        Inc(Position, Len);
    end;
    Result := true;
end;

function TSocketEngine.ConnectToServer(var hSocket : TSocket; Port : word; IP : integer) : boolean;
var
    Addr_in : sockaddr_in;
begin
    Result := false;
    Addr_in.sin_family := AF_INET;
    Addr_in.sin_addr.S_addr := IP;
    Addr_in.sin_port := Port;
    if connect(hSocket, Addr_in, SizeOf(Addr_in)) = 0 then
    begin
        Result := true;
    end;
    if not Result then
    begin
        DeInitSocket(hSocket, WSAGetLastError);
    end;

end;

procedure TSocketEngine.destroyDeadTunels;
var
    i : integer;
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    if not Assigned(tunels) then
    begin
        exit;
    end;
    i := 0;
    while i < tunels.Count do
    begin
        if Ttunel(tunels.Items[i]).MustBeDestroyed then
        begin
            Ttunel(tunels.Items[i]).destroy;
            break;//����� ������� �� ������. ��� � 20 ��.
        end
        else
        begin
            inc(i);
        end;
    end;
end;

procedure TSocketEngine.NewAction(Action : byte; Caller : TObject);
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    if caller <> nil then
    begin
        SendMessage(fMainReplacer.Handle, WM_NewAction, integer(action), integer(caller));
    end;
end;


function AuthOnSocks5;
type
    TaPInAddr = array [0..255] of PInAddr;
    PaPInAddr = ^TaPInAddr;
var
    PHe : PHostEnt;
    Addr_in : sockaddr_in;
    Buf : string;
begin
    result := 0;

    PHe := gethostbyname(pchar(Sock5Host));

    if PHe = nil then
    begin
        result := 1; //��� ����� �� ����������
        exit;
    end;

  //�������� ��������� (���������� � ������ ��������)

    Addr_in.sin_family := AF_INET;
    Addr_in.sin_addr.S_addr := PInAddr(PHe.h_addr_list^)^.S_addr;
    Addr_in.sin_port := htons(Socks5Port);

    if (connect(socket, Addr_in, sizeof(Addr_in))) <> 0 then
    begin
        result := 2; //�� �� ������ �������������� �� � ������ �� �����.
        exit;
    end;

  //�� ������� � �����.
  //���� ������
    if Socks5NeedAuth then
    begin
        Buf := #5#1#2;
    end
    else
    begin
        Buf := #5#1#0;
    end;

    Send(socket, Buf[1], 3, 0);
  //�������� ��������� (����������� �� ������ �������)
    if recv(socket, Buf[1], 2, 0) = 2 then
    begin

      //����� �����������
        case Buf[2] of
            #$00 :
            begin
            end; //authOK
            #$02 :
            begin
          //���������� ���� ���������� ������ � � ��� ��� ���
                if not Socks5NeedAuth then
                begin
                    result := 4; //����������� ���������.
                    exit;
                end;
          //���� �������� � ����.
                Buf := #5 + chr(length(Socks5AuthUsername)) + Socks5AuthUsername + chr(length(Socks5AuthPwd)) + Socks5AuthPwd;
                Send(socket, Buf[1], length(buf), 0);
          //� ���� ������
                if recv(socket, Buf[1], 2, 0) = 2 then
                begin
                    case buf[2] of
                        #$00 :
                        begin
                        end;//authOK
                    else
                    begin
                        result := 5; //������ � ��� ������������ �������.
                        exit;
                    end;
                    end;
                end
                else
                begin
                    result := 6; //��������� ����������� ��� � �� ������.
                    exit;
                end;
            end;
            #$FF :
            begin
                beep;
            end; //����������. ���������������� ����� �����������.
        end;


      //�� �������������� �� ��������. ���� �������.
        Buf := #05#01#00#01#$20#$20#$20#$20#$20#$20;
        Move(RedirrectIP, buf[5], 4);
        Move(RedirrectPort, buf[9], 2);
        Send(socket, Buf[1], length(buf), 0);

       //� ���� ������
        if recv(socket, Buf[1], length(buf), 0) > 0 then
        begin
            if buf[2] <> #00 then
            begin
                result := 7; //����������� ������ ��� ������� �������������� ����� �����5
                case buf[2] of
                    #$01 :
                    begin
                        result := 8;
                    end;//'������ SOCKS-�������';
                    #$02 :
                    begin
                        result := 9;
                    end;//'���������� ��������� ������� ������';
                    #$03 :
                    begin
                        result := 10;
                    end;//'���� ����������';
                    #$04 :
                    begin
                        result := 11;
                    end;//'���� ����������';
                    #$05 :
                    begin
                        result := 12;
                    end;//'����� � ����������';
                    #$06 :
                    begin
                        result := 13;
                    end;//'��������� TTL';
                    #$07 :
                    begin
                        result := 14;
                    end;//'������� �� ��������������';
                    #$08 :
                    begin
                        result := 15;
                    end;//'��� ������ �� ��������������';
                end;
                exit;
            end;
        end;

    end
    else
    begin
        result := 3; //������ ��������.
        exit;
    end;
//��������� - ������������ � ���� ����� ������ ���
end;

{ Ttunel }

constructor Ttunel.create;
begin
    active := false;
    Visual := nil;
    NeedDeinit := false;
    TSocketEngine(SockEngine).tunels.Add(self);
    isRawAllowed := GlobalRawAllowed;
    AddToLog(Format(rsTunelCreated, [integer(pointer(Self))]));
    TunelWork := false;
    noFreeOnClientDisconnect := false;
    noFreeOnServerDisconnect := false;
    MustBeDestroyed := false;
    cursockengine := SockEngine;
    EncDec := TencDec.create;
    EncDec.ParentTtunel := Self;
    EncDec.ParentLSP := nil;
    EncDec.Settings := GlobalSettings;
    EncDec.Settings.isNoDecrypt := EncDec.Settings.isNoDecrypt or TSocketEngine(SockEngine).donotdecryptnextconnection;
    EncDec.Settings.isprocesspackets := EncDec.Settings.isprocesspackets and not TSocketEngine(SockEngine).donotdecryptnextconnection;
//  EncDec.Settings.NoFreeAfterDisconnect := EncDec.Settings.NoFreeAfterDisconnect and TSocketEngine(SockEngine).donotdecryptnextconnection;
    EncDec.Settings.isNoProcessToClient := EncDec.Settings.isNoProcessToClient or TSocketEngine(SockEngine).donotdecryptnextconnection;
    EncDec.Settings.isNoProcessToServer := EncDec.Settings.isNoProcessToServer or TSocketEngine(SockEngine).donotdecryptnextconnection;
    EncDec.Settings.NoFreeAfterDisconnect := EncDec.Settings.NoFreeAfterDisconnect and not TSocketEngine(SockEngine).donotdecryptnextconnection;

    EncDec.onNewPacket := NewPacket;
    EncDec.onNewAction := NewAction;
    tempfilename := 'RAW.' + IntToStr(round(random(1000000) * 10000)) + '.temp';
    RawLog := TFileStream.Create(tempfilename, fmOpenWrite or fmCreate);
    noFreeAfterDisconnect := EncDec.Settings.NoFreeAfterDisconnect;

end;

destructor Ttunel.destroy;
var
    i : integer;
begin
    AddToLog(Format(rsTunelDestroy, [integer(pointer(Self))]));
    if assigned(curSockEngine) then
    begin
        TSocketEngine(curSockEngine).DeinitSocket(serversocket, WSAGetLastError);
    end;
    if assigned(curSockEngine) then
    begin
        TSocketEngine(curSockEngine).DeinitSocket(clientsocket, WSAGetLastError);
    end;

    if not Assigned(TSocketEngine(curSockEngine).tunels) then
    begin
        exit;
    end;
    i := 0;
    while i < TSocketEngine(curSockEngine).tunels.Count do
    begin
        if Ttunel(TSocketEngine(curSockEngine).tunels.Items[i]) = self then
        begin
            TSocketEngine(curSockEngine).tunels.Delete(i);
            break;
        end;
        inc(i);
    end;
    Visual.currenttunel := nil;
    if hServerThread <> 0 then
    begin
        TerminateThread(hServerThread, 0);
    end;
    if hClientThread <> 0 then
    begin
        TerminateThread(hClientThread, 0);
    end;
    sendNewAction(Ttulel_action_tunel_destroyed);
    if Assigned(encdec) then
    begin
        EncDec.destroy;
    end;
    RawLog.Destroy;
    DeleteFile(tempfilename);
    inherited;
end;

procedure Ttunel.NewAction(action : byte; Caller : TObject);
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    SendMessage(fMainReplacer.Handle, WM_NewAction, integer(action), integer(caller));
end;

procedure Ttunel.NewPacket(var packet : tpacket; FromServer : boolean; Caller : TObject);
var
    tmp : SendMessageParam;
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    if not assigned(caller) then
    begin
        exit;
    end;
    if ttunel(TencDec(Caller).ParentTtunel).MustBeDestroyed then
    begin
        exit;
    end;

    tmp := SendMessageParam.Create;
    tmp.packet := Packet;
    tmp.FromServer := FromServer;
    tmp.tunel := TencDec(Caller).ParentTtunel;
    tmp.Id := TencDec(Caller).Ident;
    SendMessage(fMainReplacer.Handle, WM_NewPacket, integer(@tmp), 0);
    Packet := tmp.packet;
    tmp.destroy;
end;

procedure Ttunel.RUN;
begin
  //������������� �������������, �������� ��������� �� ������, �������� �������.
    EncDec.Ident := serversocket;
    EncDec.init;
  //�������� ����� �������������� ������ � �������
    hServerThread := BeginThread(nil, 0, @ServerBody, self, 0, idServerThread);
    ResumeThread(hServerThread);
    AddToLog(Format(rsTunelRUN, [integer(pointer(Self)), EncDec.Ident]));
    sendNewAction(Ttulel_action_tunel_created);
end;

procedure Ttunel.EncryptAndSend(Packet : Tpacket; ToServer : boolean);
var
    sSendTo : TSocket;
    PreSize : word;
    PreAccumulator : TCharArray;
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    if assigned(Visual) then
    begin
        Visual.AddPacketToAcum(Packet, not ToServer, EncDec);
        Visual.processpacketfromacum;
    end;


    if ToServer then
    begin
        EncDec.EncodePacket(Packet, PCK_GS_ToServer);
    //��� ������������  
        FillChar(PreAccumulator[0], $ffff, 0);
        move(packet, PreAccumulator[0], Packet.Size);
        PreSize := Packet.Size;
    //�����������
        EncDec.xorC.PostEncrypt(PreAccumulator, PreSize);
        sSendTo := clientsocket;
    end
    else
    begin
        EncDec.EncodePacket(packet, PCK_GS_ToClient);
    //��� ������������  
        FillChar(PreAccumulator[0], $ffff, 0);
        move(packet, PreAccumulator[0], Packet.Size);
        PreSize := Packet.Size;
    //�����������  
        EncDec.xorS.PostEncrypt(PreAccumulator, PreSize);
        sSendTo := serversocket;
    end;

    if (sSendTo <> -1) and (PreSize > 0) then
    begin
        Send(sSendTo, PreAccumulator[0], PreSize, 0);
    end;
end;

procedure Ttunel.SendNewAction(action : byte);
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    NewAction(Action, self);
end;

procedure Ttunel.AddToRawLog(dirrection : byte; var data; size : word);
var
    dtime : double;
begin
    if isGlobalDestroying then
    begin
        exit;
    end;
    if not isRawAllowed then
    begin
        exit;
    end;
    RawLog.WriteBuffer(dirrection, 1);
    RawLog.WriteBuffer(size, 2);
    dtime := now;
    RawLog.WriteBuffer(dtime, 8);
    RawLog.WriteBuffer(data, size);
end;

end.
