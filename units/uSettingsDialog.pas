unit uSettingsDialog;

interface

uses
  uResourceStrings,
  usharedstructs,
  uglobalfuncs,
  winsock,
  math,
  IniFiles, Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Mask, JvExMask, JvSpin, ComCtrls, siComp,
  Buttons;

type
  TfSettings = class(TForm)
    PageControl3: TPageControl;
    TabSheet8: TTabSheet;
    TabSheet9: TTabSheet;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    isInject: TLabeledEdit;
    HookMethod: TRadioGroup;
    ChkIntercept: TCheckBox;
    JvSpinEdit1: TJvSpinEdit;
    ChkSocks5Mode: TCheckBox;
    iInject: TCheckBox;
    ChkLSPIntercept: TCheckBox;
    isLSP: TLabeledEdit;
    Panel1: TPanel;
    Panel3: TPanel;
    Button1: TButton;
    Button2: TButton;
    rgProtocolVersion: TRadioGroup;
    GroupBox1: TGroupBox;
    ChkNoDecrypt: TCheckBox;
    ChkChangeParser: TCheckBox;
    ChkAion: TCheckBox;
    ChkKamael: TCheckBox;
    ChkGraciaOff: TCheckBox;
    iNewxor: TCheckBox;
    TabSheet1: TTabSheet;
    ChkAllowExit: TCheckBox;
    ChkShowLogWinOnStart: TCheckBox;
    lang: TsiLang;
    Bevel4: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    JvSpinEdit2: TJvSpinEdit;
    isIgnorePorts: TLabeledEdit;
    isClientsList: TLabeledEdit;
    GroupBox2: TGroupBox;
    chkAutoSavePlog: TCheckBox;
    ChkHexViewOffset: TCheckBox;
    ChkShowLastPacket: TCheckBox;
    chkRaw: TCheckBox;
    chkNoFree: TCheckBox;
    btnNewXor: TSpeedButton;
    BtnInject: TSpeedButton;
    BtnLsp: TSpeedButton;
    dlgOpenDll: TOpenDialog;
    isNewXor: TLabeledEdit;
    ChkLSPDeinstallonclose: TCheckBox;
    isMainFormCaption: TEdit;
    lspInterceptMethod: TRadioGroup;
    chkProcessPackets: TCheckBox;
    PnlSocks5Chain: TGroupBox;
    ChkUseSocks5Chain: TCheckBox;
    Label4: TLabel;
    Label5: TLabel;
    edSocks5Host: TEdit;
    edSocks5Port: TEdit;
    chkSocks5NeedAuth: TCheckBox;
    edSocks5AuthUsername: TEdit;
    Label6: TLabel;
    edSocks5AuthPwd: TEdit;
    Label7: TLabel;
    btnTestSocks5Chain: TButton;
    chkIgnoseClientToServer: TCheckBox;
    chkIgnoseServerToClient: TCheckBox;
    EditkNpcID: TEdit;
    LabelkNpcID: TLabel;
    GroupBox3: TGroupBox;
    chkNoLog: TCheckBox;
    GroupBox4: TGroupBox;
    edWinClassName: TEdit;
    GroupBox5: TGroupBox;
    edMainMutex: TEdit;
    Label3: TLabel;
    Label8: TLabel;
    procedure ChkKamaelClick(Sender: TObject);
    procedure ChkGraciaOffClick(Sender: TObject);
    procedure ChkInterceptClick(Sender: TObject);
    procedure ChkSocks5ModeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ChkLSPInterceptClick(Sender: TObject);
    procedure iNewxorClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure iInjectClick(Sender: TObject);
    procedure isLSPChange(Sender: TObject);
    procedure ChkNoDecryptClick(Sender: TObject);
    procedure ChkAionClick(Sender: TObject);
    procedure rgProtocolVersionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnInjectClick(Sender: TObject);
    procedure BtnLspClick(Sender: TObject);
    procedure btnNewXorClick(Sender: TObject);
    procedure isMainFormCaptionChange(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure edSocks5AuthPwdEnter(Sender: TObject);
    procedure edSocks5AuthPwdExit(Sender: TObject);
    procedure edSocks5PortKeyPress(Sender: TObject; var Key: Char);
    procedure edSocks5PortExit(Sender: TObject);
    procedure lspInterceptMethodClick(Sender: TObject);
    procedure btnTestSocks5ChainClick(Sender: TObject);
  protected
    procedure CreateParams(var Params : TCreateParams); override;
  private
    { Private declarations }
  public
    InterfaceEnabled:boolean;
    procedure init;
    procedure readsettings;
    procedure WriteSettings;
    procedure GenerateSettingsFromInterface;
    { Public declarations }

  end;

var
  fSettings: TfSettings;

implementation

uses uData, usocketengine, uLogForm, uFilterForm, uMain, uLangSelectDialog;

{$R *.dfm}

procedure TfSettings.readsettings;
begin
  InterfaceEnabled := true;

  fLangSelectDialog.siLangCombo1.ItemIndex := Options.ReadInteger('General', 'language', 0);
  fMain.lang.Language := fLangSelectDialog.siLangCombo1.Items.Strings[fLangSelectDialog.siLangCombo1.ItemIndex];
  Application.ProcessMessages;

  InterfaceEnabled := false;

  //������������ ���������� ����� � ����
  MaxLinesInLog:=Options.ReadInteger('General','MaxLinesInLog',300);
  //������������ ���������� ����� � ���� �������
  MaxLinesInPktLog:=Options.ReadInteger('General','MaxLinesInPktLog',3000);
  //����� �������������� NpcID, ��������� ��� ����������� ����������� ����� ���
  kNpcID:=Options.ReadInteger('General', 'kNpcID', 1000000);
  EditkNpcId.Text:=inttostr(kNpcId);

  isClientsList.Text:=Options.ReadString('General','Clients','l2.exe;l2.bin;l2walker.exe;l2helper.exe;aion.bin;aion.exe;');
  isIgnorePorts.Text:=Options.ReadString('General','IgnorPorts','7777;');

  ChkNoDecrypt.Checked:=Options.ReadBool('General','NoDecrypt',False);
  ChkChangeParser.Checked:=Options.ReadBool('General','ChangeParser',False);
  ChkAion.Checked:=Options.ReadBool('General','ChkAion',False);
  chkIgnoseClientToServer.Checked:=Options.ReadBool('General','IgnoseClientToServer',False);
  chkIgnoseServerToClient.Checked:=Options.ReadBool('General','IgnoseServerToClient',False);
  ChkKamael.Checked:=Options.ReadBool('General','ChkKamael',False);
  ChkGraciaOff.Checked:=Options.ReadBool('General', 'ChkGraciaOff', False);
  isNewxor.Text:=Options.ReadString('General','isNewxor', AppPath+'newxor.dll');
  isInject.Text:=Options.ReadString('General','isInject', AppPath+'inject.dll');
  isLSP.Text := Options.ReadString('General','isLSP', ExtractFilePath(Application.ExeName)+'LSP.dll'); //+ ������ ����. �.�. ������������ ��������.

  iNewxor.Checked:=Options.ReadBool('General', 'iNewxor', False);
  iInject.Checked:=Options.ReadBool('General', 'iInject', False);

  ChkLSPIntercept.Checked:=Options.ReadBool('General','EnableLSP',False);
  ChkIntercept.Checked:=Options.ReadBool('General','Enable',True);
  ChkSocks5Mode.Checked:=Options.ReadBool('General','Socks5Mode',False);
  JvSpinEdit1.Value:=Options.ReadFloat('General','Timer',5);
  HookMethod.ItemIndex:=Options.ReadInteger('General','HookMethod',0);
  JvSpinEdit2.Value := Options.ReadInteger('General','LocalPort',7788);
  LocalPort := round(JvSpinEdit2.Value);
  ChkAllowExit.Checked := Options.ReadBool('General','FastExit',False);
  ChkShowLogWinOnStart.Checked := Options.ReadBool('General','AutoShowLog',False);
  rgProtocolVersion.ItemIndex :=  Min(Options.ReadInteger('Snifer','ProtocolVersion', 0), rgProtocolVersion.Items.Count);
  chkNoFree.Checked := Options.ReadBool('General','NoFreeAfterDisconnect',False);
  chkRaw.Checked := Options.ReadBool('General','RAWdatarememberallowed',False);
  JvSpinEdit1.Value := Options.ReadFloat('General', 'interval', 5);
  isMainFormCaption.Text := Options.ReadString('general','Caption', 'L2PacketHack v%s by CoderX.ru Team');

  ChkHexViewOffset.Checked := Options.ReadBool('General','HexViewOffset', True);
  chkAutoSavePlog.Checked := Options.ReadBool('General','AutoSavePLog', False);
  chkNoLog.Checked := Options.ReadBool('General','NoLog', False);
  ChkShowLastPacket.Checked := Options.ReadBool('General','ShowLastPacket', True);
  ChkLSPDeinstallonclose.Checked := Options.ReadBool('General','LSPDeinstallonclose',true);
  LspInterceptMethod.ItemIndex := Options.ReadInteger('General','lspInterceptMethod',0);
  chkProcessPackets.Checked := Options.ReadBool('General','chkProcessPackets',true);

  ChkUseSocks5Chain.Checked := Options.ReadBool('General','ChkUseSocks5Chain',false);
  chkSocks5NeedAuth.Checked := Options.ReadBool('General','ChkSocks5NeedAuth',false);

  edSocks5Host.Text := Options.ReadString('General','Socks5Host','');
  edSocks5Port.Text := Options.ReadString('General','Socks5Port','1080');
  edSocks5AuthUsername.Text := Options.ReadString('General','Socks5AuthUsername','');
  edSocks5AuthPwd.Text := Options.ReadString('General','Socks5AuthPwd','');

  edWinClassName.Text:=Options.ReadString('General','WinClassName','TfMainRep');
  edMainMutex.Text:=Options.ReadString('General','MainMutex','MainMutex');

  dmData.LSPControl.LookFor := isClientsList.Text;
  dmData.LSPControl.PathToLspModule := isLSP.Text;
  InterfaceEnabled := true;

  //��� ������� � ����������
  if iNewxor.Checked and (fileexists(isNewxor.Text)) then
  if LoadLibraryXor(isNewxor.Text) then
  begin
    isNewxor.Enabled := false;
    btnNewXor.Enabled := false;
    iNewxor.Checked := true;
  end;
  //
  if iInject.Checked and (fileexists(isInject.Text)) then
  begin
    //isInject.Enabled := false;
    //BtnInject.Enabled := false;
    iInject.Checked := true;
    ChkInterceptClick(nil);
  end
  else
  if iInject.Checked then
  begin
    ChkLSPIntercept.Checked := false;
    ChkInterceptClick(nil);
  end;
  if dmData.LSPControl.isLspModuleInstalled then //+ ���� ���� �� �������. ���� �������� ������� �� �����������
  begin
    //isLSP.Enabled := false;
    //BtnLsp.Enabled := false;
    ChkLSPIntercept.Checked := true;
    ChkLSPInterceptClick(nil);
  end;
 //
// if Options.ReadInteger('General','dumb',0) > 0 then
//   begin
//   Options.WriteInteger('General','dumb',Options.ReadInteger('General','dumb',1)+1);
////   dmData.dumbtimer.Enabled := false;
//   end
// else
//   Options.WriteInteger('General','dumb',0);
 //
 //PnlSocks5Chain.Enabled := ChkIntercept.Checked or (ChkLSPIntercept.Checked and (lspInterceptMethod.ItemIndex = 0) or ChkSocks5Mode.Checked);
 //PnlSocks5Chain.Font.Color := ifthen(PnlSocks5Chain.Enabled, clBlack, clGrayText);
 WriteSettings;
 rgProtocolVersionClick(nil);
end;

procedure TfSettings.GenerateSettingsFromInterface;
//var
//  oldProto : TProtocolVersion;
begin
  with GlobalSettings do begin
    //oldProto := GlobalProtocolVersion;
    isNoDecrypt := ChkNoDecrypt.Checked;
    isChangeParser := ChkChangeParser.Checked;
//    isAionTwoId := ChkAion.Checked;
    isGraciaOff := ChkGraciaOff.Checked;
    isKamael := ChkKamael.Checked;
    // isAION=true, ���� ������� AION 2.1-2.6 ��� AION 2.7
    isAION := ChkAion.Checked;
//    isAION := (rgProtocolVersion.ItemIndex=0) or (rgProtocolVersion.ItemIndex=1);
    isNoProcessToClient := chkIgnoseServerToClient.Checked;
    isNoProcessToServer := chkIgnoseClientToServer.Checked;
    GlobalRawAllowed := chkRaw.Checked;
    HexViewOffset := ChkHexViewOffset.Checked;
    isSavePLog := chkAutoSavePlog.Checked;
    isNoLog := chkNoLog.Checked;
    if isNoLog then
    begin
      chkAutoSavePlog.Enabled:=false;
      chkAutoSavePlog.Checked:=false;
      chkShowLogWinOnStart.Enabled:=false;
      chkShowLogWinOnStart.Checked:=false;
      chkRaw.Enabled:=false;
      chkRaw.Checked:=false;
    end else
    begin
      chkAutoSavePlog.Enabled:=true;
      chkShowLogWinOnStart.Enabled:=true;
      chkRaw.Enabled:=true;
    end;

    ShowLastPacket := ChkShowLastPacket.Checked;
    isprocesspackets := chkProcessPackets.Checked;

    //��� ������ ���������������� packets.ini
    case rgProtocolVersion.ItemIndex of
      0: GlobalProtocolVersion := AION;            //AION v 2.1
      1: GlobalProtocolVersion := AION27;          //AION v 2.5
      2: GlobalProtocolVersion := CHRONICLE4;      //�4
      3: GlobalProtocolVersion := CHRONICLE5;      //C5
      4: GlobalProtocolVersion := INTERLUDE;       //��������
      5: GlobalProtocolVersion := GRACIA;          //������
      6: GlobalProtocolVersion := GRACIAFINAL;     //������ �����
      7: GlobalProtocolVersion := GRACIAEPILOGUE;  //������ ������
      8: GlobalProtocolVersion := FREYA;           //Freya
      9: GlobalProtocolVersion := HIGHFIVE;        //High Five
      10: GlobalProtocolVersion := GOD;            //Goddess of Destruction
    end;
    reload;     //���������� ������

    fPacketFilter.LoadPacketsIni;
    if InterfaceEnabled then fPacketFilter.UpdateBtnClick(nil);

    UseSocks5Chain := ChkUseSocks5Chain.Checked;
    Socks5NeedAuth := chkSocks5NeedAuth.Checked;
    Socks5Port := strtointdef(edSocks5Port.Text,1080);
    Socks5Host := edSocks5Host.Text;
    Socks5AuthUsername := edSocks5AuthUsername.Text;
    Socks5AuthPwd := edSocks5AuthPwd.Text;
    NoFreeAfterDisconnect := chkNoFree.Checked;
  end;

  sClientsList := isClientsList.Text;
  sIgnorePorts := isIgnorePorts.Text;
  sNewxor := isNewxor.Text;
  sInject := isInject.Text;
  sLSP := isLSP.Text;
  AllowExit := ChkAllowExit.Checked;
  dmData.timerSearchProcesses.Interval := round(JvSpinEdit1.Value*1000);

  if assigned(sockEngine) then
    sockEngine.isSocks5 := ChkSocks5Mode.Checked;
end;

procedure TfSettings.WriteSettings;
begin
  //������������ ���������� ����� � ����
  Options.WriteInteger('General','MaxLinesInLog',MaxLinesInLog);
  //������������ ���������� ����� � ���� �������
  Options.WriteInteger('General','MaxLinesInPktLog',MaxLinesInPktLog);
  //����� �������������� NpcID, ��������� ��� ����������� ����������� ����� ���
  Options.WriteString('general','kNpcID', EditkNpcID.Text);

  Options.WriteString('General','Clients', isClientsList.Text);
  Options.WriteString('General','IgnorPorts', isIgnorePorts.Text);
  Options.WriteBool('General','NoDecrypt', ChkNoDecrypt.Checked);
  Options.WriteBool('General','ChangeParser', ChkChangeParser.Checked);
  Options.WriteBool('General','ChkAion', ChkAion.Checked);
  Options.WriteBool('General','IgnoseClientToServer', chkIgnoseClientToServer.Checked);
  Options.WriteBool('General','IgnoseServerToClient', chkIgnoseServerToClient.Checked);
  Options.WriteBool('General','ChkKamael', ChkKamael.Checked);
  Options.WriteBool('General','ChkGraciaOff', ChkGraciaOff.Checked);
  Options.WriteString('General', 'isNewxor', isNewxor.Text);
  Options.WriteString('General', 'isInject', isInject.Text);
  Options.WriteString('General', 'isLSP', isLSP.Text);

  Options.WriteFloat('General', 'interval', JvSpinEdit1.Value);
  Options.WriteBool('General', 'Enable', ChkIntercept.Checked);
  Options.WriteBool('General', 'EnableLSP', ChkLSPIntercept.Checked);
  Options.WriteBool('General', 'Socks5Mode', ChkSocks5Mode.Checked);
  Options.WriteFloat('General','Timer',JvSpinEdit1.Value);
  Options.WriteInteger('General','HookMethod',HookMethod.ItemIndex);
  Options.WriteBool('General', 'FastExit', ChkAllowExit.Checked);
  Options.WriteBool('General', 'iNewxor', iNewxor.Checked);
  Options.WriteBool('General', 'iInject', iInject.Checked);
  Options.WriteBool('General','AutoShowLog',ChkShowLogWinOnStart.Checked);
  Options.WriteInteger('Snifer','ProtocolVersion', rgProtocolVersion.ItemIndex);
  Options.WriteBool('General','NoFreeAfterDisconnect',chkNoFree.Checked);
  Options.WriteBool('General','RAWdatarememberallowed',chkRaw.Checked);
  Options.WriteInteger('General','LocalPort',round(JvSpinEdit2.Value));

  Options.WriteBool('General','HexViewOffset',ChkHexViewOffset.Checked);
  Options.WriteBool('General','AutoSavePLog',chkAutoSavePlog.Checked);
  Options.WriteBool('General','NoLog',chkNoLog.Checked);
  Options.WriteBool('General','ShowLastPacket',ChkShowLastPacket.Checked);
  Options.WriteBool('General','LSPDeinstallonclose',ChkLSPDeinstallonclose.Checked);
  Options.WriteInteger('General','lspInterceptMethod',lspInterceptMethod.ItemIndex);
  Options.WriteBool('General','chkProcessPackets',chkProcessPackets.Checked);

  Options.WriteBool('General','ChkUseSocks5Chain',ChkUseSocks5Chain.Checked);
  Options.WriteBool('General','ChkSocks5NeedAuth',chkSocks5NeedAuth.Checked);

  Options.WriteString('General','Socks5Host',edSocks5Host.Text);
  Options.WriteString('General','Socks5Port',edSocks5Port.Text);
  Options.WriteString('General','Socks5AuthUsername',edSocks5AuthUsername.Text);
  Options.WriteString('General','Socks5AuthPwd',edSocks5AuthPwd.Text);

  Options.WriteString('General','WinClassName',edWinClassName.Text);
  Options.WriteString('General','MainMutex',edMainMutex.Text);

  Options.UpdateFile;
end;

procedure TfSettings.ChkKamaelClick(Sender: TObject);
begin
  if  not ChkKamael.Checked then ChkGraciaOff.Checked:=False;
//  if InterfaceEnabled then GenerateSettingsFromInterface;
end;

procedure TfSettings.ChkGraciaOffClick(Sender: TObject);
begin
  if ChkGraciaOff.Checked then ChkKamael.Checked := True;
//  if InterfaceEnabled then GenerateSettingsFromInterface;
end;

procedure TfSettings.iInjectClick(Sender: TObject);
begin
  if not iInject.Checked then
  begin
    ChkIntercept.Checked := false;
    FreeMem(pInjectDll);
    pInjectDll := nil;
    AddToLog(format(rsUnLoadDllSuccessfully,[isInject.Text]));
  end
  else
    if ExtractFilePath(isInject.Text) = '' then iInject.Checked := false
    else if not LoadLibraryInject (isInject.Text) then iInject.Checked := false;

  isInject.Enabled := not iInject.Checked;
  BtnInject.Enabled := not iInject.Checked;
  HookMethod.Enabled := iInject.Checked;
  ChkIntercept.Enabled := iInject.Checked;
  JvSpinEdit1.Enabled := iInject.Checked;

//  if InterfaceEnabled then GenerateSettingsFromInterface;
end;

procedure TfSettings.ChkInterceptClick(Sender: TObject);
begin
  if not iInject.Checked then
    ChkIntercept.Checked := false; // �������� �� ��������� inject.dll
  dmData.timerSearchProcesses.Enabled := ChkIntercept.Checked; //��� ������ ���������
  //��������� LSP
  ChkLSPIntercept.Enabled := not ChkIntercept.Checked; // ���/����
  //ChkLSPIntercept.Checked := ChkIntercept.Checked; //���������� �������
  ChkLSPDeinstallonclose.Enabled := not ChkIntercept.Checked; // ���/����
  isLSP.Enabled := not ChkIntercept.Checked; // ���/����
  BtnLsp.Enabled := not ChkIntercept.Checked; // ���/����
  lspInterceptMethod.Enabled := not ChkIntercept.Checked; // ���/����
  dmData.LSPControl.setlspstate(false);
  //��������� SOCKS5
  ChkSocks5Mode.Enabled := not ChkIntercept.Checked; //���/����
  if assigned(sockEngine) then sockEngine.isSocks5 := false; //���� �����
  // ���� ������� inject, LSP ��� SOCKS5 ������ - ��������� "��������������� ���������� ����� SOCK5 ������"
  PnlSocks5Chain.Enabled := ChkIntercept.Checked;
  PnlSocks5Chain.Font.Color := ifthen(PnlSocks5Chain.Enabled, clBlack, clGrayText);
  ChkUseSocks5Chain.Enabled := ChkIntercept.Checked; // ���/����
  if not ChkIntercept.Checked then ChkUseSocks5Chain.Checked := false; //���������� �������
  chkSocks5NeedAuth.Enabled := ChkIntercept.Checked; // ���/����
  if not ChkIntercept.Checked then chkSocks5NeedAuth.Checked := false; //���������� �������

//  if InterfaceEnabled then GenerateSettingsFromInterface; //��� ���������� ���������
end;

procedure TfSettings.ChkSocks5ModeClick(Sender: TObject);
begin
  //��������� inject
  ChkIntercept.Checked := false; //���������� �������
  ChkIntercept.Enabled := false; //���� � �� ��������
  JvSpinEdit1.Enabled := false; //���� � �� ��������
  iInject.Enabled := not ChkSocks5Mode.Checked; // ���/����
  iInject.Checked := false; //���������� �������
  isInject.Enabled := not ChkSocks5Mode.Checked; // ���/����
  HookMethod.Enabled := not ChkSocks5Mode.Checked; // ���/����
  BtnInject.Enabled := not ChkSocks5Mode.Checked; // ���/���� ������ ��������� ����� ������������ dll
  dmData.timerSearchProcesses.Enabled := not ChkSocks5Mode.Checked; //���� ������ ���������
  //��������� LSP
  ChkLSPIntercept.Enabled := not ChkSocks5Mode.Checked; // ���/����
  ChkLSPIntercept.Checked := false; //���������� �������
  ChkLSPDeinstallonclose.Enabled := not ChkSocks5Mode.Checked; // ���/����
  isLSP.Enabled := not ChkSocks5Mode.Checked; // ���/����
  BtnLsp.Enabled := not ChkSocks5Mode.Checked; // ���/����
  lspInterceptMethod.Enabled := not ChkSocks5Mode.Checked; // ���/����
  dmData.LSPControl.setlspstate(false); //����
  // ���� ������� inject, LSP ��� SOCKS5 ������ - ��������� "��������������� ���������� ����� SOCK5 ������"
  PnlSocks5Chain.Enabled := ChkSocks5Mode.Checked;
  PnlSocks5Chain.Font.Color := ifthen(PnlSocks5Chain.Enabled, clBlack, clGrayText);
  ChkUseSocks5Chain.Enabled := ChkSocks5Mode.Checked; // ���/����
  if not ChkSocks5Mode.Checked then ChkUseSocks5Chain.Checked := false; //���������� �������
  chkSocks5NeedAuth.Enabled := ChkSocks5Mode.Checked; // ���/����
  if not ChkSocks5Mode.Checked then chkSocks5NeedAuth.Checked := false; //���������� �������
  //�������� SOCKS5
  if assigned(sockEngine) then sockEngine.isSocks5 := ChkSocks5Mode.Checked;
  //if Sender = nil then exit; //���� ��� ������ �� ������������, �� �����
  //if ChkIntercept.Checked then ChkInterceptClick(nil);
  //if ChkLSPIntercept.Checked then ChkLSPInterceptClick(nil);
  //if ChkSocks5Mode.Checked then ChkSocks5ModeClick(nil);

//  if InterfaceEnabled then GenerateSettingsFromInterface; //��� ���������� ���������
end;

procedure TfSettings.FormDestroy(Sender: TObject);
begin
  //���������� � ������ ����
  savepos(self);
  //������� LSP ��� ������ �� ���������
  if ChkLSPDeinstallonclose.Checked then
    dmData.LSPControl.setlspstate(false);

  //���������� ����������
  Options.UpdateFile;
  Options.Destroy;
  if hXorLib <> 0 then FreeLibrary(hXorLib);
  if not isInject.Enabled then FreeMem(pInjectDll);
end;

procedure TfSettings.ChkLSPInterceptClick(Sender: TObject);
begin
if (ExtractFilePath(isLSP.Text) = '') and ChkLSPIntercept.Checked then
  begin
    ChkLSPIntercept.Checked := false;  //�� ������ ������� ���� ���������� �� ������� � �� ������� inject
    exit;
  end;
  //��������� inject
  ChkIntercept.Enabled := false; //���� � �� ��������
  JvSpinEdit1.Enabled := false; //���� � �� ��������
  iInject.Enabled := not ChkLSPIntercept.Checked; // ���/����
  iInject.Checked := false; //���������� �������
  isInject.Enabled := not ChkLSPIntercept.Checked; // ���/����
  HookMethod.Enabled := not ChkLSPIntercept.Checked; // ���/����
  BtnInject.Enabled := not ChkLSPIntercept.Checked; // ���/���� ������ ��������� ����� ������������ dll
  dmData.timerSearchProcesses.Enabled := not ChkLSPIntercept.Checked; //���� ������ ���������
  //�������� LSP
  isLSP.Enabled := not ChkLSPIntercept.Checked; // ���/����
  BtnLsp.Enabled := not ChkLSPIntercept.Checked; // ���/����
  dmData.LSPControl.setlspstate(ChkLSPIntercept.Checked);
  // ���� ������� inject, LSP ��� SOCKS5 ������ - ��������� "��������������� ���������� ����� SOCK5 ������"
  PnlSocks5Chain.Enabled := ChkLSPIntercept.Checked;
  PnlSocks5Chain.Font.Color := ifthen(PnlSocks5Chain.Enabled, clBlack, clGrayText);
  ChkUseSocks5Chain.Enabled := ChkLSPIntercept.Checked; // ���/����
  if not ChkLSPIntercept.Checked then ChkUseSocks5Chain.Checked := false; //���������� �������
  chkSocks5NeedAuth.Enabled := ChkLSPIntercept.Checked; // ���/����
  if not ChkLSPIntercept.Checked then chkSocks5NeedAuth.Checked := false; //���������� �������
  //��������� SOCKS5
  ChkSocks5Mode.Enabled := not ChkLSPIntercept.Checked; //���/����
  if assigned(sockEngine) then sockEngine.isSocks5 := false;
  //if Sender = nil then exit; //���� ��� ������ �� ������������, �� �����
  //if ChkIntercept.Checked then ChkInterceptClick(nil);
  //if ChkLSPIntercept.Checked then ChkLSPInterceptClick(nil);
  //if ChkSocks5Mode.Checked then ChkSocks5ModeClick(nil);

//  if InterfaceEnabled then GenerateSettingsFromInterface; //��� ���������� ���������
end;

procedure TfSettings.iNewxorClick(Sender: TObject);
begin
  if not InterfaceEnabled then exit;
    if iNewxor.Checked then
    begin
      isNewxor.Enabled := false;
      btnNewXor.Enabled := false;
      if not loadLibraryXOR(isNewxor.Text) then
      begin
        isNewxor.Enabled := true;
        btnNewXor.Enabled := true;
        iNewxor.Checked := false;
      end;
    end
    else
    begin
      if not isNewxor.Enabled then
      begin
        FreeLibrary(hXorLib);
        hXorLib := 0;
        @CreateXorIn := nil;
        @CreateXorOut := nil;
        isNewxor.Enabled := true;
        btnNewXor.Enabled := true;
      end;
    end;
//  GenerateSettingsFromInterface;
end;

procedure TfSettings.Button1Click(Sender: TObject);
begin
  Hide;
  WriteSettings;
  GenerateSettingsFromInterface;
end;

procedure TfSettings.Button2Click(Sender: TObject);
begin
  Hide;
  readsettings;
  GenerateSettingsFromInterface;
end;

procedure TfSettings.isLSPChange(Sender: TObject);
begin
  dmData.LSPControl.PathToLspModule := isLSP.Text;
end;

procedure TfSettings.ChkNoDecryptClick(Sender: TObject);
begin
  if not InterfaceEnabled then exit;
//  GenerateSettingsFromInterface;
end;

procedure TfSettings.ChkAionClick(Sender: TObject);
begin
  if not InterfaceEnabled then exit;
//  GenerateSettingsFromInterface;
end;

procedure TfSettings.init;
begin
  //��������� Options.ini � ������
  Options:=TMemIniFile.Create(AppPath+'settings\Options.ini');
  if not FileExists(AppPath+'settings\Options.ini') then
  begin
    fLangSelectDialog.ShowModal;
    Show;
  end;
  readsettings;
  GenerateSettingsFromInterface;
  if ChkShowLogWinOnStart.Checked then fLog.show;
end;

procedure TfSettings.rgProtocolVersionClick(Sender: TObject);
begin
  //���� ������ ��� Gracia = 5
  ChkKamael.Checked := rgProtocolVersion.ItemIndex >= 5; // and (rgProtocolVersion.ItemIndex <= 7);
  //���� ���� 2.1 ��� ���� 2.5, �� ���������
  ChkKamael.Enabled:=((rgProtocolVersion.ItemIndex <> 0) and (rgProtocolVersion.ItemIndex <> 1)); //AION
  ChkGraciaOff.Enabled:=ChkKamael.Enabled;
  ChkChangeParser.Enabled:=true;
  //
  ChkAion.Enabled:=((rgProtocolVersion.ItemIndex = 0) or (rgProtocolVersion.ItemIndex = 1)); //AION
  ChkAion.Checked:=((rgProtocolVersion.ItemIndex = 0) or (rgProtocolVersion.ItemIndex = 1)); //AION
  //
//  if InterfaceEnabled then GenerateSettingsFromInterface;
end;

procedure TfSettings.FormCreate(Sender: TObject);
begin
  loadpos(self);
  InterfaceEnabled := false;
end;

procedure TfSettings.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle OR WS_EX_APPWINDOW;
  // ���� ���� �������� �� ��������� �� ��������
  Params.WndParent:=fMain.Handle;
end;

procedure TfSettings.BtnInjectClick(Sender: TObject);
begin
  dlgOpenDll.InitialDir:=AppPath;
  if dlgOpenDll.Execute then
    isInject.Text := dlgOpenDll.FileName;
end;

procedure TfSettings.BtnLspClick(Sender: TObject);
begin
  dlgOpenDll.InitialDir:=AppPath;
  if dlgOpenDll.Execute then
    isLSP.Text := dlgOpenDll.FileName;
end;

procedure TfSettings.btnNewXorClick(Sender: TObject);
begin
  dlgOpenDll.InitialDir:=AppPath;
  if dlgOpenDll.Execute then
    isNewxor.Text := dlgOpenDll.FileName;
end;

procedure TfSettings.isMainFormCaptionChange(Sender: TObject);
begin
  fMain.Caption := format(isMainFormCaption.Text, [uGlobalFuncs.getversion]);
  Options.WriteString('general','Caption', isMainFormCaption.Text);
end;

procedure TfSettings.FormDeactivate(Sender: TObject);
begin
  SetWindowPos(handle,HWND_TOP,0,0,0,0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TfSettings.edSocks5AuthPwdEnter(Sender: TObject);
begin
  edSocks5AuthPwd.PasswordChar := #0;
end;

procedure TfSettings.edSocks5AuthPwdExit(Sender: TObject);
begin
  edSocks5AuthPwd.PasswordChar := '*';
end;

procedure TfSettings.edSocks5PortKeyPress(Sender: TObject; var Key: Char);
begin
  if (pos(key, '1234567890') = 0) and (key<>#8) then
  key := #0;
end;

procedure TfSettings.edSocks5PortExit(Sender: TObject);
begin
  edSocks5Port.Text := inttostr(StrToIntDef(edSocks5Port.text,1080));
end;

procedure TfSettings.lspInterceptMethodClick(Sender: TObject);
begin
  PnlSocks5Chain.Enabled := ChkIntercept.Checked or (ChkLSPIntercept.Checked and (lspInterceptMethod.ItemIndex = 0) or ChkSocks5Mode.Checked);
  PnlSocks5Chain.Font.Color := ifthen(PnlSocks5Chain.Enabled, clBlack, clGrayText);
end;

procedure TfSettings.btnTestSocks5ChainClick(Sender: TObject);
var
  s : tsocket;
  res : integer;
begin
 S:=socket(AF_INET,SOCK_STREAM,0);
 if S=INVALID_SOCKET then
    BalloonHint(rsSocks5Check,'Socket error');

 res := AuthOnSocks5(s, edSocks5Host.Text, strtointdef(edSocks5Port.text,1080), inet_addr(pchar('207.46.232.182')){microsoft.com}, htons(80), chkSocks5NeedAuth.Checked, edSocks5AuthUsername.Text, edSocks5AuthPwd.Text);
 if res = 0 then 
        begin
          BalloonHint(rsSocks5Check, rsProxyServerOk);
        end
      else
        begin
        //���������
          case res of
          1: BalloonHint(rsSocks5Check, rs101);
          2: BalloonHint(rsSocks5Check, rs102);
          3: BalloonHint(rsSocks5Check, rs103);
          4: BalloonHint(rsSocks5Check, rs105);
          5: BalloonHint(rsSocks5Check, rs105);
          6: BalloonHint(rsSocks5Check, rs106);
          7: BalloonHint(rsSocks5Check, rs107);
          8: BalloonHint(rsSocks5Check, rs108);
          9: BalloonHint(rsSocks5Check, rs109);
          10: BalloonHint(rsSocks5Check, rs110);
          11: BalloonHint(rsSocks5Check, rs111);
          12: BalloonHint(rsSocks5Check, rs112);
          13: BalloonHint(rsSocks5Check, rs113);
          14: BalloonHint(rsSocks5Check, rs114);
          15: BalloonHint(rsSocks5Check, rs115);
          end;
        end;
 if s >= 0 then
 closesocket(s);
end;

end.
