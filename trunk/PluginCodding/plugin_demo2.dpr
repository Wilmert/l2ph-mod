library plugin_demo2;

uses
  mmsystem,
  usharedstructs in '..\units\usharedstructs.pas';

var
  min_ver_a: array[0..3] of Byte = ( 3,5,30,      160   );
  min_ver: cardinal absolute min_ver_a; // ����������� �������������� ������ ���������
  work : boolean;
  ps: TPluginStruct;


function GetPluginInfo(const ver: LongWord): PChar; stdcall;
begin
  work := ver>=min_ver;
  if not work then
    Result:='Plugin � ��������� l2ph ����������� �-� PlaySound(FileName:string;Synch:boolean=false):boolean'+sLineBreak+
            '��� ������ 3.5.31.162+'+sLineBreak+
            '� ��� ������ ������ ���������. ����������!!'
  else
    Result:='Plugin � ��������� l2ph ����������� �-� PlaySound(FileName:string;Synch:boolean=false):boolean'+sLineBreak+
            '��� ������ 3.5.31.162+';

end;


function SetStruct(const struct: PPluginStruct): Boolean; stdcall;
begin
  ps := struct^;
  Result:=True;
end;

function OnCallMethod(const ConnectId, ScriptId: integer;
                      const MethodName: String; // ��� ������� � ������� ��������
                      var Params, // ��������� �������
                      FuncResult: Variant // ��������� �������
         ): Boolean; stdcall; // ���� ����� True �� ����������
                              // ��������� ������� ������������
begin
  Result:=False; // ������� ��������� ������� ���������
  if not work then exit;  
  if MethodName='PLAYSOUND' then begin
    if boolean(Params[1]) then
      FuncResult := PlaySound(pchar(string(Params[0])),0,SND_SYNC)
    else
    begin
      FuncResult := true;
      PlaySound(pchar(string(Params[0])),0,SND_ASYNC);
    end;
    Result:=True; // ��������� ���������� ��������� ������� � ���������
    FuncResult:=Pi;
  end;
end;

Procedure OnRefreshPrecompile; stdcall;
begin
  if not work then exit;
  ps.UserFuncs.Add('function PlaySound(FileName:string;Synch:boolean=false):boolean');
end;


exports
  GetPluginInfo,
  SetStruct,
  OnRefreshPrecompile,
  OnCallMethod;

begin
end.
