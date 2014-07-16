 unit uencdec;

interface

uses
  uResourceStrings,
  usharedstructs,
  Classes,
  windows,
  forms,
  sysutils;

const
  KeyConst2: array[0..63] of Char = 'nKO/WctQ0AVLbpzfBkS6NevDYT8ourG5CRlmdjyJ72aswx4EPq1UgZhFMXH?3iI9';

type
  L2Xor = class(TCodingClass)
  private
    keyLen: Byte;
  public
    isAion: Boolean;
    constructor Create;
    procedure InitKey(const XorKey; Interlude: Byte = 0); override;
    procedure DecryptGP(var Data; var Size: Word); override;
    procedure EncryptGP(var Data; var Size: Word); override;
    procedure PreDecrypt(var Data; var Size: Word); override;
    procedure PostEncrypt(var Data; var Size: Word); override;
  end;


  TencDec = class (TObject)
    fonNewPacket : TNewPacket;
    fonNewAction : TNewAction;
    xorC, xorS: TCodingClass;         //����
    LastPacket:Tpacket;
  private
    isInterlude : boolean;
    SetInitXORAfterEncode : boolean; //���������� SetInitXOR � True ����� ������ EncodePacket

    pckCount: Integer;                //������� �������
    MaxLinesInPktLog : integer;
    //////////////////////////////////////////////////////////////////////////////////////////////
    CorrectXorData : TPacket;
    CorrectorData: PCorrectorData;
    
    //��������� ��� ������� �����
    Procedure Corrector(var data; const enc: Boolean = False; const FromServer: Boolean = False);

    //������ ������ �����
    //Procedure CorrectXor(Packet:Tpacket);
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    //����� �����������
    procedure sendAction(act : integer);
    Procedure ProcessRecivedPacket(var packet:tpacket); //������������ ����� (���������� ��� ����������, etc)
    public
    ParentTtunel, ParentLSP : Tobject;
    Ident : cardinal;
//    Packet: TPacket; //�������� ����� ��� ������� � ������ ������ ������������ ��������

    CharName: String;                     //��� ������������
    sLastPacket  : string;
    sLastMessage : string;

    //���������
    InitXOR : boolean;

    Settings : TEncDecSettings;
    innerXor:boolean;

    procedure DecodePacket(var Packet:Tpacket;Dirrection: byte); //������ PacketProcesor
    Procedure EncodePacket(var Packet:Tpacket;Dirrection: byte); //������ ���������

    constructor create;
    Procedure INIT; //�������������, �������� ����� �������
    destructor Destroy; override;

    published
    //������������� �������
    property onNewPacket: TNewPacket read fonNewPacket write fonNewPacket;
    property onNewAction: TNewAction read fonNewAction write fonNewAction;
  end;

implementation

uses Math, uData, uSocketEngine,   uglobalfuncs;

{ TencDec }


constructor TencDec.create;
begin
  MaxLinesInPktLog := 10000;
  innerXor := false;
  pckCount := 0;
  SetInitXORAfterEncode := false;
  isInterlude := false;
  InitXOR:=False;
  New(CorrectorData);
  CorrectorData._id_mix:=False;
end;

procedure TencDec.DecodePacket;
var
  InitXOR_copy : boolean;
  temp : word;
begin
  InitXOR_copy := InitXOR;  //���� ���.
  if (Packet.Size>2) then
  begin
  Inc(pckCount);
  
  //���������.
//  if Settings.isAionTwoId then
//    CorrectXor(Packet);

   case Dirrection of
      PCK_GS_ToClient, PCK_LS_ToClient:
      begin                       //�� ��
        //����������� 3�� ������ (�� ������)
        //����� ����� XOR �����. � 4� ������ (�� ������)
        //����� �������� ���� InitXOR ������� � ��� ���� InitXOR_copy.
//        if Settings.isAionTwoId then CorrectXor(packet);

        //���������� �������, ���� ���� ���� � �� ����� ������� "�� ������������".
        if (InitXOR_copy and (not Settings.isNoDecrypt)) then
        begin
          temp := Packet.Size - 2;
          xorS.DecryptGP(packet.data, temp);
          Packet.Size := temp + 2
        end;
        if (Packet.Size <= 2) then
            FillChar(Packet.PacketAsCharArray, $FFFF, #0) //������!
        else
          //���������� ��� ���������� � ������
          if (not Settings.isNoDecrypt) then
          begin
            if (Settings.isAION and (not InitXOR)) then
              packet.Data[0]:=(packet.Data[0] xor $EE) - $AE; //obfuscate packet id
            ProcessRecivedPacket(packet);
          end;

        LastPacket := Packet;
        if (Assigned(onNewPacket)) then
          if Packet.Size > 2 then //�� ���������� �������� ������ ������� 2 ����� (���������)
            onNewPacket(Packet, true, self);

        if (Packet.Size <= 2) then
            FillChar(Packet.PacketAsCharArray, $FFFF, #0); //������!
      end;

      PCK_GS_ToServer, PCK_LS_ToServer:
      begin
        if Packet.Size=29754 then Packet.Size:=267;
        //�������������
        if (InitXOR and (not Settings.isNoDecrypt)) then
        begin
          temp := Packet.Size - 2;
          xorC.DecryptGP(Packet.Data, temp);
          Packet.Size := temp + 2;
        end;
        //��������� ��� ������
        if (Settings.isGraciaOff and (not Settings.isNoDecrypt)) then
          Corrector(Packet.Size);
        //�������� ��������
        if Assigned(onNewPacket) then
          onNewPacket(packet, false, self);
        if Packet.Size = 0 then
            FillChar(Packet.PacketAsCharArray, $FFFF, #0);
      end;
    end;
  end;      
end;

destructor TencDec.destroy;
begin
  try
  if not innerxor then
  begin
    xorS.Destroy;
    xorC.Destroy;
  end;
  except
  //�.�. ������. ������ ��������� - �����.
  end;

  Dispose(CorrectorData);
  inherited destroy;
end;

                 
procedure TencDec.Corrector(var data; const enc,  FromServer: Boolean);
var
  buff: array[1..400] of Char absolute data;

  procedure _pseudo_srand(seed : integer);
  begin
    CorrectorData._seed := seed;
  end;

  function _pseudo_rand: integer;
  var
    a : integer;
  begin
    with CorrectorData^ do begin
      a := (Int64(_seed) * $343fd + $269EC3) and $FFFFFFFF;
      _seed := a;
      result := (_seed shr $10) and $7FFF;
    end;
  end;

  procedure _init_tables(seed: integer; _2_byte_size: integer);
  var
    i : integer;
    x : Char;
    x2: Word;
    rand_pos : integer;
    cur_pos : integer;
  begin
    with CorrectorData^ do begin
      _1_byte_table := '';
      _2_byte_table := '';

      _2_byte_table_size := _2_byte_size;

      for i := 0 to $D0 do begin
        _1_byte_table := _1_byte_table + chr(i);
      end;
      for i := 0 to _2_byte_size do begin
        _2_byte_table := _2_byte_table + chr(i) + #$0;
      end;
      _pseudo_srand(seed);
      for i := 2 to $D1 do begin
        rand_pos := (_pseudo_rand mod i) + 1;
        x := _1_byte_table[rand_pos];
        _1_byte_table[rand_pos] := _1_byte_table[i];
        _1_byte_table[i] := x;
      end;

      cur_pos := 3;
      for i := 2 to _2_byte_size+1 do begin
        rand_pos := _pseudo_rand mod i;
        x2 := PWord(@_2_byte_table[rand_pos * 2 + 1])^;
        PWord(@_2_byte_table[rand_pos * 2 + 1])^:=PWord(@_2_byte_table[cur_pos])^;
        PWord(@_2_byte_table[cur_pos])^:=x2;
        cur_pos := cur_pos + 2;
      end;
      // nlobp �� ��������� alexteam
      if GlobalProtocolVersion<FREYA then  //���� �����
      begin
        cur_pos := Pos(#$12, _1_byte_table);
        x := _1_byte_table[$13];
        _1_byte_table[$13] := #$12;
        _1_byte_table[cur_pos]:=x;

        cur_pos := Pos(#$B1, _1_byte_table);
        x := _1_byte_table[$B2];
        _1_byte_table[$B2] := #$B1;
        _1_byte_table[cur_pos]:=x;
      end
      else
      if GlobalProtocolVersion<GOD then  //����� � HighFive
      begin
        cur_pos := Pos(#$11, _1_byte_table);
        x := _1_byte_table[$12];
        _1_byte_table[$12] := #$11;
        _1_byte_table[cur_pos]:=x;

        cur_pos := Pos(#$D0, _1_byte_table);
        x := _1_byte_table[$D1];
        _1_byte_table[$D1] := #$D0;
        _1_byte_table[cur_pos]:=x;
      end
      else
      if GlobalProtocolVersion=GOD then  //GoD
      begin
        cur_pos := Pos(#$73, _1_byte_table);
        x := _1_byte_table[$74];
        _1_byte_table[$74] := #$73;
        _1_byte_table[cur_pos]:=x;

        cur_pos := Pos(#$74, _1_byte_table);
        x := _1_byte_table[$75];
        _1_byte_table[$75] := #$74;
        _1_byte_table[cur_pos]:=x;
      end;

      _id_mix := true;
    end;
  end;

  procedure _decode_ID;
  begin
    with CorrectorData^ do begin
      buff[3]:=_1_byte_table[Byte(buff[3])+1];
      if buff[3] = #$D0 then begin
        if Byte(buff[4]) > _2_byte_table_size then begin
          // error!
        end;
        buff[4]:=_2_byte_table[Byte(buff[4])*2+1];
      end;
    end;
  end;

  procedure _encode_ID;
  var
    p: integer;
  begin
    with CorrectorData^ do begin
      if buff[3] = #$D0 then begin
        p:= pos(buff[4], _2_byte_table);
        buff[4]:=Char(((p + 1) shr 1) - 1);
      end;
      p := pos(buff[3], _1_byte_table);
      buff[3]:=Char(p-1);
    end;
  end;

begin
  with CorrectorData^ do if FromServer then begin
    if _id_mix and(buff[3]=#$0b)then begin
      temp_seed:=PInteger(@buff[PWord(@buff[1])^-3])^;
      _init_tables(temp_seed,_2_byte_table_size);
    end;
    if(buff[3]=#$2e)then begin
      // nlobp �� ��������� alexteam
      if GlobalProtocolVersion<FREYA then _init_tables(PInteger(@buff[$16])^, $80) //���� �����
      else
      if GlobalProtocolVersion<GOD then _init_tables(PInteger(@buff[$16])^, $86) //�����, HighFive
      else
      if GlobalProtocolVersion=GOD then _init_tables(PInteger(@buff[$16])^, $C5) //GoD
    end;
  end else begin
    if not _id_mix and(buff[3]=#$0e)then Protocol:=PInteger(@buff[4])^;
    if _id_mix and not enc then _decode_ID;
    if _id_mix and enc then _encode_ID;
  end;
end;

procedure TencDec.INIT;
begin
  //newxor
  if @CreateXorOut = nil then
    CreateXorOut := CreateXorIn;
  //xorS, xorC - init
  if Assigned(CreateXorIn) then
  begin
    CreateXorIn(@xorS);
    innerXor := true;
  end
  else
    xorS := L2Xor.Create;
  if Assigned(CreateXorOut) then
  begin
    CreateXorOut(@xorC);
    innerXor := true;
  end
  else
    xorC := L2Xor.Create;
end;

procedure TencDec.EncodePacket;
var
  isToServer : boolean;
  CurrentCoddingClass : TCodingClass;
  NeedEncrypt : boolean;
  temp : word;
begin
  isToServer := (Dirrection = PCK_GS_ToServer) or (Dirrection = PCK_LS_ToServer); //����� ���� �� ������ ?
  if (isToServer) then //� ����������� �� ����������� �������� ���������� �����
  begin
    NeedEncrypt := (not Settings.isNoDecrypt) and InitXOR;
    CurrentCoddingClass := xorC;
  end
  else
  begin
    NeedEncrypt := (not Settings.isNoDecrypt) and InitXOR;
    if (Settings.isAION and not InitXOR and not Settings.isNoDecrypt) then
      packet.Data[0]:=(packet.Data[0] + $AE) xor $EE; //obfuscate packet id
    CurrentCoddingClass := xorS;
  end;
  if (NeedEncrypt) then
  begin
    if (isToServer and Settings.isGraciaOff) then
      Corrector(Packet.Size, True);
    temp := Packet.Size - 2;
    CurrentCoddingClass.EncryptGP(Packet.data, temp); //��������
    Packet.Size := temp + 2;
  end;
  if SetInitXORAfterEncode then
  begin
    InitXOR := true;
    SetInitXORAfterEncode := false;
  end;
  LastPacket := Packet;
end;

//procedure TencDec.CorrectXor;
//var
////  tmp: string;
//  Offset: Word;
//  TempPacket : Tpacket;
//  temp : word;
//begin
////����� ����� XOR �����.
//case pckCount of
//3:  CorrectXorData := Packet;
//4:  begin
//      TempPacket := Packet;
////      SetLength(tmp, TempPacket.Size);
////      Move(TempPacket, tmp[1], TempPacket.Size);
//      temp := TempPacket.Size-2;
//      xorS.DecryptGP(TempPacket.Data, temp);
//      TempPacket.Size := temp + 2;
//      Offset := $13 or ((TempPacket.size-7) div 295) shl 8;
//      PInteger(@TempPacket.Data[0])^:=PInteger(@TempPacket.Data[0])^ xor Offset xor PInteger(@(xorS.GKeyS[0]))^;
//      xorS.InitKey(TempPacket.Data[0],Byte(isInterlude));
//      xorC.InitKey(TempPacket.Data[0],Byte(isInterlude));
//      if (not Settings.isNoDecrypt) then
//        begin
//          temp := CorrectXorData.Size - 2;
//          xorC.DecryptGP(CorrectXorData.Data, temp);
//          CorrectXorData.Size := temp + 2;
//        end;
//      if (not Settings.isNoDecrypt) then
//        begin
//          temp := CorrectXorData.Size - 2;
//          xorC.EncryptGP(CorrectXorData.Data, temp);
//          CorrectXorData.Size := temp + 2;
//        end;
//      InitXOR:=True;
//    end;
//end;
//end;

procedure TencDec.ProcessRecivedPacket;
var
  Offset: Word;
  WStr: WideString;
begin
  if (not Settings.isAION) then
  begin  //LineageII
    case Packet.Data[0] of
      //KeyInit �� ��������� ������������
      $00: if ((not InitXOR) and (not Settings.isKamael)) then
      begin
        isInterlude:=(Packet.Size>19);
        xorC.InitKey(Packet.Data[2], Byte(isInterlude));
        xorS.InitKey(Packet.Data[2], Byte(isInterlude));
        SetInitXORAfterEncode := true;
      end;
      //CharSelected ������� � ������� �� ���
      $0B: if (Settings.isKamael) then
      begin
          Offset := 1;
          while not ((Packet.Data[Offset] = 0) and (Packet.Data[Offset + 1] = 0)) do Inc(Offset);
          SetLength(WStr, round((Offset+0.5)/2));
          Move(Packet.Data[1], WStr[1], Offset);
          CharName := WideStringToString(WStr, 1251);
          if (Settings.isGraciaOff) then
            Corrector(Packet.Size, False, True); // ������������� ����������
          //�������� ��� ����������
          sendAction(TencDec_Action_GotName);
      end;
      //CharSelected �� ��������� ������������
      $15: if (not Settings.isKamael) then
      begin //and (pckCount=7)
        Offset := 1;
        while not ((Packet.Data[Offset]=0) and (Packet.Data[Offset+1]=0)) do Inc(Offset);
        SetLength(WStr, round((Offset+0.5)/2));
        Move(Packet.Data[1], WStr[1], Offset);

        CharName := WideStringToString(WStr, 1251);
        //�������� ��� ����������
        sendAction(TencDec_Action_GotName);
      end;
      //KeyInit ������� � ������� �� ���
      $2e: if ((not InitXOR) and Settings.isKamael) then
      begin
        isInterlude := True;
        xorC.InitKey(Packet.Data[2], Byte(isInterlude));
        xorS.InitKey(Packet.Data[2], Byte(isInterlude));
        if Settings.isGraciaOff then
          Corrector(Packet.Size,False,True); // ������������� ����������
        SetInitXORAfterEncode := true;
        exit;
      end;
    end;
  end
  else
  begin  //Aion
    case Packet.Data[0] of
      // $0166=SM_KEY AION 2.7
      $66: if not InitXOR then
      begin
        xorC.InitKey(Packet.Data[5], 2);
        xorS.InitKey(Packet.Data[5], 2);
        SetInitXORAfterEncode := true;
      end;
      // $67=SM_KEY AION 2.1
      $67: if not InitXOR then
      begin
        xorC.InitKey(Packet.Data[3], 2);
        xorS.InitKey(Packet.Data[3], 2);
        SetInitXORAfterEncode := true;
      end;
      // E4=sm_l2auth_login_check Aion 2.1
      $E4: if (GlobalProtocolVersion=AION) then
      begin
        CharName := WideStringToString(PWideChar(@Packet.Data[7]), 1251);
        //�������� ��� ����������
        sendAction(TencDec_Action_GotName);
      end;
      // 01E7=sm_l2auth_login_check Aion 2.7
      $E7: if (GlobalProtocolVersion=AION27) then
      begin
        CharName := WideStringToString(PWideChar(@Packet.Data[9]), 1251);
        //�������� ��� ����������
        sendAction(TencDec_Action_GotName);
      end;
    //���� ��� ���������� �������
    else
      if (not InitXOR) then
      begin
        xorC.InitKey(Packet.Data[3], 2);
        xorS.InitKey(Packet.Data[3], 2);
        SetInitXORAfterEncode := true;
      end;
    end;
  end;
end;

procedure TencDec.sendAction(act: integer);
begin
  if assigned(onNewAction) then
    onNewAction(act, Self);
end;

{ L2Xor }
constructor L2Xor.Create;
begin
  FillChar(GKeyS[0], SizeOf(GKeyS), 0);
  FillChar(GKeyR[0], SizeOf(GKeyR), 0);
  keyLen := 0;
  isAion:=False;
end;

procedure L2Xor.DecryptGP(var Data; var Size: Word);
var
  k:integer;
  i,t:byte;
  pck:array[0..$FFFD] of Byte absolute Data;
begin
  i:=0;
  for k:=0 to size-1 do
  begin
    t:=pck[k];
    pck[k]:=t xor GKeyR[k and keyLen] xor i xor IfThen(isAion and(k>0), Byte(KeyConst2[k and 63]));
    i:=t;
  end;
  Inc(PCardinal(@GKeyR[keyLen-7])^, size);
  if (isAion and (Size>0)) then pck[0]:=(pck[0] xor $EE) - $AE; //obfuscate packet id
end;

procedure L2Xor.EncryptGP(var Data; var Size: Word);
var
  i:integer;
  k:byte;
  pck:array[0..$FFFD] of Byte absolute Data;
begin
  if (isAion and (Size>0)) then pck[0]:=(pck[0] + $AE) xor $EE; //obfuscate packet id
  k:=0;
  for i:=0 to size-1 do
  begin
    pck[i]:=pck[i] xor GKeyS[i and keyLen] xor k xor IfThen(isAion and (i>0), Byte(KeyConst2[i and 63]));
    k:=pck[i];
  end;
  Inc(PCardinal(@GKeyS[keyLen-7])^, size);
end;

procedure L2Xor.InitKey(const XorKey; Interlude: Byte);
const
  KeyConst: array[0..3] of Byte = ($A1,$6C,$54,$87);
  KeyConstInterlude: array[0..7] of Byte = ($C8,$27,$93,$01,$A1,$6C,$31,$97);
var
  key2:array[0..15] of Byte;
begin
  case Interlude of
    0:begin   //C4
      keyLen:=7;
      Move(XorKey, key2, 4);
      Move(KeyConst, key2[4], 4);
    end;
    1:begin   //Interlude - Gracia - GoD
      keyLen:=15;
      Move(XorKey, key2, 8);
      Move(KeyConstInterlude, key2[8], 8);
    end;
    2:begin   //Aion
      keyLen:=7;
      Move(XorKey, key2, 4);
      Move(KeyConst, key2[4], 4);
      PCardinal(@key2[0])^:=PCardinal(@key2[0])^ - $3ff2cc87 xor $cd92e451;
      isAion:=True;
    end;
  end;
  Move(key2, GKeyS, 16);
  Move(key2, GKeyR, 16);
  inherited;          
end;

procedure L2Xor.PostEncrypt(var Data; var Size: Word);
begin
//������ �� ������, ��� ������ ������ � �� ����.
end;

procedure L2Xor.PreDecrypt(var Data; var Size: Word);
begin
//������ �� ������, ��� ������ ������ � �� ����.
end;

end.
