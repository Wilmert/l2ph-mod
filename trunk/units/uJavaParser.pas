//******************************************************************************
// ������������� ������� � ������� ���������� ������� �� *.java
// ������ 0.1 �� 03.08.2011
// (C)NLObP, 2011
//******************************************************************************
unit uJavaParser;

interface

uses
  SysUtils,
  StrUtils,
  Classes;


const
  max=20; //����� ��������� � ��������


type
  //����������
  //������ ����������
  PVariable = ^TVariable;
  TVariable = packed record
    name : string;
    value : integer;
  end;
  //������ ���������� if, else, switch, for : ���_����, �_�����_������, ������ ����� ������ {, ������ ������ ������ }
  PStatement = ^TStatement;
  TStatement = packed record
    name : string;
    line : integer;
    lineBrakeLeft : integer;
    lineBrakeRigth : integer;
  end;

  type
  PJavaParser =^TJavaParser;
  TJavaParser = class(TObject)
  private
    FIndex : integer;      //��������� �� �������
//    idx : integer;      //��������� �� ������� � ������� statement
    FCurString : string; //������� ������ ��������� ������ �� java
    FPosition : integer;   //��������� �� ������� ������ � ��������� java
    FTotal : integer;      //���-�� ����� � ����� ��������� ������ �� java
    FText : TStrings; //����� ��������� ������ �� java
    FLastPosition: Integer;
    //token
    FTknCount : integer; //���-�� ��������� �������
    FTknIndex : integer;   //��������� �� ������� �����
//    FKeywords : array[0..max] of string; //������ �������
    FKeywords : TStrings; //�������� �����
//    var
      FVars : TStringList; //����������
      FVariable : array[0..max] of TVariable; //������ ���� ����������
      FVarCount : integer; //���-�� �������������� ����������
      FVarIndex : integer;   //��������� �� ������� ����������
  //    expression : array[0..max] of string; //������ �������
  //    operand : array[0..max] of integer; //������ �������
//      FStatement : array[0..max] of TStatement; //������ �������
//      FStmtCount : integer; //���-�� �������������� �������
//      FStmtIndex : integer;   //��������� �� ������� �����
    FStack: TStringList; //����� ������ ������ ����� ��� FOR, IF, SWITCH
    FStackPointer: integer;
    FProc : TStringList; //���������
    function AllTrim(sData: string): string;
    function AllTrimEx(sData, sDelimiterLeft, sDelimiterRight: string): string;
    function ExtractAfterCharacter(sData, sFind: string): string;
    function ExtractBeforeCharacter(sData, sFind: string): string;
    function Ltrim(sData: string): string;
    function LtrimEx(sData, sDelimiter: string): string;
    function Rtrim(sData: string): string;
    function RtrimEx(sData, sDelimiter: string): string;
    function TrimEx(sData, sDelimiter: string): string;
    procedure ClearVars;
//    procedure ClearStatement;
    procedure SetPosition(const Value: Integer);
    procedure ClearText;
  public
    constructor Create;
    destructor Destroy; override;
    function GetVarValue(index: integer): integer;
    procedure SetVarValue(index, value: integer);
    function GetVarName(index: integer): string;
    procedure SetVarName(index: integer; name: string);
    function GetVarIndex(index: integer): integer;
    procedure SetVarIndex(index: integer);
    function GetVar(name: string): string;
    procedure SetVar(name, value: string);
    function GetStrIndex() : integer;
    procedure SetStrIndex(index : integer);
    function GetToken(index : integer) : string;
    procedure SetToken(index : integer; tok : string);
    procedure ClearKeywords;
    function NextString() : string;
    function GetString(index : integer) : string;
    function isalpha(ch: char): boolean;
    function isdelimiter(ch: char): boolean;
    function isdigit(ch: char): boolean;
    procedure LoadFromFile(name : string);
    function CountToken() : integer;
    function FindVar(name: string): integer;
    function CountVar: integer;
    procedure Translate(PacketName, Packet: string; size: word;
                        var offset : integer; var typ, name_, value, hexvalue : string);
    function ParseString() : boolean;
    function FindToken(tok : string) : integer;
    function GetValueFromPktStr(const typ, name_, PktStr: string;
                                var PosInPkt: integer; var hexvalue : string): string;
    { Current position }
    property Position: Integer read FPosition write SetPosition;
    { Current position }
    property Count: Integer read FTotal;
    procedure fWriteD(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
    procedure fWriteB(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
    procedure fReadD(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
    procedure fReadB(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
    procedure fByte();
//    function fBalanceIf(): boolean;
//    function fEmptyIf(brkLeft, brkRigth: integer): boolean;
    function fEmptyFor(brkLeft, brkRigth: integer): boolean;
    function fFor(var brkLeft, brkRigth, count: integer): boolean;
    procedure fPop(var brkLeft, brkRigth, count, idx: integer);
    procedure fPop1(var str: string);
    procedure fPush(brkLeft, brkRigth, count, idx: integer);
    procedure fPush1(str: string);
    function fSwitch(var brkLeft, brkRigth, count: integer): boolean;
    function fCase(var brkLeft, brkRigth, count: integer): boolean;
    function fIf(var brkLeft, brkRigth, count: integer): boolean;
    function fElse(var brkLeft, brkRigth, count: integer): boolean;
    procedure fMove();
    procedure fFindProc;
    function fProcExec(var brkLeft, brkRigth: integer): boolean;
  end;

implementation

uses
  uglobalfuncs;

  { TJavaParser }

procedure TJavaParser.SetPosition(const Value: Integer);
begin
  FPosition := Value;
  FLastPosition := Value;
end;
//******************************************************************************
//������ ����� ������
procedure TJavaParser.ClearText;
begin
  FText.Clear;
end;
//******************************************************************************
//������ ������ �������
procedure TJavaParser.ClearKeywords;
begin
  FKeywords.Clear;
end;
//******************************************************************************
//������ ������ ����������
procedure TJavaParser.ClearVars;
begin
  FVars.Clear;
end;
//******************************************************************************
function TJavaParser.CountToken: integer;
begin
  result:=FTknCount;
end;
//******************************************************************************
function TJavaParser.CountVar: integer;
begin
  result:=FVarCount;
end;
//******************************************************************************
constructor TJavaParser.Create;
begin
  FCurString:='';
  FPosition:=0;
  FVarIndex:=0;
//  FStmtIndex:=0;
  FIndex:=0;
  FVarCount:=0;
  FTknCount:=0;
//  FStmtCount:=0;
  FTotal:=0;
  FText := TStringList.Create;
  FKeywords := TStringList.Create;
//  TStringList(FKeywords).Sorted := True;
  FVars := TStringList.Create;
//  TStringList(FVars).Sorted := True;
  FStack := TStringList.Create;
  FStackPointer:=0;
  FProc := TStringList.Create;
end;
//******************************************************************************
destructor TJavaParser.Destroy;
begin
  FText.Free;
  FKeywords.Free;
  FVars.Free;
  FStack.Free;
  FProc.Free;
  inherited;
end;
//******************************************************************************
function TJavaParser.GetStrIndex: integer;
begin
  result:=FPosition;
end;
//******************************************************************************
function TJavaParser.GetString(index: integer): string;
begin
  result:=FText[index];
end;
//******************************************************************************
function TJavaParser.NextString(): string;
begin
  result:=lowercase(FText.Strings[FPosition]);
  inc(FPosition);
  if FPosition>FTotal then FPosition:=FTotal;
end;
//******************************************************************************
function TJavaParser.GetToken(index: integer): string;
begin
  result:=FKeywords[index];
end;
//******************************************************************************
procedure TJavaParser.SetVar(name, value: string);
var
  i: integer;
  s: string;
begin
  i:=FVars.IndexOfName(name);
  if length(name)>0 then
    s:=name+'='+value
  else
    s:=name+'=0';  //��������� ������ ������ ���������� ���� �������
  if  i>-1 then
    Fvars[i]:=s    //���� ��� ����, �� ���������
  else
    Fvars.Append(s);  //���������� ����� ����������
//  Fvars.SaveToFile(AppPath+'Fvars.txt');
end;
//******************************************************************************
function TJavaParser.GetVar(name: string): string;
var
  s: string;
begin
  s:=FVars.Values[name];
  if length(s)>0 then
    result := s
  else
    result:='0';
end;
//******************************************************************************
procedure TJavaParser.SetVarIndex(index: integer);
begin
  FVarIndex:=index;
  if FVarIndex>max then FVarIndex:=max;
end;
//******************************************************************************
function TJavaParser.GetVarIndex(index: integer): integer;
begin
  result:=FVarIndex;
end;
//******************************************************************************
procedure TJavaParser.SetVarName(index : integer; name : string);
begin
  FVariable[index].name := name;
end;
//******************************************************************************
procedure TJavaParser.SetVarValue(index: integer; value: integer);
begin
  FVariable[index].value := value;
end;
//******************************************************************************
function TJavaParser.GetVarName(index: integer): string;
begin
  result := FVariable[index].name;
end;
//******************************************************************************
function TJavaParser.GetVarValue(index: integer): integer;
begin
  result := FVariable[index].value;
end;
//******************************************************************************
procedure TJavaParser.SetStrIndex(index: integer);
begin
  if index<Count then  //�� ������ ��� ����� � �����
    FPosition:=index  //������������� �����. ������
  else
    FPosition:=Count-1;  //����� �� ��������� ������
end;
//******************************************************************************
procedure TJavaParser.SetToken(index: integer; tok: string);
begin

end;
//******************************************************************************
procedure TJavaParser.fWriteB(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
var
  s: string;
begin
//  if FindToken('getip') <> -1 then
//    name_:='5'
//  else
//  if (FindToken('_key') <> -1) and (GlobalProtocolVersion=INTERLUDE)then
//    name_:='8'
//  else
//  if FTknCount<=5 then
  name_:=FKeywords[FTknCount-1];
//  else
  //writeB(buf, new byte[208 - itemsDataSize]);
  if FTknCount=6 then
  begin
   //������� ������ ���������
   s:=lowercase(FText.Strings[FPosition-1]);
   //������� �� �������, ���� length() ?
   if (Pos('length', s)>0)then
      name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[5]))))
  end
  else
  begin
    //	writeS(buf, accPlData.getLegion().getLegionName());
    //	byte[] somebyte = new byte[86-(accPlData.getLegion().getLegionName().length() * 2)];
    //	writeB(buf, somebyte);
    if FTknCount>6 then
    begin
     //������� ������ ���������
     s:=lowercase(FText.Strings[FPosition-1]);
     //������� �� �������
     if ((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)then
       name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[6]))*2+2))
     else
     if ((Pos('*2', s)>0) or (Pos('* 2', s)>0)) and (Pos('length', s)>0) then
       name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[6]))*2));
    end;
  end;
  if (length(name_)>0) and (isalpha(name_[1])) then
  begin
    value:=GetVar(name_);
    name_:=value;
//    value:=GetValueFromPktStr(typ, name_, Packet, offset, hexvalue);
  end
  else
  begin
    value:=name_;
//    Inc(offset, strtoint(value));
  end;
end;
//******************************************************************************
procedure TJavaParser.fWriteD(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
var
  i, k, val: integer;
begin
  //server
  //writeC(0xc7);
  //writeD(_sList.get(i).getId());
  //writeD(_sList.size());
  name_:=FKeywords[FTknCount-1];
  if FTknCount=1 then
    name_:='unknown';     // writed()

  //writeD(_inv.getPaperdollAugmentationId(PAPERDOLL_ID));
//  if FTknCount=4 then
//      name_:=FKeywords[FTknCount-2];
  //writeH(temp.isEquipped() ? 1 : 0);
//  if FindToken('?') <> -1 then
//  begin
//      name_:=FKeywords[FindToken('?')-1]; //�� �� ��������� �������������
//  end else
  //writeD(charInfoPackage.getPaperdollItemId(PAPERDOLL_ID));
//  if FindToken('paperdoll_id') <> -1 then
//  begin
//      name_:=FKeywords[FindToken('paperdoll_id')-1]; //�� �� ��������� ������������
//  end;
  //����� �������� �� ������ ������
  value:=GetValueFromPktStr(typ, name_, Packet, offset, hexvalue);
  //��� ������
  if (FindToken('getitemsmask') <> -1) or
     (FindToken('itemsmask') <> -1)
  then
  begin
    //����������� �������� ����� � �����
    k:=StrToInt(value); // EquipmentMask
    val:=0;
    for i:=0 to 15 do val:=val+((k shr i)and 1);
    value:=inttostr(val);
  end;
  //������� ���������� � �� ���������
  for i := 0 to FTknCount - 1 do
  begin
    SetVar(FKeywords[i], value);
  end;
end;
//******************************************************************************
procedure TJavaParser.fReadD(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
var
  i, k, val: integer;
begin
  //client
  name_:=FKeywords[0];    // data=readd()
  if FTknCount=1 then
    name_:='unknown';     // readd()
//  if FTknCount>1 then
//  begin
//    //������� ������ ���������
//    s:=lowercase(FText.Strings[FPosition-1]);
//    //������� �� �������, ���� "="?
//    if (Pos('=', s)>0) or (not Pos('==', s)>0) then //
//      name_:=FKeywords[0]    //_loginName = readS(32).toLowerCase();
//    else
//                             //playerCommonData.setGender(readD() == 0 ? Gender.MALE : Gender.FEMALE);
//      name_:=FKeywords[1];   //playerAppearance.setVoice(readD());
//  end;
//  if FTknCount>2 then
//      name_:=FKeywords[1];    //playerAppearance.setSkinRGB(readD());

  //����� �������� �� ������ ������
  value:=GetValueFromPktStr(typ, name_, Packet, offset, hexvalue);
  //��� ������
  if (FindToken('getitemsmask') <> -1) or
     (FindToken('itemsmask') <> -1)
  then
  begin
    //����������� �������� ����� � �����
    k:=StrToInt(value); // EquipmentMask
    val:=0;
    for i:=0 to 15 do val:=val+((k shr i)and 1);
    value:=inttostr(val);
  end;
  //������� ���������� � �� ���������
  for i := 0 to FTknCount - 1 do
  begin
    SetVar(FKeywords[i], value);
  end;
end;
//******************************************************************************
procedure TJavaParser.fReadB(Packet: string; var offset: integer; var typ, name_, value, hexvalue: string);
var
  s: string;
begin
  //client
  //data = readB(size);
  //byte[] macAddress = readB(6);
  //readB(1);
  //readB(_data);
//  if FTknCount<=5 then
  name_:=FKeywords[FTknCount-1];
//  else
//  if FTknCount=6 then
//  begin
//   //������� ������ ���������
//   s:=lowercase(FText.Strings[FPosition-1]);
//   //������� �� �������, ���� length()
//   if (Pos('length', s)>0)then
//      name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[5]))))
//  end
//  else
//  begin
  //readB(44 - (name.length() * 2 + 2));
  //byte[] shit = readB(42 - (name.length() * 2));

  if FTknCount>=6 then
  begin
    //������� ������ ���������
    s:=lowercase(FText.Strings[FPosition-1]);
    //������� �� �������
    if ((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)then
      name_:=inttostr(strtoint(FKeywords[1])-(length(GetVar(FKeywords[3]))*2+2))
    else
      if ((Pos('*2', s)>0) or (Pos('* 2', s)>0)) and (Pos('length', s)>0) then
        name_:=inttostr(strtoint(FKeywords[1])-(length(GetVar(FKeywords[3]))*2));
  end;

  if (length(name_)>0) and (isalpha(name_[1])) then
  begin
    value:=GetVar(name_);
    name_:=value;
  end
  else
    value:=name_;
end;
//******************************************************************************
procedure TJavaParser.fPush(brkLeft, brkRigth, count, idx: integer);
begin
  FStack.Add(inttostr(brkLeft));
  FStack.Add(inttostr(brkRigth));
  FStack.Add(inttostr(count));
  FStack.Add(inttostr(idx));
//  FStack.SaveToFile(AppPath+'FStack.txt');
end;
//******************************************************************************
procedure TJavaParser.fPush1(str: string);
begin
  FStack.Add(str);
//  FStack.SaveToFile(AppPath+'FStack.txt');
end;
//******************************************************************************
procedure TJavaParser.fPop1(var str: string);
begin
  str:=FStack.Strings[FStack.Count-1];
  Fstack.Delete(FStack.Count-1);
//  FStack.SaveToFile(AppPath+'FStack.txt');
end;
//******************************************************************************
procedure TJavaParser.fPop(var brkLeft, brkRigth, count, idx: integer);
begin
  idx:=strtoint(FStack.Strings[FStack.Count-1]);
  Fstack.Delete(FStack.Count-1);
  count:=strtoint(FStack.Strings[FStack.Count-1]);
  Fstack.Delete(FStack.Count-1);
  brkRigth:=strtoint(FStack.Strings[FStack.Count-1]);
  Fstack.Delete(FStack.Count-1);
  brkLeft:=strtoint(FStack.Strings[FStack.Count-1]);
  Fstack.Delete(FStack.Count-1);
//  FStack.SaveToFile(AppPath+'FStack.txt');
end;
//******************************************************************************
function TJavaParser.fSwitch(var brkLeft, brkRigth, count: integer): boolean;
var
  idx: integer;
  isEnd: boolean;
  name: string;
begin
  name:=FKeywords[FTknCount-1];
  if FindToken('{') <> -1 then
  begin
      name:=FKeywords[FindToken('{')-1];
  end;
  if (length(name)>0) and (isalpha(name[1])) then
  begin
    count:=strtoint(GetVar(name));
  end
  else
    count:=strtoint(name);

  //���������� ������ � ����� ���� switch
  isEnd:=false;
  idx:=0;
  //����� ���������� ������
  dec(FPosition);
  while (FPosition < FTotal-1) and (not isEnd) do
  begin
    //����� ��������� ������
    ParseString();
    if FTknCount>0 then
    begin
      //�������� ���� switch
      if FindToken('switch') <> -1 then
      begin
        //� ���� �� ������ ����������� ������
        if FindToken('{') <> -1 then
        begin
          inc(idx);
          isEnd:=false;
          if idx=1 then
          begin
            brkLeft:=FPosition;
          end;
        end;
        while (FPosition < FTotal-1) and (not isEnd) do
        begin
          //����� ��������� ������
          ParseString();
          if FTknCount>0 then
          begin
            //����������� ������
            if FindToken('{') <> -1 then
            begin
              inc(idx);
              if idx=1 then
              begin
                brkLeft:=FPosition-1;
              end;
            end;
            //����������� ������
            if FindToken('}') <> -1 then
            begin
              dec(idx);
              if idx=0 then
              begin
                isEnd:=true;
                brkRigth:=FPosition-1;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  result:=true;
end;
//******************************************************************************
function TJavaParser.fCase(var brkLeft, brkRigth, count: integer): boolean;
var
  name: string;
  ccase: integer;
begin
  dec(FPosition);
  begin
    //���������� CASE �� SWITCH
    while (FPosition < FTotal-1) do
    begin
      //����� ��������� ������
      ParseString();
      if FTknCount>0 then
      begin
        if FindToken('case') <> -1 then
        begin
          //�����
          name:=FKeywords[FTknCount-1];
          if (length(name)>0) and (isalpha(name[1])) then
          begin
            ccase:=strtoint(GetVar(name));
          end
          else
            ccase:=strtoint(name);
          if ccase=count then
          begin
            //������ � CASE
            //�������� ���� ��� CASE?
            while (FPosition < FTotal-1) do
            begin
              //����� ��������� ������
              ParseString();
              if FTknCount>0 then
              begin
                if not FindToken('case') <> -1 then
                begin
                  dec(FPosition);
                  result:=false;
                  exit;
                end;
              end;
            end;
          end;
        end
        else
        begin
          //�� ������ � CASE, ���������� �� BREAK;
          dec(FPosition);
          while (FPosition < FTotal-1)do
          begin
            //����� ��������� ������
            ParseString();
            if FTknCount>0 then
            begin
              if FindToken('break') <> -1 then
              begin
                //�����
                result:=false;
                ClearKeywords; //��������
                exit;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  result:=true;
end;
//******************************************************************************
function TJavaParser.fFor(var brkLeft, brkRigth, count: integer): boolean;
var
  idx: integer;
  isEnd: boolean;
  name, s: string;
begin
  //���������� ���������� �������� �����
  if FTknCount<=5 then
  begin
    name:=FKeywords[FTknCount-1];
    if FindToken('{') <> -1 then
    begin
        name:=FKeywords[FindToken('{')-1];
    end;
  end;
  if FTknCount>=6 then
  begin
    name:=FKeywords[FTknCount-2];
    if FindToken('{') <> -1 then
    begin
        name:=FKeywords[FindToken('{')-2];
    end;
  end;
  if FTknCount>9 then
  begin
    name:=FKeywords[FTknCount-1];
   //������� ������ ���������
   s:=lowercase(FText.Strings[FPosition-1]);
   //������� �� �������
   if ((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)then
     name:=inttostr(strtoint(FKeywords[5])-(length(GetVar(FKeywords[7]))*2+2))
   else
   if ((Pos('*2', s)>0) or (Pos('* 2', s)>0)) and (Pos('length', s)>0) then
     name:=inttostr(strtoint(FKeywords[5])-(length(GetVar(FKeywords[7]))*2));
  end;

  if (length(name)>0) and (isalpha(name[1])) then
  begin
    count:=strtoint(GetVar(name));
  end
  else
    count:=strtoint(name);

  //���������� ������ � ����� ���� �����
  isEnd:=false;
  idx:=0;
  //����� ���������� ������
  dec(FPosition);
  while (FPosition < FTotal-1) and (not isEnd) do
  begin
    //����� ��������� ������
    ParseString();
    if FTknCount>0 then
    begin
      //�������� ���� for
      if FindToken('for') <> -1 then
      begin
        //� ���� �� ������ ����������� ������
        if FindToken('{') <> -1 then
        begin
          inc(idx);
          isEnd:=false;
          if idx=1 then
          begin
            brkLeft:=FPosition;
          end;
        end;
        while (FPosition < FTotal-1) and (not isEnd) do
        begin
          //����� ��������� ������
          ParseString();
          if FTknCount>0 then
          begin
            //����������� ������
            if FindToken('}') <> -1 then
            begin
              dec(idx);
              if idx=0 then
              begin
                isEnd:=true;
                brkRigth:=FPosition-1;
              end;
            end;
            //����������� ������
            if FindToken('{') <> -1 then
            begin
              inc(idx);
              if ((idx=1) and (not isEnd)) then
              begin
                brkLeft:=FPosition-1;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  result:=true;
end;
//******************************************************************************
//��������� ������������� For
function TJavaParser.fEmptyFor(brkLeft, brkRigth: integer): boolean;
var
  idx: integer;
  isFind, isEnd: boolean;
begin
  isFind:=false;
  isEnd:=false;
  idx:=0;
  FPosition:=brkLeft;    //������ � ������ �����
  dec(FPosition);
  while (FPosition < FTotal-1) and (not isEnd) do
  begin
    //����� ��������� ������
    ParseString();
    if FTknCount>0 then
    begin
      //�������� ���� for
      if FindToken('for') <> -1 then
      begin
        //� ���� �� ������ ����������� ������
        if FindToken('{') <> -1 then
        begin
          inc(idx);
          isEnd:=false;
        end;
        while (FPosition < FTotal-1) and (not isEnd) do
        begin
          //����� ��������� ������
          ParseString();
          if FTknCount>0 then
          begin
            //����������� ������
            if FindToken('}') <> -1 then
            begin
              dec(idx);
              if idx=0 then
                isEnd:=true;
            end;
            //����������� ������
            if FindToken('{') <> -1 then
            begin
              inc(idx);
              isEnd:=false;
            end;
            if
              (FindToken('writec') <> -1) or
              (FindToken('writeh') <> -1) or
              (FindToken('writed') <> -1) or
              (FindToken('writef') <> -1) or
              (FindToken('writen') <> -1) or
              (FindToken('writes') <> -1) or
              (FindToken('writeb') <> -1) or
              (FindToken('readc') <> -1) or
              (FindToken('readh') <> -1) or
              (FindToken('readd') <> -1) or
              (FindToken('readf') <> -1) or
              (FindToken('readn') <> -1) or
              (FindToken('reads') <> -1) or
              (FindToken('readb') <> -1)
            then
            begin
              isFind:=true;
            end;
          end;
        end;
      end;
    end;
  end;
  result:=not isFind;
end;
//******************************************************************************
function TJavaParser.fElse(var brkLeft, brkRigth, count: integer): boolean;
var
  idx: integer;
  isEnd: boolean;
begin
  //���������� ������ � ����� ���� �����
  isEnd:=false;
  idx:=0;
  //����� ���������� ������
  dec(FPosition);
  while (FPosition < FTotal-1) and (not isEnd) do
  begin
    //����� ��������� ������
    ParseString();
    if FTknCount>0 then
    begin
      //�������� ���� IF
      if FindToken('else') <> -1 then
      begin
        //� ���� �� ������ ����������� ������
        if FindToken('{') <> -1 then
        begin
          inc(idx);
          isEnd:=false;
          if idx=1 then
          begin
            brkLeft:=FPosition;
          end;
        end;
        while (FPosition < FTotal-1) and (not isEnd) do
        begin
          //����� ��������� ������
          ParseString();
          if FTknCount>0 then
          begin
            //����������� ������
            if FindToken('}') <> -1 then
            begin
              dec(idx);
              if idx=0 then
              begin
                isEnd:=true;
                brkRigth:=FPosition; //-1;
              end;
            end;
            //����������� ������
            if FindToken('{') <> -1 then
            begin
              inc(idx);
              if ((idx=1) and (not isEnd)) then
              begin
                brkLeft:=FPosition-1;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  result:=true;
end;
//******************************************************************************
procedure TJavaParser.fFindProc();
var
  name: string;
  tmpPosition: integer;
begin
  FProc.Clear;
  tmpPosition:=FPosition;
  //������ � ������
  FPosition:=0;
  while (FPosition < FTotal-1) do
  begin
    //����� ��������� ������
    ParseString();
    if FTknCount>0 then
    begin
      //�������� ���� ���������
      if ((FindToken('protected') <> -1) OR (FindToken('private') <> -1)) AND (FindToken('void') <> -1) then
      begin
        name:=FKeywords[FindToken('void')+1];
        FProc.Add(name+'='+inttostr(FPosition));
      end;
    end;
  end;
  FPosition:=tmpPosition;
//  FProc.SaveToFile(AppPath+'FProc.txt');
end;
//******************************************************************************
function TJavaParser.fProcExec(var brkLeft, brkRigth: integer): boolean;
var
  name, s: string;
begin
  name:=FKeywords[0];  //��� ���������
  s:=FProc.Values[FKeywords[0]]; //���� ��� ���������
  if length(s)>0 then
  begin
    result := true;
    brkLeft:=strtoint(s);
    brkRigth:=FPosition;
  end
  else
  begin
    brkRigth:=FPosition;
    brkLeft:=brkRigth;
    result:=false;
  end;
end;
//******************************************************************************
procedure TJavaParser.fMove();
var
  nameR, s: string;
  valueR, i: integer;
begin
//����������� ����� ���������� �������� ������ ����������
//        type = MovementType.getMovementTypeById(movementType);

  //������� ������ ���������
  s:=lowercase(FText.Strings[FPosition-1]);
  //������� �� �������
  if (Pos('==', s)>0) OR  (Pos('read', s)>0) OR (Pos('write', s)>0)then
  begin
    exit;
  end;
  //��������� �������� ��� VALUE
  nameR:=FKeywords[FTknCount-1];  //��������� �����
  if FTknCount>=8 then
  begin
      //������� �� �������
      if (((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)) then
        nameR:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[5]))*2+2))
      else
        if (Pos('*2', s)>0) or (Pos('* 2', s)>0) and (Pos('length', s)>0) then
           nameR:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[5]))*2));
  end
  else
  begin
    if FTknCount>=6 then
      if FindToken('int') <> -1 then
         //������� �� �������
         if ((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)then
           nameR:=inttostr(strtoint(FKeywords[2])-(length(GetVar(FKeywords[3]))*2+2))
         else
            if ((Pos('*2', s)>0) or (Pos('* 2', s)>0)) and (Pos('length', s)>0) then
              nameR:=inttostr(strtoint(FKeywords[2])-(length(GetVar(FKeywords[3]))*2))
      else
        //������� �� �������
        if (((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)) then
          nameR:=inttostr(strtoint(FKeywords[1])-(length(GetVar(FKeywords[2]))*2+2))
        else
          if (Pos('*2', s)>0) or (Pos('* 2', s)>0) and (Pos('length', s)>0) then
             nameR:=inttostr(strtoint(FKeywords[1])-(length(GetVar(FKeywords[2]))*2));
  end;
  //====================
  //��������� �� ���������� � � ��������
  if (length(nameR)>0) and (isalpha(nameR[1])) then
    valueR:=strtoint(GetVar(nameR))
  else
    valueR:=strtoint(nameR);
  //====================
  if (Pos('=', s)>0) then
    //    valueL = valueR
    //������� ���������� � �� ���������
    for i := 0 to FTknCount - 1 do
      SetVar(FKeywords[i], inttostr(valueR));
end;
//******************************************************************************
function TJavaParser.fIf(var brkLeft, brkRigth, count: integer): boolean;
var
  idx: integer;
  isEnd: boolean;
  nameL, nameR, s: string;
  valueL, valueR: integer;
begin
  //���������� ����� ���������� IF or ELSE
//====================
  //if(itemsDataSize >= 208)
  //��������� �������� ��� VALUE
  nameR:=FKeywords[FTknCount-1];
  if FindToken('{') <> -1 then
  begin
    nameR:=FKeywords[FindToken('{')-1];
  end;
//===
  //������ ����� IF ��� ����������
  nameL:=FKeywords[1];
//====================
  //��������� �� ���������� � � ��������
  if (length(nameL)>0) and (isalpha(nameL[1])) then
  begin
    valueL:=strtoint(GetVar(nameL));
  end
  else
    valueL:=strtoint(nameL);
  if (length(nameR)>0) and (isalpha(nameR[1])) then
  begin
    valueR:=strtoint(GetVar(nameR));
  end
  else
    valueR:=strtoint(nameR);
//====================
  //������� ������ ���������
  s:=lowercase(FText.Strings[FPosition-1]);
  //������� �� �������
  if (Pos('&&', s)>0) then
  begin
//    result:= (valueL >= valueR);
  end;
  if (Pos('||', s)>0) then
  begin
//    result:= (valueL >= valueR);
  end;

  if (Pos('>=', s)>0) then
  begin
    result:= (valueL >= valueR);
  end else
  if (Pos('>', s)>0) then
  begin
    result:= (valueL > valueR);
  end else
  if (Pos('<=', s)>0) then
  begin
    result:= (valueL <= valueR);
  end else
  if (Pos('<', s)>0) then
  begin
    result:= (valueL < valueR);
  end else
  if (Pos('!=', s)>0) OR (Pos('<>', s)>0)then
  begin
    result:= (valueL <> valueR);
  end else
  if (Pos('=', s)>0) then
  begin
    result:= (valueL = valueR);
  end else
  if (Pos('!', s)>0) then
  begin
    //if (!object)
    result:=(valueL=0);
  end else
  begin
    //if (object)
    //0 - false, other - true;
    result:=(valueL<>0);
  end;
//====================
  //���������� ������ � ����� ���� �����
  isEnd:=false;
  idx:=0;
  if result then
  begin
    //����� ���������� ������
    dec(FPosition);
    while (FPosition < FTotal-1) and (not isEnd) do
    begin
      //����� ��������� ������
      ParseString();
      if FTknCount>0 then
      begin
        //�������� ���� IF
        if FindToken('if') <> -1 then
        begin
          //� ���� �� ������ ����������� ������
          if FindToken('{') <> -1 then
          begin
            inc(idx);
            isEnd:=false;
            if idx=1 then
            begin
              brkLeft:=FPosition;
            end;
          end;
          while (FPosition < FTotal-1) and (not isEnd) do
          begin
            //����� ��������� ������
            ParseString();
            if FTknCount>0 then
            begin
              //����������� ������
              if FindToken('}') <> -1 then
              begin
                dec(idx);
                if idx=0 then
                begin
                  isEnd:=true;
                  brkRigth:=FPosition-1;
                end;
              end;
              //����������� ������
              if FindToken('{') <> -1 then
              begin
                inc(idx);
              if ((idx=1) and (not isEnd)) then
                begin
                  brkLeft:=FPosition-1;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end else //����� ELSE
  begin
    //����� ���������� ������
    dec(FPosition);
    while (FPosition < FTotal-1) and (not isEnd) do
    begin
      //����� ��������� ������
      ParseString();
      if FTknCount>0 then
      begin
        //�������� ���� IF
        if FindToken('else') <> -1 then
        begin
          //� ���� �� ������ ����������� ������
          if FindToken('{') <> -1 then
          begin
            inc(idx);
            isEnd:=false;
            if idx=1 then
            begin
              brkLeft:=FPosition;
            end;
          end;
          while (FPosition < FTotal-1) and (not isEnd) do
          begin
            //����� ��������� ������
            ParseString();
            if FTknCount>0 then
            begin
              //����������� ������
              if FindToken('{') <> -1 then
              begin
                inc(idx);
                if idx=1 then
                begin
                  brkLeft:=FPosition-1;
                end;
              end;
              //����������� ������
              if FindToken('}') <> -1 then
              begin
                dec(idx);
                if idx=0 then
                begin
                  isEnd:=true;
                  brkRigth:=FPosition-1;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  result:=true; //����� ����� ����� IF ��� ELSE
  //���� �� ����� ELSE, ������ ����� � ����� IF
  if not isEnd then
  begin
    result:=false; //����� �� ����� ����� IF ��� ELSE
    FPosition:=brkLeft;
    //����� ���������� ������
    dec(FPosition);
    while (FPosition < FTotal-1) and (not isEnd) do
    begin
      //����� ��������� ������
      ParseString();
      if FTknCount>0 then
      begin
        //�������� ���� IF
        if FindToken('if') <> -1 then
        begin
          //� ���� �� ������ ����������� ������
          if FindToken('{') <> -1 then
          begin
            inc(idx);
            isEnd:=false;
          end;
          while (FPosition < FTotal-1) and (not isEnd) do
          begin
            //����� ��������� ������
            ParseString();
            if FTknCount>0 then
            begin
              //����������� ������
              if FindToken('{') <> -1 then
              begin
                inc(idx);
                if idx=1 then
                begin
                  brkLeft:=FPosition-1;
                end;
              end;
              //����������� ������
              if FindToken('}') <> -1 then
              begin
                dec(idx);
                if idx=0 then
                begin
                  isEnd:=true;
                  brkRigth:=FPosition-1;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;
//******************************************************************************
function TJavaParser.isdigit(ch : char) : boolean;
begin
  result:=pos(lowercase(ch), '1234567890') > 0;
end;
//******************************************************************************
function TJavaParser.isalpha(ch : char) : boolean;
begin
  result:=pos(lowercase(ch), 'qwertyuiopasdfghjklzxcvbnm_@{}?') > 0;
end;
//******************************************************************************
function TJavaParser.isdelimiter(ch : char) : boolean;
begin
  result:=pos(lowercase(ch), ' (),.:;[]=*+-<>!|') > 0;
end;
//******************************************************************************
function TJavaParser.GetValueFromPktStr(const typ, name_, PktStr: string;
                                        var PosInPkt: integer;
                                        var hexvalue: string): string;
var
  value: string;
  d: integer;
  pch: WideString;
begin
  hexvalue:='';
  case typ[1] of
    'd':
    begin
      value:=IntToStr(PInteger(@PktStr[PosInPkt])^);
      hexvalue:=' (0x'+inttohex(Strtoint(value),8)+')';
      Inc(PosInPkt,4);
    end;  //integer (������ 4 �����)           d, h-hex
    'c':
    begin
      value:=IntToStr(PByte(@PktStr[PosInPkt])^);
      hexvalue:=' (0x'+inttohex(Strtoint(value),2)+')';
      Inc(PosInPkt);
    end;  //byte / char (������ 1 ����)        b
    'f':
    begin
      value:=FloatToStr(PDouble(@PktStr[PosInPkt])^);
      Inc(PosInPkt,8);
    end;  //double (������ 8 ����, float)      f
    'n':
    begin
      value:=FloatToStr(PSingle(@PktStr[PosInPkt])^);
      Inc(PosInPkt,4);
    end;  //Single (������ 4 ����, float)      n
    'h':
    begin
      value:=IntToStr(PWord(@PktStr[PosInPkt])^);
      hexvalue:=' (0x'+inttohex(Strtoint(value),4)+')';
      Inc(PosInPkt,2);
    end;  //word (������ 2 �����)              w
    'q':
    begin
      value:=IntToStr(PInt64(@PktStr[PosInPkt])^);
      Inc(PosInPkt,8);
    end;  //int64 (������ 8 �����)
    '-','z':
    begin
      if Length(name_)>4 then
      begin
        if name_[1]<>'S' then
        begin
          d:=strtoint(copy(name_,1,4));
          Inc(PosInPkt,d);
          value:='���������� '+inttostr(d)+' ����(�)';
        end else
          value:='���������� ������';
      end else
      begin
        d:=strtoint(name_);
        Inc(PosInPkt,d);
        value:='���������� '+inttostr(d)+' ����(�)';
      end;
    end;
    's':
    begin
      d := PosEx(#0#0, PktStr ,PosInPkt)-PosInPkt;
      if (d mod 2)=1 then Inc(d);
      SetLength(pch, d div 2);
      if d>=2 then Move(PktStr[PosInPkt],pch[1],d) else d:=0;
      value:=pch; //����������� ���������

      Inc(PosInPkt,d+2);
    end;
  end;
  Result:=value;
//  if PosInPkt>wSize+10 then
//    result:='range error';
end;
//******************************************************************************
procedure TJavaParser.fByte();
var
  i: Integer;
  s, name_, value: string;
begin
  name_:=FKeywords[FTknCount-1];

  if FTknCount<=5 then
    name_:=FKeywords[FTknCount-1]
  else
  if FTknCount=6 then
  begin
   //������� ������ ���������
   s:=lowercase(FText.Strings[FPosition-1]);
   //������� �� �������, ���� length()
   if (Pos('length', s)>0)then
      name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[5]))))
   else
    name_:=FKeywords[FTknCount-1]
  end
  else
  begin
    if FTknCount>6 then
    begin
     //������� ������ ���������
     s:=lowercase(FText.Strings[FPosition-1]);
     //������� �� �������
     if ((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)then
       name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[6]))*2+2))
     else
     if ((Pos('*2', s)>0) or (Pos('* 2', s)>0)) and (Pos('length', s)>0) then
       name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[6]))*2));
    end;
  end;
  if (length(name_)>0) and (isalpha(name_[1])) then
  begin
    value:=GetVar(name_);
    name_:=value;
  end
  else
    value:=name_;
  //������� ���������� � �� ���������
  for i := 0 to FTknCount - 1 do
  begin
    SetVar(FKeywords[i], value);
  end;
end;
//******************************************************************************
procedure TJavaParser.Translate(PacketName, Packet: string; size: word;
                                var offset : integer; var typ, name_, value, hexvalue : string);
var
  i: Integer;
  s: string;
begin
  if FindToken('byte') <> -1 then
  begin
    name_:=FKeywords[FTknCount-1];

    if FTknCount<=5 then
      name_:=FKeywords[FTknCount-1]
    else
    if FTknCount=6 then
    begin
     //������� ������ ���������
     s:=lowercase(FText.Strings[FPosition-1]);
     //������� �� �������, ���� length()
     i:=Pos('length', s);
     if (Pos('length', s)>0)then
        name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[5]))))
     else
      name_:=FKeywords[FTknCount-1]
    end
    else
    begin
      if FTknCount>6 then
      begin
       //������� ������ ���������
       s:=lowercase(FText.Strings[FPosition-1]);
       //������� �� �������
       if ((Pos('+2', s)>0) or (Pos('+ 2', s)>0)) and (Pos('length', s)>0)then
         name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[6]))*2+2))
       else
       if ((Pos('*2', s)>0) or (Pos('* 2', s)>0)) and (Pos('length', s)>0) then
         name_:=inttostr(strtoint(FKeywords[4])-(length(GetVar(FKeywords[6]))*2));
      end;
    end;
    if (length(name_)>0) and (isalpha(name_[1])) then
    begin
      value:=GetVar(name_);
      name_:=value;
    end
    else
      value:=name_;
    //������� ���������� � �� ���������
    for i := 0 to FTknCount - 1 do
    begin
      SetVar(FKeywords[i], value);
    end;
    typ:='';
    name_:='';
    value:='';
  end;
end;
//******************************************************************************
//������ ������, ���� ���� �����������, �� ����������
function TJavaParser.ParseString(): boolean;
var
  ch, ch2   : char;
  str, tok : string;
  i, strsize: integer;
  isFind : boolean;
begin
  //������ ������ �������
  ClearKeywords;
  tok:='';
  isFind:=false;
  i:=1; //������ � ������
  result:=false; //������ �� �����
  str:=NextString; //��������� ������
  strsize:=length(Str);
  while (i<=length(Str)) do //and (not isFind) do
  begin
    //��������� ������
    ch:=Str[i];
    //���������� ����������� //
//    isFind := false;
    if ch = '/' then
    begin
      if i<length(Str) then
        ch2 := Str[i + 1]
      else
        ch2 := ' ';
      if ch2 = '/' then
      begin
        //����� //
        i := length(Str) + 1;
      end
      else
      begin
        //���������� ����������� '/*' �� '*/' � ������ ������
        isFind := false;
        if ch2 = '*' then
        begin
          isFind := false;
          while (FPosition < Count - 1) and (not isFind) do
          begin
            while (i <= length(Str)) do
            begin
              ch := Str[i];
              //��������� ������
              if ch = '*' then
              begin
                if i<length(Str) then
                  ch2 := Str[i + 1]
                else
                  ch2 := ' ';
                if ch2 = '/' then
                begin
                  //����� */
                  i := length(Str) + 1;
                  isFind := true;
                  break;
                end;
              end;
              inc(i);
            end;
            if isFind then
              break;
            //��������� ������
            Str := NextString;
            //�������� �� ��������� ������
            i := 1;
          end;
        end;
      end;
    end;
    //��������� ������������� ��� �������� �����
    if isalpha(ch) or isdigit(ch) then
      tok:=tok+lowercase(ch)
    else
    begin
      if isdelimiter(ch) then
      begin
        if tok<>'' then  //�� ��������� ������ �����
        begin
          FKeywords.Add(tok); //�������� ����� � �������
          tok:='';             //������� ��� ������ ���������� ������
          result:=true; //� ������� ���� ������
        end;
      end;
    end;
    inc(i); //�������� �� ��������� ������
  end;
  if tok<>'' then  //�� ��������� ������ �����
  begin
    FKeywords.Add(tok); //�������� ����� � �������
  end;
  FTknCount:=FKeywords.Count; //���-�� ��������� �������
end;
//******************************************************************************
function TJavaParser.ExtractAfterCharacter(sData, sFind: string): string;
  {���������� ����� ������ ����� ���������� �������}
var
  i: integer;
begin
  Result := '';
  i := Pos(sFind, sData);
  if i > 0 then
    Result := copy(sData, i + length(sFind), length(sData));
end;
//******************************************************************************
function TJavaParser.ExtractBeforeCharacter(sData, sFind: string): string;
  {���������� ������ �� ���������� �������}
var
  i: integer;
begin
  Result := '';
  i := Pos(sFind, sData);
  if i > 0 then
    Result := copy(sData, 1, i - length(sFind) + 1);
end;
//******************************************************************************
function TJavaParser.FindToken(tok: string): integer;
begin
  result:=FKeywords.IndexOf(tok);
end;
//******************************************************************************
function TJavaParser.FindVar(name: string): integer;
var
  isFind : boolean;
  i : integer;
begin
  result:=-1;
  for i := 0 to CountToken - 1 do
  begin
      isFind:=Pos(name, FVariable[i].name)>0;
      if isFind then
      begin
        result:=i;
        break;
      end;
  end;
end;
//******************************************************************************
function TJavaParser.RtrimEx(sData, sDelimiter: string): string;
//  {�������� �� ������ S �������� ������� ������}
var
  m, i, j: integer;
  s: string;
  isFind : boolean;
begin
  s := sData;
  i := 0;
  while i = 0 do
  begin
    //����� ������ � ����� ������
    m := length(s)-length(sDelimiter)+1;
    if m > 0 then
    begin
      if s[m] <> sDelimiter[1] then
        i := 1
      else
      begin
        //������ ������ ������
        isFind:=true;
        //��������� �� ���� ����� sDelemiter, ������ �� ������� �������
        for j := 2 to length(sDelimiter) do
        begin
          if s[m+j-1] = sDelimiter[j] then
            isFind:=true   //������ ������
          else
            isFind:=false; //���
        end;
        if isFind then  //���� �����
          Delete(s, m, length(sDelimiter)); //�� ������ ��� ���������
      end;
    end;
    //������ �������
    if m <= 0 then
      i := 1;
  end;
  Result := s;
end;
//******************************************************************************
function TJavaParser.TrimEx(sData, sDelimiter: string): string;
  {�������� �� ���� ������ S �������� �������}
var
  i: integer;
  s: string;
begin
  s := sData;
  i:=1;
  while i<>0 do
  begin
    i:=Pos(sDelimiter, s);
    if (i<>0) then
      Delete(s, i, length(sDelimiter))
    else
      i:=0;
  end;
  Result := s;
end;
//******************************************************************************
function TJavaParser.LtrimEx(sData, sDelimiter: string): string;
  {�������� �� ������ S �������� ������� �����}
var
  i: integer;
  s: string;
begin
  s := sData;
  i:=1;
  while i<>0 do
  begin
    i:=Pos(sDelimiter, s);
    if (i<>0) and (i=1) then
      Delete(s, i, length(sDelimiter))
    else
      i:=0;
  end;
  Result := s;
end;
//******************************************************************************
procedure TJavaParser.LoadFromFile(name: string);
begin
  try
    FText.LoadFromFile(name);
  except
    //
  end;
  FTotal:=FText.Count;
end;
//******************************************************************************
function TJavaParser.Ltrim(sData: string): string;
  {�������� �� ������ S �������� ������� �����}
begin
  Result := LtrimEx(sData, ' ');
  Result := LtrimEx(sData, #9);
end;
//******************************************************************************
function TJavaParser.Rtrim(sData: string): string;
  {�������� �� ������ S �������� ������� �����}
begin
  Result := RtrimEx(sData, ' ');
end;
//******************************************************************************
function TJavaParser.AllTrimEx(sData, sDelimiterLeft, sDelimiterRight: string): string;
  {�������� �� ������ S �������� ������� ����� � ������}
begin
  Result := LtrimEx(RtrimEx(sData, sDelimiterRight), sDelimiterLeft);
end;
//******************************************************************************
function TJavaParser.AllTrim(sData: string): string;
  {�������� �� ������ S ���������� ������� ����� � ������}
begin
  Result := Ltrim(Rtrim(sData));
end;
//******************************************************************************

end.
