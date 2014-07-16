unit uMainReplacer;

interface

uses
  uSharedStructs,
  ComCtrls,
  uGlobalFuncs,
  uResourceStrings,
  IniFiles,
  advApiHook,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, jpeg, ExtCtrls, StdCtrls, siComp;

type
  TfMainReplacer = class(TForm)
    ActionList1: TActionList;
    Action2: TAction;
    Action3: TAction;
    Action4: TAction;
    Action6: TAction;
    Action7: TAction;
    Action8: TAction;
    Action9: TAction;
    Action10: TAction;
    Action1: TAction;
    Image1: TImage;
    HideSplash: TTimer;
    Status: TLabel;
    siLang1: TsiLang;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure Action3Execute(Sender: TObject);
    procedure Action4Execute(Sender: TObject);
    procedure Action6Execute(Sender: TObject);
    procedure Action7Execute(Sender: TObject);
    procedure Action8Execute(Sender: TObject);
    procedure Action9Execute(Sender: TObject);
    procedure Action10Execute(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
    procedure Image1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure NewPacket(var msg: TMessage); Message WM_NewPacket;
    procedure ProcessPacket(var msg: TMessage); Message WM_ProcessPacket;
    procedure NewAction(var msg: TMessage); Message WM_NewAction;
    procedure ReadMsg(var msg: TMessage); Message WM_Dll_Log;
    procedure UpdAutoCompleate(var msg: TMessage); Message WM_UpdAutoCompleate;
    procedure BalonHint(var msg: TMessage); Message WM_BalloonHint;   
  protected
    { Protected declarations }
    procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  fMainReplacer: TfMainReplacer;

implementation
uses
  SyncObjs, uPlugins, uPluginData, usocketengine, winsock, uEncDec, uVisualContainer,
  uSettingsDialog, uLogForm, uConvertForm, uFilterForm, uProcesses,
  uAboutDialog, uData, uUserForm, uProcessRawLog, uScripts, Math, uMain,
  uPacketViewer;

{$R *.dfm}

{ TuMainFormReplacer }
var
  c_s : TCriticalSection;

procedure TfMainReplacer.NewAction(var msg: TMessage);
var
  Tunel : Ttunel;
  EncDec : TencDec;
  SocketEngine : TSocketEngine;
  action : byte;
  i:integer;
begin
  c_s.Enter;
  try
  action := byte(msg.wparam);

  case action of
    TencDec_Action_LOG: //������ � sLastPacket;  ������ �����
    begin
      //TencDec(Caller).sLastPacket
    end;
    TencDec_Action_MSG: //�a���� � sLastMessage; ���������� - Log
      begin
        EncDec := TencDec(msg.LParam);
        AddToLog(encdec.sLastMessage);
      end;
    TencDec_Action_GotName:
      begin
        EncDec := TencDec(msg.LParam);
        if assigned(EncDec.ParentTtunel) then
          begin
            Tunel := Ttunel(EncDec.ParentTtunel);
            if assigned(tunel) then
              begin
                AddToLog(Format(rsConnectionName, [integer(pointer(Tunel)), encdec.CharName]));
                Tunel.AssignedTabSheet.Caption := EncDec.CharName;
                Tunel.CharName := EncDec.CharName;
              end;
          end;
      end; //������ � name;
    
    TencDec_Action_ClearPacketLog:; //������ ���. ������ �����; ���������� ClearPacketsLog
    //TSocketEngine �������� ���
    TSocketEngine_Action_MSG: //������ � sLastMessage; ���������� - Log
      begin
        SocketEngine := TSocketEngine(msg.LParam);
        AddToLog(SocketEngine.sLastMessage);
      end;
    Ttunel_Action_connect_server:
    begin
      Tunel := Ttunel(msg.LParam);
      Tunel.AssignedTabSheet := TTabSheet.Create(fMain.pcClientsConnection);
      Tunel.AssignedTabSheet.PageControl := fMain.pcClientsConnection;
      fMain.pcClientsConnection.ActivePageIndex := Tunel.AssignedTabSheet.PageIndex;
      Tunel.AssignedTabSheet.Show;

      Tunel.Visual := TfVisual.Create(Tunel.AssignedTabSheet);
      Tunel.Visual.currentLSP := nil;
      Tunel.Visual.CurrentTpacketLog := nil;
      Tunel.Visual.currenttunel := Tunel;
      Tunel.AssignedTabSheet.Caption := Tunel.CharName;
      tunel.Visual.init;
      Tunel.NeedDeinit := true;

      Tunel.Visual.setNofreeBtns(tunel.EncDec.Settings.NoFreeAfterDisconnect);
      Tunel.Visual.Parent := Tunel.AssignedTabSheet;
      Tunel.active := true;

      if not fMain.pcClientsConnection.Visible then fMain.pcClientsConnection.Visible  := true;

      for i:=0 to Plugins.Count - 1 do with TPlugin(Plugins.Items[i]) do
        if Loaded and Assigned(OnConnect) then OnConnect(Tunel.initserversocket, true);
    end; //
    Ttunel_Action_disconnect_server:
    begin
      Tunel := Ttunel(msg.LParam);
      if not Tunel.noFreeOnServerDisconnect then
        Tunel.active := false;
      for i:=0 to Plugins.Count - 1 do with TPlugin(Plugins.Items[i]) do
        if Loaded and Assigned(OnDisconnect) then OnDisconnect(Tunel.initserversocket, true);
    end; //
    Ttunel_Action_connect_client:
      begin ////��������� ����� ���� � ���� ������.. � ��� ��� �����...
        Tunel := Ttunel(msg.LParam);
        for i:=0 to Plugins.Count - 1 do with TPlugin(Plugins.Items[i]) do
          if Loaded and Assigned(OnConnect) then OnConnect(Tunel.initserversocket, false);
      end; //
    Ttunel_Action_disconnect_client:
      begin
        Tunel := Ttunel(msg.LParam);
        if not Tunel.noFreeOnClientDisconnect then
          Tunel.active := false;
        for i:=0 to Plugins.Count - 1 do with TPlugin(Plugins.Items[i]) do
          if Loaded and Assigned(OnDisconnect) then OnDisconnect(Tunel.initserversocket, false);
      end;

    Ttulel_action_tunel_created:
      begin

      end;
    Ttulel_action_tunel_destroyed:
      begin
        
        Tunel := Ttunel(msg.LParam);
        if Tunel.NeedDeinit then
          tunel.Visual.deinit;
        if assigned(Tunel) then
          if assigned(Tunel.Visual) then
            begin
            Tunel.Visual.Destroy;
            Tunel.Visual := nil;
            end;

        if Assigned(Tunel.AssignedTabSheet) then
          begin
          Tunel.AssignedTabSheet.Destroy;
          Tunel.AssignedTabSheet := nil;
          end;
      end;
    end;
  finally
    c_s.Leave;
  end;
end;

procedure TfMainReplacer.NewPacket(var msg: TMessage);
var
  temp : SendMessageParam;
begin
  try
  temp := SendMessageParam(pointer(msg.WParam)^);
  fScript.ScryptProcessPacket(temp.packet, temp.FromServer, temp.Id);
  
  if temp.Packet.Size > 2 then //������� ���� ������� ����� ��������
  if assigned(Ttunel(temp.tunel)) then
    if not Ttunel(temp.tunel).MustBeDestroyed then
      if assigned(Ttunel(temp.tunel).Visual) then
      if Ttunel(temp.tunel).Visual.btnProcessPackets.Down then
        begin
          Ttunel(temp.tunel).Visual.AddPacketToAcum(temp.Packet, temp.FromServer, Ttunel(temp.tunel).EncDec);
          if assigned(Ttunel(temp.tunel).Visual) then
            SendMessage(Handle,WM_ProcessPacket,integer(@Ttunel(temp.tunel).Visual), 0);
        end;
  finally
  end;
end;

procedure TfMainReplacer.ProcessPacket(var msg: TMessage);
var
visual:tfvisual;
begin
  try
    visual := TfVisual(pointer(msg.WParam)^);
    visual.processpacketfromacum;
  except
  end;
end;

procedure TfMainReplacer.ReadMsg(var msg: TMessage);
var
  NewReddirectIP: Integer;
  IPb:array[0..3] of Byte absolute NewReddirectIP;
begin
  c_s.Enter;
  msg.ResultHi := htons(sockEngine.ServerPort);
  NewReddirectIP := msg.WParam;
  sockEngine.RedirrectIP := NewReddirectIP;
  sockEngine.RedirrectPort := msg.LParamLo;
  //+++  ������ �������������� ������ - ������������
  if Pos(IntToStr(ntohs(msg.LParamLo))+';',sIgnorePorts+';')<>0 then begin
    if fSettings.ChkIntercept.Checked then
    begin
      msg.ResultLo:=1;
      AddToLog (Format(rsInjectConnectIntercepted, [IPb[0],IPb[1],IPb[2],IPb[3],ntohs(msg.LParamLo)]));
      sockEngine.donotdecryptnextconnection := false;
    end else
    begin
      msg.ResultLo:=0;
      AddToLog (Format(rsInjectConnectInterceptOff, [IPb[0],IPb[1],IPb[2],IPb[3],ntohs(msg.LParamLo)]));
      sockEngine.donotdecryptnextconnection := false;
    end;
  end else
  if GlobalSettings.UseSocks5Chain then
    begin
      msg.ResultLo:=1;
      AddToLog (Format(rsInjectConnectInterceptedIgnoredPort, [IPb[0],IPb[1],IPb[2],IPb[3],ntohs(msg.LParamLo)]));
      sockEngine.donotdecryptnextconnection := true;
    end
  else
  begin
    msg.ResultLo:=0;
    AddToLog (Format(rsInjectConnectInterceptedIgnoder, [IPb[0],IPb[1],IPb[2],IPb[3],ntohs(msg.LParamLo)]));
    sockEngine.donotdecryptnextconnection := false;
  end;
  c_s.Leave;
end;
procedure TfMainReplacer.FormDestroy(Sender: TObject);
begin
  c_s.Destroy;
end;

procedure TfMainReplacer.FormCreate(Sender: TObject);
begin
  AppPath := ExtractFilePath(Application.ExeName);
  c_s := TCriticalSection.Create;
end;

procedure TfMainReplacer.Action1Execute(Sender: TObject);
begin
  if GetForegroundWindow = fPacketViewer.Handle then
    fPacketViewer.Hide
  else
    fPacketViewer.Show;
end;

procedure TfMainReplacer.Action2Execute(Sender: TObject);
begin
  if GetForegroundWindow = fProcessRawLog.Handle then
    fProcessRawLog.Hide
  else
    fProcessRawLog.Show;
end;

procedure TfMainReplacer.Action3Execute(Sender: TObject);
begin
  if GetForegroundWindow = fSettings.Handle then
    fSettings.Hide
  else
    fSettings.Show;
end;

procedure TfMainReplacer.Action4Execute(Sender: TObject);
begin
  if GetForegroundWindow = fScript.Handle then
    fScript.Hide
  else
    fScript.Show;
end;

procedure TfMainReplacer.Action6Execute(Sender: TObject);
begin
  if GetForegroundWindow = fPacketFilter.Handle then
    fPacketFilter.Hide
  else
    fPacketFilter.Show;
end;

procedure TfMainReplacer.Action7Execute(Sender: TObject);
begin
  if GetForegroundWindow = fPlugins.Handle then
    fPlugins.Hide
  else
    fPlugins.Show;
end;

procedure TfMainReplacer.Action8Execute(Sender: TObject);
begin
if (GetForegroundWindow = UserForm.Handle) or not fMain.nUserFormShow.Enabled then
  UserForm.Hide
else
  UserForm.show;
end;

procedure TfMainReplacer.Action9Execute(Sender: TObject);
begin
  if fMain.Visible then fMain.BringToFront; 
end;

procedure TfMainReplacer.Action10Execute(Sender: TObject);
begin
if GetForegroundWindow = fLog.Handle then
  fLog.Hide
else
  fLog.Show;
end;

procedure TfMainReplacer.UpdAutoCompleate(var msg: TMessage);
var
  i:integer;
begin
  //�������� ��������� ��� �������
  dmData.DO_reloadFuncs;
  i := 0;
  while i < ScriptList.Count do
  begin
    dmData.UpdateAutoCompleate(TScript(ScriptList.Items[i]).Editor.AutoComplete);
    inc(i);
  end;
end;

procedure TfMainReplacer.Image1Click(Sender: TObject);
begin
  HideSplash.Enabled := false;
  FormStyle := fsNormal;
  visible := false;
  ShowWindow(application.Handle,sw_hide);
  fMain.show;
end;

procedure TfMainReplacer.BalonHint(var msg: TMessage);
var
  smsg, stitle : String;
begin
  smsg := string(msg.WParam);
  stitle := string(msg.LParam);
  fMain.JvTrayIcon1.BalloonHint(stitle,smsg);
end;

procedure TfMainReplacer.CreateParams(var Params: TCreateParams);
var
  wcnL2PH :string;
begin
//  inherited CreateParams(Params);
  inherited;
  Options:=TMemIniFile.Create(AppPath+'settings\Options.ini');
  wcnL2PH := Options.ReadString('general','WinClassName', 'TfMainRep');
  wcnL2PH:=wcnL2PH+#0;   //������� ���������� ������
  Options.Destroy;
//  �������� ����� str �� ��������� ����� WinClassName
  if (Length(wcnL2PH)<=64) AND (Length(wcnL2PH)<>0) then
  begin
    move(wcnL2PH[1], Params.WinClassName, Length(wcnL2PH));
    //MessageBox(0, 'TfMainReplacer', PChar(String(wcnL2PH)), MB_OK);
  end else
  begin
    Params.WinClassName := 'TfMainRep';
    //MessageBox(0, 'TfMainReplacer', 'TfMainReplacer', MB_OK);
  end;
end;

end.
