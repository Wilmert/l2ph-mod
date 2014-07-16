library WinAmp;

{$define RELEASE} // ��� ������������� � ������� ���������, ��� ������ ����� ���������������

uses
  FastMM4 in '..\fastmm\FastMM4.pas',
  FastMM4Messages in '..\fastmm\FastMM4Messages.pas',
  windows,
  messages,
  sysutils,
  usharedstructs in '..\units\usharedstructs.pas';

var                                {version} {revision}
  min_ver_a: array[0..3] of Byte = ( 3,5,23,      141   );
  min_ver: longword absolute min_ver_a; // ����������� �������������� ������ ���������
  ps: TPluginStruct; // ��������� ������������ � ������

function GetPluginInfo(const ver: longword): PChar; stdcall;
begin
    Result:='������ ���������� Winamp � ��������� l2ph'+sLineBreak+
            '��� ������ 3.5.23.141+';
end;


function SetStruct(const struct: PPluginStruct): Boolean; stdcall;
begin
  ps := struct^;
  Result:=True;
end;

Procedure WinampCommand(Command:Integer);
var WinampHWND:cardinal;
begin
WinampHWND := findwindow('Winamp v1.x',nil);
if (WinampHWND <> 0) then
  SendMessage(WinampHWND, WM_COMMAND, Command, 0);
end;


// ���������� ��� ������ ���������� ������� ����������� � RefreshPrecompile
function OnCallMethod(const ConnectId, ScriptId: integer;
                      const MethodName: String; // ��� ������� � ������� ��������
                      var Params, // ��������� �������
                      FuncResult: Variant // ��������� �������
         ): Boolean; stdcall; // ���� ����� True �� ����������
                              // ��������� ������� ������������
begin
  Result:=False; // ������� ��������� ������� ���������
  if lowercase(MethodName) = 'winampcommand' then 
    begin
      WinampCommand(integer(Params[0]));
      Result:=True; // ��������� ���������� ��������� ������� � ���������
    end;
end;


// ���������� ����� ������������ �������, ��������� ��������� ���� ������� � �������� / ���������� ������
Procedure OnRefreshPrecompile; stdcall;
begin
  ps.UserFuncs.Add('procedure WinampCommand(Command:Integer)');
end;



// ������������ ������������ ���������� �������
exports
  GetPluginInfo,
  SetStruct,
  OnCallMethod,
  OnRefreshPrecompile;

begin
end.

