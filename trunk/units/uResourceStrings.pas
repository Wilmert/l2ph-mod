unit uResourceStrings;

interface

var

	rsTunelCreated: string = ''; (* ������ ($%d) ������ *)
	rsTunelRUN: string = ''; (* ������ ($%d) ������� ��� ������ � ������ � %d *)
	rsTunelDestroy: string = ''; (* ������ ($%d) ��������� *)
	rsTunelConnecting: string = ''; (* ������ ($%d), ��������� ����� � %d / ���������� ����� � %d, ���������� � %s:%d ..... *)
	rsTunelConnected: string = ''; (* ������ ($%d), ��������� ����� � %d / ���������� ����� � %d, ���������� ����������� � %s:%d *)
  rsTunelConnectedProxyUse: string = '';
  rsTunel: string = '';

	rsTunelTimeout: string = ''; (* ������ ($%d), ������ ���������� �� �������� *)


	rsInjectConnectIntercepted: string = ''; (* (Inject.dll) ���������� ������� �� %d.%d.%d.%d:%d *)
	rsInjectConnectInterceptedIgnoredPort: string = ''; (* (Inject.dll) ���������� ������� �� %d.%d.%d.%d:%d *)
	rsInjectConnectInterceptOff: string = ''; (* (Inject.dll) ������� �� %d.%d.%d.%d:%d ������� (�������� ��������) *)
	rsInjectConnectInterceptedIgnoder: string = ''; (* (Inject.dll) ������� �� %d.%d.%d.%d:%d �������������� *)

	rsTunelServerDisconnect: string = ''; (* ������ ($%d) ���������� �� ������� *)
	rsTunelClientDisconnect: string = ''; (* ������ ($%d) ���������� �� ������� *)


	rsSocketEngineNewConnection: string = ''; (* ServerListen: ���������� ����� ����������. *)
	rsTsocketEngineError: string = ''; (* ������: %s *)
	rsTsocketEngineSocketError: string = ''; (* �� ������: %d ������: %d: %s  *)

	rsSavingPacketLog: string = ''; (* ��������� ��� �������... *)
	rsConnectionName: string = ''; (* ��� ���������� ��� ������ ($%d): %s *)

  rsProxyServerOk : string = '';
  rsSocks5Check : string = '';

	rs100: string = ''; (* ���������� � %s:%d ����������� ����� ������� ������ ������*)
	rs101: string = ''; (* ��� ����� ������ ������� �� ���� ����������*)
	rs102: string = ''; (* ������ ������ ����������*)
	rs103: string = ''; (* ����� ����������� ��� �������� ������ ��������*)
	rs104: string = ''; (* �� ������ ������� ��������� �����������*)
	rs105: string = ''; (* �������� ��� ������������ � ������ �� ������������� �� ������ �������*)
	rs106: string = ''; (* ����������� �� ������ ������� ���� ���������*)
	rs107: string = ''; (* ����������� ������ ��� ����������� �� ������ �������*)
	rs108: string = ''; (* ������ ������: ������ SOCKS-�������*)
	rs109: string = ''; (* ������ ������: ���������� ��������� ������� ������*)
	rs110: string = ''; (* ������ ������: ���� ����������*)
	rs111: string = ''; (* ������ ������: ���� ����������*)
	rs112: string = ''; (* ������ ������: ����� � ����������*)
	rs113: string = ''; (* ������ ������: ��������� TTL*)
	rs114: string = ''; (* ������ ������: ������� (connect) �� ��������������*)
	rs115: string = ''; (* ������ ������: ��� ������ (IPv4) �� ��������������*)

  rsLSPSOCKSMODE : string = '';

	rsClientPatched0: string = ''; (* ������ ��������� ����� ������ %S (%s) *)
	rsClientPatched1: string = ''; (* ������� ��������� ����� ������ %S (%s) *)
	rsClientPatched2: string = ''; (* ������������� ��������� ����� ������ %S (%s) *)
  
	rsUnLoadDllSuccessfully: string = ''; (* ���������� %s ������� ��������� *)
	rsLoadDllUnSuccessful: string = ''; (* ���������� %s ����������� ��� ������������� ������ ����������� *)
	rsLoadDllSuccessfully: string = ''; (* ������� ��������� %s *)
	rsStartLocalServer: string = ''; (* �� %d ��������������� ��������� ������ *)
	rsFailedLocalServer: string = ''; (* �� ������� ���������������� ��������� ������ �� ���� %d
�������� ���� ���� ����� ������ ����������� *)

	rsLSPConnectionDetected: string = ''; (* (LSP) ���������� ���������� (����� %d) IP/port %s:%d. %s *)
	rsLSPConnectionWillbeIntercepted: string = ''; (* ���������� ����� ����������� *)
  rsLSPConnectionWillbeInterceptedAndRettirected: string = ''; (* ���������� ����� ����������� *)
	rsLSPConnectionWillbeIgnored: string = ''; (* ���������� ����� ��������������� *)
	rsLSPDisconnectDetected: string = ''; (* (LSP) ���������� ������� (����� %d) *)

	RsAppError: string = ''; (* %s - ������ ���������� *)
	RsExceptionClass: string = ''; (* �����: %s *)
	RsExceptionMessage: string = ''; (* ���������: %s *)
	RsExceptionAddr: string = ''; (* �����: %p *)
	RsStackList: string = ''; (* Stack list, generated %s *)
	RsModulesList: string = ''; (* List of loaded modules: *)
	RsOSVersion: string = ''; (* System   : %s %s, Version: %d.%d, Build: %x, "%s" *)
	RsProcessor: string = ''; (* Processor: %s, %s, %d MHz *)
	RsMemory: string = ''; (* Memory: %d; free %d *)
	RsScreenRes: string = ''; (* Display  : %dx%d pixels, %d bpp *)
	RsActiveControl: string = ''; (* Active Controls hierarchy: *)
	RsThread: string = ''; (* Thread: %s *)
	RsMissingVersionInfo: string = ''; (* (no version info) *)
	RsMainThreadCallStack: string = ''; (* Call stack for main thread *)
	RsThreadCallStack: string = ''; (* Call stack for thread %s *)
  rsLSP_Install_success: string = '';
  rsLSP_Already_installed: string = '';
  rsLSP_Uninstall_success: string = '';
  rsLSP_Not_installed: string = '';
  rsLSP_Install_error: string = '';
  rsLSP_UnInstall_error: string = '';
  rsLSP_Install_error_badspipath: string = '';

implementation

end.


