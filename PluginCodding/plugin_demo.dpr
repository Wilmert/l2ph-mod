library plugin_demo;

{$define RELEASE} // ��� ������������� � ������� ���������, ��� ������ ����� ���������������

uses
  FastMM4 in '..\fastmm\FastMM4.pas',
  FastMM4Messages in '..\fastmm\FastMM4Messages.pas',
  SysUtils,
  Windows,
  dialogs,
  Classes,
  usharedstructs in '..\units\usharedstructs.pas';

var                                
  min_ver_a: array[0..3] of Byte = ( 3,5,23,      141   );
  min_ver: LongWord absolute min_ver_a; // ����������� �������������� ������ ���������
  ps: TPluginStruct;
  ppck: string;
const
  pause=15000;

var
  ColvoHP, CharObjID, ItemObjHP: integer;
  CurHP, MaxHP : integer;
  lastHP, cntHP:cardinal;
  TimerHP: Boolean;
  StatusHP: Boolean;

function GetPluginInfo(const ver: LongWord): PChar; stdcall;
begin
  if ver<min_ver then
    Result:='���������������� Plugin � ��������� l2phx'+sLineBreak+
            '��� ������ 3.5.23.141+'+sLineBreak+
            '� ��� ������ ������ ���������! ������ �� ������ ��������� � ��� ��������!'
  else
    Result:='���������������� Plugin � ��������� l2phx'+sLineBreak+
            '��� ������ 3.5.23.141+'+sLineBreak+
            '������������� �� �������';
end;


procedure Say(msg:string);
var
  buf: string;
begin
  with ps do begin
    buf:=HexToString('4A 00 00 00 00');
    WriteD(buf,2);
    WriteS(buf,'AutoHP');
    WriteS(buf,msg);
    SendPacketStr(buf,cntHP,False);
  end;
end;


function SetStruct(const struct: PPluginStruct): Boolean; stdcall;
begin
  ps := struct^;
  Result:=True;
  cntHP := 0;
end;




procedure StatsUpdate;
var
 i: integer;
begin
 for i:=0 to ps.ReadDEx(ppck,7)-1 do
 case ppck[i*8+8] of
   #$09: CurHP:=ps.ReadDEx(ppck,i*8+15);
   #$0A: MaxHP:=ps.ReadDEx(ppck,i*8+15);
 end;
 say('CurHP/MaxHP = '+inttostr(curhp)+'/'+inttostr(maxhp));
 if (CurHP<=MaxHP-50) then TimerHP:=true else TimerHP:=false;
end;

procedure OnLoad; stdcall;
begin
  statusHP:=false;
  CharObjID:=0;
  ItemObjHP:=0;
  TimerHP:=false;
  lastHP:=0;
  cntHP := 0;
  with ps do
    begin

    if GoFirstConnection then
      repeat
      cntHP := ConnectInfo.ConnectID;
      Say('��� ������ ������� ���������� �������� � ���� ����� set � ���������');
      until GoNextConnection;
      
    end;
end;

procedure OnPacket(const cnt: integer; const fromServer: Boolean; const connectionname:string; var pck: string); stdcall;
var
  buf: string;
begin
  if length(pck) < 3 then exit;
  ppck:=pck;

  if not FromServer and (pck[1]=#$38) and (cntHP=0) then
  if(ps.ReadSEx(pck,3)='set')then begin
    pck := ''; // �� ���������� �����
    cntHP:=cnt;
    Say('������� ��� ����������.');
    Say('��� ������ ������ ������� �������, ��������� ��� �������� Heal Potion!');
  end;

  if FromServer and(cnt = cntHP)then begin
    //InventoryUpdate
    if(pck[1]=#$27)and((ps.ReadDEx(pck,13)=1060)
    or(ps.ReadDEx(pck,13)=1061))then begin //Healing Potion, Lesser Healing Potion
      ItemObjHP:=ps.ReadDEx(pck,9);
      ColvoHP:=ps.ReadDEx(pck,17); //���������� �����
      if statusHP then exit;
      Say('�������������� ������������� �eal �otion ������ � ������!');
      Say('�����='+IntToStr(ColvoHP));
      statusHP:=true;
    end;

    //UserInfo
    if(pck[1]=#$04)then
      begin
        CharObjID:=ps.ReadDEx(ppck,19);
        MaxHP:=ps.ReadDEx(ppck,83);
      end;

    //StatusUpdate
    if((pck[1]=#$0E)and(ps.ReadDEx(pck,3)=CharObjID)and(pck[4]=#$04))then
      StatsUpdate;

    if TimerHP and(GetTickCount-lastHP > pause)then begin
      lastHP:=GetTickCount;
      buf:=#$14;
      ps.WriteD(buf,ItemObjHP);
      ps.WriteD(buf,0);
      ps.SendPacketStr(buf,cnt,True);
      if ColvoHP<5 then
        Say('��������� �����! �������� Heal Potion!');
      if ColvoHP=1 then begin
        Say('�����='+inttostr(ColvoHP-1));
        Say('��������� �����! �������� Heal Potion!');
        TimerHP:=False;
      end;
    end;
  end;

end;

exports
  GetPluginInfo,
  OnPacket,
  OnLoad,
  SetStruct;

begin
end.

