library plugin_demo3;

{$define RELEASE} // ��� ������������� � ������� ���������, ��� ������ ����� ���������������

uses
    FastMM4 in '..\fastmm\FastMM4.pas',
    FastMM4Messages in '..\fastmm\FastMM4Messages.pas',
    windows,
    usharedstructs in '..\units\usharedstructs.pas',
    plugin_demo3_form in 'plugin_demo3_form.pas' {MyForm};

var
    min_ver_a : array[0..3] of byte = (3, 5, 23, 141);
    min_ver : longword absolute min_ver_a; // ����������� �������������� ������ ���������
    ps : TPluginStruct; // ��������� ������������ � ������

// ����������� ���������� �������.
// ������ ������� �������� �������,
// ������ ����� ��������� ������ ���������
function GetPluginInfo(const ver : longword) : pchar; stdcall;
begin
    if ver < min_ver then
    begin
        Result := '���������������� Plugin � ��������� l2phx' + sLineBreak +
            '��� ������ 3.5.23.141+' + sLineBreak +
            '� ��� ������ ������ ���������! ������ �� ������ ��������� � ��� ��������!';
    end
    else
    begin
        Result := '���������������� Plugin � ��������� l2phx' + sLineBreak +
            '��� ������ 3.5.23.141+' + sLineBreak +
            '��� ����� ������������ ���������������� ����� ?';
    end;
end;

// ����������� ���������� �������.
// �������� ��������� � �������� �� ��� ������� �������� ���������,
// ������� ����� ���������� �� �������.
// ���� ����� False �� ������ �����������.
function SetStruct(const struct : PPluginStruct) : boolean; stdcall;
begin
    ps := struct^;
    Result := true;
end;


// ������������� ���������� �������. (����� ������������� � �������)
// ���������� ��� �������� �������
procedure OnFree; stdcall;
begin
    MyForm.Destroy;
end;

// ������������� ���������� �������. (����� ������������� � �������)
// ���������� ��� �������� �������
procedure OnLoad; stdcall;
begin
    MyForm := TMyForm.Create(nil);
    SetParent(MyForm.Handle, ps.userFormHandle);
    ps.ShowUserForm(false);
    MyForm.Show;
end;


// ������������ ������������ ���������� �������
exports
    GetPluginInfo,
    SetStruct,
    OnLoad,
    OnFree;
begin
end.
