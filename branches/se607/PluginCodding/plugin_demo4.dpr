library plugin_demo4;

{$define RELEASE} // ��� ������������� � ������� ���������, ��� ������ ����� ���������������

uses
  FastMM4 in '..\fastmm\FastMM4.pas',
  FastMM4Messages in '..\fastmm\FastMM4Messages.pas',
  windows,
  variants,
  classes,
  usharedstructs in '..\units\usharedstructs.pas';

var                                {version} {revision}
  min_ver_a : array[0..3] of byte = (3, 5, 23, 141);
  min_ver : integer absolute min_ver_a; // ����������� �������������� ������ ���������
  ps : TPluginStruct;

function GetPluginInfo(const ver : integer) : pchar; stdcall;
begin
  if ver < min_ver then
  begin
    Result := '���������������� Plugin � ��������� l2ph' + sLineBreak +
      '��� ������ 3.5.23.141+' + sLineBreak +
      '� ��� ������ ������ ���������! ������ �� ������ ��������� � ��� ��������!';
  end
  else
  begin
    Result := '���������������� Plugin � ��������� l2ph' + sLineBreak +
      '��� ������ 3.5.23.141+' + sLineBreak +
      '"��� �������� ���� ������� � �� ����������" ����� ������. � alexteam' + sLineBreak +
      sLineBreak +
      sLineBreak +
      '������ - ��������� ���������� ����������, ��������, ��� ��� ����� �������� � ��� variant (����� ���). ����� ��� ���� ��������' + sLineBreak +
      sLineBreak +
      '������� ������� ���� �� ����:' + sLineBreak +
      'function isGlobalVarExists(name:string):boolean' + sLineBreak +
      'procedure SetGlobalVar(name:string; variable:Variant)' + sLineBreak +
      'procedure DeleteGlobalVar(name:string)' + sLineBreak +
      'Function GetGlobalVar(name:string):Variant' + sLineBreak +
      'procedure DeleteAllGlobalVars' + sLineBreak;
  end;
end;

function SetStruct(const struct : PPluginStruct) : boolean; stdcall;
begin
  ps := struct^;
  Result := true;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//��� �������.


type
  TVariable = class (tobject)
    name : string;
    variable : variant;
    constructor create;
    destructor destroy; override;
  end;

var
  VarList : Tlist;


constructor TVariable.create;
begin
  //��������� ���� � ���������� ������
  VarList.Add(self);
end;

destructor TVariable.destroy;
var
  i : integer;
begin
  //������� ���� �� ����������� ������
  i := 0;
  while i < VarList.Count do
  begin
    if TVariable(VarList.Items[i]) = self then
    begin
      VarList.Delete(i);
      exit;
    end;
    inc(i);
  end;
  inherited;
end;


procedure OnLoad; stdcall;
begin
  VarList := TList.Create;

end;


procedure DeleteAllGlobalVars;
begin
  while VarList.Count > 0 do
  begin
    TVariable(VarList.Items[0]).destroy;
  end;
end;

procedure OnFree; stdcall;
begin
  DeleteAllGlobalVars;
  VarList.Destroy;
end;

function GetTVariable(name : string) : TVariable;
var
  i : integer;
begin
  result := nil;

  i := 0;
  while i < VarList.Count do
  begin
    if TVariable(VarList.Items[i]).name = name then
    begin
      Result := TVariable(VarList.Items[i]);
      exit;
    end;
    inc(i);
  end;
end;

procedure SetOrCreateVar(Name : string; variable : variant);
var
  MyVar : TVariable;
begin
  myvar := GetTVariable(name);

  if not assigned(MyVar) then
  begin
    MyVar := TVariable.create;
    MyVar.name := Name;
  end;

  MyVar.variable := variable;
end;

procedure deletevar(name : string);
var
  i : integer;
begin
  i := 0;
  while i < VarList.Count do
  begin
    if TVariable(VarList.Items[i]).name = name then
    begin
      TVariable(VarList.Items[i]).destroy;
      exit;
    end;
    inc(i);
  end;
end;

function OnCallMethod(const ConnectId, ScriptId : integer; const MethodName : string; // ��� ������� � ������� ��������
var Params, // ��������� �������
  FuncResult : variant // ��������� �������
  ) : boolean; stdcall; // ���� ����� True �� ����������
                              // ��������� ������� ������������
var
  variable : TVariable;
begin
  Result := false;
  if MethodName = 'ISGLOBALVAREXISTS' then
  begin
    FuncResult := assigned(GetTVariable(VarAsType(Params[0], varString)));

    Result := true;
  end
  else

  if MethodName = 'SETGLOBALVAR' then
  begin
    SetOrCreateVar(
      VarAsType(Params[0], varString),
      Params[1]);

    Result := true;
    FuncResult := Null;
  end
  else

  if MethodName = 'DELETEGLOBALVAR' then
  begin
    deletevar(VarAsType(Params[0], varString));

    Result := true;
    FuncResult := Null;
  end
  else

  if MethodName = 'GETGLOBALVAR' then
  begin
    variable := GetTVariable(VarAsType(Params[0], varString));
    if assigned(variable) then
    begin
      FuncResult := variable.variable;
    end
    else
    begin
      FuncResult := Null;
    end;

    Result := true; // ��������� ���������� ��������� ������� � ���������
  end
  else

  if MethodName = 'DELETEALLGLOBALVARS' then
  begin
    DeleteAllGlobalVars;

    Result := true;
    FuncResult := Null;
  end;
end;

procedure OnRefreshPrecompile; stdcall;
begin
  ps.UserFuncs.Add('function isGlobalVarExists(name:string):boolean');
  ps.UserFuncs.Add('procedure SetGlobalVar(name:string; variable:Variant)');
  ps.UserFuncs.Add('procedure DeleteGlobalVar(name:string)');
  ps.UserFuncs.Add('Function GetGlobalVar(name:string):Variant');
  ps.UserFuncs.Add('procedure DeleteAllGlobalVars');
end;

// ������������ ������������ ���������� �������
exports
  GetPluginInfo,
  SetStruct,
  OnLoad,
  OnRefreshPrecompile,
  OnCallMethod,
  OnFree;


begin
end.
