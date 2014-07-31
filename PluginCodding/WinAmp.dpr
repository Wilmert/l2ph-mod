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
  min_ver_a : array[0..3] of byte = (3, 5, 23, 141);
  min_ver : longword absolute min_ver_a; // ����������� �������������� ������ ���������
  ps : TPluginStruct; // ��������� ������������ � ������

function GetPluginInfo(const ver : longword) : pchar; stdcall;
begin
  Result := '������ ���������� Winamp � ��������� l2ph' + sLineBreak +
    '��� ������ 3.5.23.141+';
end;


function SetStruct(const struct : PPluginStruct) : boolean; stdcall;
begin
  ps := struct^;
  Result := true;
end;

procedure WinampCommand(Command : integer);
var
  WinampHWND : cardinal;
begin
  WinampHWND := findwindow('Winamp v1.x', nil);
  if (WinampHWND <> 0) then
  begin
    SendMessage(WinampHWND, WM_COMMAND, Command, 0);
  end;
end;


// ���������� ��� ������ ���������� ������� ����������� � RefreshPrecompile
function OnCallMethod(const ConnectId, ScriptId : integer; const MethodName : string; // ��� ������� � ������� ��������
var Params, // ��������� �������
  FuncResult : variant // ��������� �������
  ) : boolean; stdcall; // ���� ����� True �� ����������
                              // ��������� ������� ������������
begin
  Result := false; // ������� ��������� ������� ���������
  if lowercase(MethodName) = 'winampcommand' then
  begin
    WinampCommand(integer(Params[0]));
    Result := true; // ��������� ���������� ��������� ������� � ���������
  end;
end;


// ���������� ����� ������������ �������, ��������� ��������� ���� ������� � �������� / ���������� ������
procedure OnRefreshPrecompile; stdcall;
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
