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
  min_ver_a: array[0..3] of Byte = ( 3,5,23,      141   );
  min_ver: Integer absolute min_ver_a; // ����������� �������������� ������ ���������
  ps: TPluginStruct;

function GetPluginInfo(const ver: Integer): PChar; stdcall;
begin
  if ver<min_ver then
    Result:='���������������� Plugin � ��������� l2ph'+sLineBreak+
            '��� ������ 3.5.23.141+'+sLineBreak+
            '� ��� ������ ������ ���������! ������ �� ������ ��������� � ��� ��������!'
  else
    Result:='���������������� Plugin � ��������� l2ph'+sLineBreak+
            '��� ������ 3.5.23.141+'+sLineBreak+
            '"��� �������� ���� ������� � �� ����������" ����� ������. � alexteam'+sLineBreak+
            sLineBreak+
            sLineBreak+
            '������ - ��������� ���������� ����������, ��������, ��� ��� ����� �������� � ��� variant (����� ���). ����� ��� ���� ��������'+sLineBreak+
            sLineBreak+
            '������� ������� ���� �� ����:'+sLineBreak+
            'function isGlobalVarExists(name:string):boolean'+sLineBreak+
            'procedure SetGlobalVar(name:string; variable:Variant)'+sLineBreak+
            'procedure DeleteGlobalVar(name:string)'+sLineBreak+
            'Function GetGlobalVar(name:string):Variant'+sLineBreak+
            'procedure DeleteAllGlobalVars'+sLineBreak;
end;

function SetStruct(const struct: PPluginStruct): Boolean; stdcall;
begin
  ps := struct^;
  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//��� �������.


type
  TVariable = class(tobject)
  name : string;
  variable : variant;
  Constructor create;
  Destructor destroy; override;
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
  i: integer;
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
  TVariable(VarList.Items[0]).destroy;
end;

procedure OnFree; stdcall;
begin
  DeleteAllGlobalVars;
  VarList.Destroy;
end;         

Function GetTVariable(name:string):TVariable;
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

Procedure SetOrCreateVar(Name:string; variable: variant);
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

procedure deletevar(name:string);
var
  i:integer;
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

function OnCallMethod(const ConnectId, ScriptId: integer; 
                      const MethodName: String; // ��� ������� � ������� ��������
                      var Params, // ��������� �������
                      FuncResult: Variant // ��������� �������
         ): Boolean; stdcall; // ���� ����� True �� ����������
                              // ��������� ������� ������������
var
  variable : TVariable;
begin
  Result:=False;
  if MethodName='ISGLOBALVAREXISTS' then
  begin
    FuncResult := assigned(GetTVariable(VarAsType(Params[0], varString)));
    
    Result := True;     
  end else

  if MethodName='SETGLOBALVAR' then
  begin
    SetOrCreateVar(
      VarAsType(Params[0], varString),
      Params[1]);

    Result:=True;
    FuncResult := Null;    
  end else

  if MethodName='DELETEGLOBALVAR' then
  begin
    deletevar(VarAsType(Params[0], varString));

    Result:=True;
    FuncResult := Null;    
  end else

  if MethodName='GETGLOBALVAR' then
  begin
    variable := GetTVariable(VarAsType(Params[0], varString));
    if assigned(variable) then
      FuncResult := variable.variable
    else
      FuncResult := Null;

    Result:=True; // ��������� ���������� ��������� ������� � ���������
  end else

  if MethodName='DELETEALLGLOBALVARS' then
  begin
    DeleteAllGlobalVars;

    Result:=True;
    FuncResult := Null;
  end;
end;

Procedure OnRefreshPrecompile; stdcall;
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
